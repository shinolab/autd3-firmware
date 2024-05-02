`timescale 1ns / 1ps
module sim_mem_stm_gain ();

  localparam int DEPTH = 249;
  localparam int SIZE = 1024;

  logic CLK;
  logic locked;

  sim_helper_random sim_helper_random ();
  sim_helper_bram #(.DEPTH(DEPTH)) sim_helper_bram ();

  clock_bus_if clock_bus ();
  cnt_bus_if cnt_bus ();
  modulation_bus_if mod_bus ();
  stm_bus_if stm_bus ();
  duty_table_bus_if duty_table_bus ();
  filter_bus_if filter_bus ();

  memory memory (
      .CLK(CLK),
      .MRCC_25P6M(MRCC_25P6M),
      .MEM_BUS(sim_helper_bram.memory_bus.bram_port),
      .CLOCK_BUS(clock_bus.in_port),
      .CNT_BUS(cnt_bus.in_port),
      .MOD_BUS(mod_bus.in_port),
      .STM_BUS(stm_bus.in_port),
      .DUTY_TABLE_BUS(duty_table_bus.in_port),
      .FILTER_BUS(filter_bus.in_port)
  );

  sim_helper_clk sim_helper_clk (
      .MRCC_25P6M(),
      .CLK(CLK),
      .CLOCK_BUS(clock_bus.out_port),
      .LOCKED(locked),
      .SYS_TIME()
  );

  logic [9:0] idx;
  logic [7:0] addr;
  logic [63:0] value;
  logic segment;

  assign stm_bus.stm_port.MODE = params::STM_MODE_GAIN;
  assign stm_bus.stm_port.SEGMENT = segment;
  assign stm_bus.out_gain_port.GAIN_IDX = idx;
  assign stm_bus.out_gain_port.GAIN_ADDR = addr;
  assign value = stm_bus.out_gain_port.VALUE;

  logic [7:0] phase_buf_0[SIZE][DEPTH];
  logic [7:0] intensity_buf_0[SIZE][DEPTH];
  logic [7:0] phase_buf_1[SIZE][DEPTH];
  logic [7:0] intensity_buf_1[SIZE][DEPTH];

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
      expect_phase = segment === 1'b0 ? phase_buf_0[index][cur_idx] : phase_buf_1[index][cur_idx];
      expect_intensity = segment === 1'b0 ? intensity_buf_0[index][cur_idx] : intensity_buf_1[index][cur_idx];
      offset = (16 * cur_idx) % 64;
      tmp = value >> offset;
      if (expect_phase !== tmp[7:0]) begin
        $error("Phase: %d != %d @ %d", expect_phase, tmp[7:0], cur_idx);
        $finish();
      end
      if (expect_intensity !== tmp[15:8]) begin
        $error("Intensity: %d != %d @ %d", expect_intensity, tmp[15:8], cur_idx);
        $finish();
      end
    end
  endtask

  initial begin
    sim_helper_random.init();

    idx = 0;
    addr = 0;
    segment = 0;

    @(posedge locked);

    for (int j = 0; j < SIZE; j++) begin
      for (int i = 0; i < DEPTH; i++) begin
        phase_buf_0[j][i] = sim_helper_random.range(8'hFF, 0);
        intensity_buf_0[j][i] = sim_helper_random.range(8'hFF, 0);
        phase_buf_1[j][i] = sim_helper_random.range(8'hFF, 0);
        intensity_buf_1[j][i] = sim_helper_random.range(8'hFF, 0);
      end
    end
    sim_helper_bram.write_stm_gain_intensity_phase(0, intensity_buf_0, phase_buf_0, SIZE);
    sim_helper_bram.write_stm_gain_intensity_phase(1, intensity_buf_1, phase_buf_1, SIZE);
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
