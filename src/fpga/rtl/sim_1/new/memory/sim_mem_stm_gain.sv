`timescale 1ns / 1ps
module sim_mem_stm_gain ();

  `include "define.vh"

  localparam int DEPTH = 249;
  localparam int SIZE = 1024;

  logic CLK;
  logic locked;

  sim_helper_random sim_helper_random ();
  sim_helper_bram #(.DEPTH(DEPTH)) sim_helper_bram ();

  cnt_bus_if cnt_bus ();
  phase_corr_bus_if phase_corr_bus ();
  modulation_bus_if mod_bus ();
  stm_bus_if stm_bus ();
  pwe_table_bus_if pwe_table_bus ();

  memory memory (
      .CLK(CLK),
      .MRCC_25P6M(MRCC_25P6M),
      .MEM_BUS(sim_helper_bram.memory_bus.bram_port),
      .CNT_BUS(cnt_bus.in_port),
      .PHASE_CORR_BUS(phase_corr_bus.in_port),
      .MOD_BUS(mod_bus.in_port),
      .STM_BUS(stm_bus.in_port),
      .PWE_TABLE_BUS(pwe_table_bus.in_port)
  );

  sim_helper_clk sim_helper_clk (
      .MRCC_25P6M(MRCC_25P6M),
      .CLK(CLK),
      .LOCKED(locked),
      .SYS_TIME()
  );

  logic [9:0] idx;
  logic [7:0] addr;
  logic [511:0] value;
  logic segment;

  assign stm_bus.stm_port.MODE = params::STM_MODE_GAIN;
  assign stm_bus.stm_port.SEGMENT = segment;
  assign stm_bus.out_gain_port.GAIN_IDX = idx;
  assign stm_bus.out_gain_port.GAIN_ADDR = addr;
  assign value = stm_bus.out_gain_port.VALUE;

  logic [7:0] phase_buf[params::NumSegment][SIZE][DEPTH];
  logic [7:0] intensity_buf[params::NumSegment][SIZE][DEPTH];

  task automatic progress(input logic [9:0] index);
    idx = index;
    for (int i = 0; i < DEPTH + 3; i++) begin
      @(posedge CLK);
      addr <= i % DEPTH;
    end
  endtask

  task automatic check(input logic segment, input logic [9:0] index);
    logic [7:0] cur_idx;
    logic [7:0] expect_phase;
    logic [7:0] expect_intensity;
    int offset;
    int tmp;
    repeat (3) @(posedge CLK);
    for (int i = 0; i < DEPTH; i++) begin
      @(posedge CLK);
      cur_idx = (addr + DEPTH - 2) % DEPTH;
      expect_phase = phase_buf[segment][index][cur_idx];
      expect_intensity = intensity_buf[segment][index][cur_idx];
      offset = (16 * cur_idx) % 512;
      tmp = value >> offset;
      `ASSERT_EQ(expect_phase, tmp[7:0]);
      `ASSERT_EQ(expect_intensity, tmp[15:8]);
    end
  endtask

  initial begin
    sim_helper_random.init();

    idx = 0;
    addr = 0;
    segment = 0;

    @(posedge locked);

    for (int s = 0; s < params::NumSegment; s++) begin
      for (int j = 0; j < SIZE; j++) begin
        for (int i = 0; i < DEPTH; i++) begin
          phase_buf[s][j][i] = sim_helper_random.range(8'hFF, 0);
          intensity_buf[s][j][i] = sim_helper_random.range(8'hFF, 0);
        end
      end
      sim_helper_bram.write_stm_gain_intensity_phase(s, intensity_buf[s], phase_buf[s], SIZE);
    end
    $display("memory initialized");

    segment = 0;
    for (int j = 0; j < SIZE; j++) begin
      fork
        progress(j);
        check(segment, j);
      join
      if (j % 32 == 31) $display("segment %d: %d/%d...done", segment, j + 1, SIZE);
    end

    segment = 1;
    for (int j = 0; j < SIZE; j++) begin
      fork
        progress(j);
        check(segment, j);
      join
      if (j % 32 == 31) $display("segment %d: %d/%d...done", segment, j + 1, SIZE);
    end

    $display("OK! sim_mem_stm_gain");
    $finish();
  end

endmodule
