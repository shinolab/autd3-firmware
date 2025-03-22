`timescale 1ns / 1ps
module sim_mem_stm_foci ();

  `include "define.vh"

  localparam int DEPTH = 249;
  localparam int SIZE = 65536;

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

  logic [15:0] idx;
  logic [63:0] value;
  logic segment;

  assign stm_bus.stm_port.MODE = params::STM_MODE_FOCUS;
  assign stm_bus.stm_port.SEGMENT = segment;
  assign stm_bus.out_focus_port.FOCUS_IDX = idx;
  assign value = stm_bus.out_focus_port.VALUE;

  logic [17:0] x, y, z;
  logic [7:0] intensity_or_offsets;
  assign x = value[17:0];
  assign y = value[35:18];
  assign z = value[53:36];
  assign intensity_or_offsets = value[61:54];

  logic signed [17:0] x_buf[params::NumSegment][SIZE];
  logic signed [17:0] y_buf[params::NumSegment][SIZE];
  logic signed [17:0] z_buf[params::NumSegment][SIZE];
  logic [7:0] intensity_or_offsets_buf[params::NumSegment][SIZE];

  task automatic progress();
    for (int i = 0; i < SIZE + 3; i++) begin
      @(posedge CLK);
      idx <= i % SIZE;
    end
  endtask

  task automatic check(input logic segment);
    logic [15:0] cur_idx;
    logic [17:0] expect_x, expect_y, expect_z;
    logic [7:0] expect_intensity_or_offset;
    repeat (3) @(posedge CLK);
    for (int i = 0; i < SIZE; i++) begin
      @(posedge CLK);
      cur_idx = (idx + SIZE - 2) % SIZE;
      expect_x = x_buf[segment][cur_idx];
      expect_y = y_buf[segment][cur_idx];
      expect_z = z_buf[segment][cur_idx];
      expect_intensity_or_offset = intensity_or_offsets_buf[segment][cur_idx];
      `ASSERT_EQ(expect_x, x);
      `ASSERT_EQ(expect_y, y);
      `ASSERT_EQ(expect_z, z);
      `ASSERT_EQ(expect_intensity_or_offset, intensity_or_offsets);
      if (i % 512 == 511) $display("segment %d: %d/%d...done", segment, i + 1, SIZE);
    end
  endtask

  initial begin
    sim_helper_random.init();

    idx = 0;
    segment = 0;

    @(posedge locked);

    for (int s = 0; s < params::NumSegment; s++) begin
      for (int i = 0; i < SIZE; i++) begin
        x_buf[s][i] = sim_helper_random.range(17'h1FFFF, 0);
        y_buf[s][i] = sim_helper_random.range(17'h1FFFF, 0);
        z_buf[s][i] = sim_helper_random.range(17'h1FFFF, 0);
        intensity_or_offsets_buf[s][i] = sim_helper_random.range(8'hFF, 0);
      end
      sim_helper_bram.write_stm_focus(s, x_buf[s], y_buf[s], z_buf[s], intensity_or_offsets_buf[s],
                                      SIZE);
    end
    $display("memory initialized");

    segment = 0;
    fork
      progress();
      check(segment);
    join

    segment = 1;
    fork
      progress();
      check(segment);
    join

    $display("OK! sim_mem_stm_foci");
    $finish();
  end

endmodule
