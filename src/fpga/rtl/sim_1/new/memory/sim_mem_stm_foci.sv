`timescale 1ns / 1ps
module sim_mem_stm_foci ();

  `include "define.vh"

  localparam int DEPTH = 249;
  localparam int SIZE = 8192;

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
  logic [511:0] value;
  logic segment;

  assign stm_bus.stm_port.MODE = params::STM_MODE_FOCUS;
  assign stm_bus.stm_port.SEGMENT = segment;
  assign stm_bus.out_focus_port.FOCUS_IDX = idx;
  assign value = stm_bus.out_focus_port.VALUE;

  logic [17:0] x[params::NumFociMax];
  logic [17:0] y[params::NumFociMax];
  logic [17:0] z[params::NumFociMax];
  logic [7:0] intensity_or_offsets[params::NumFociMax];
  for (genvar i = 0; i < params::NumFociMax; i++) begin
    assign x[i] = value[64*i+17:64*i];
    assign y[i] = value[64*i+35:64*i+18];
    assign z[i] = value[64*i+53:64*i+36];
    assign intensity_or_offsets[i] = value[64*i+61:64*i+54];
  end

  logic signed [17:0] x_buf[params::NumSegment][SIZE][params::NumFociMax];
  logic signed [17:0] y_buf[params::NumSegment][SIZE][params::NumFociMax];
  logic signed [17:0] z_buf[params::NumSegment][SIZE][params::NumFociMax];
  logic [7:0] intensity_or_offsets_buf[params::NumSegment][SIZE][params::NumFociMax];

  task automatic progress();
    for (int i = 0; i < SIZE + 3; i++) begin
      @(posedge CLK);
      idx <= i % SIZE;
    end
  endtask

  task automatic check(input logic segment);
    logic [15:0] cur_idx;
    logic [17:0] expect_x[params::NumFociMax];
    logic [17:0] expect_y[params::NumFociMax];
    logic [17:0] expect_z[params::NumFociMax];
    logic [7:0] expect_intensity_or_offset[params::NumFociMax];
    repeat (3) @(posedge CLK);
    for (int i = 0; i < SIZE; i++) begin
      @(posedge CLK);
      cur_idx = (idx + SIZE - 2) % SIZE;
      for (int k = 0; k < params::NumFociMax; k++) begin
        expect_x[k] = x_buf[segment][cur_idx][k];
        expect_y[k] = y_buf[segment][cur_idx][k];
        expect_z[k] = z_buf[segment][cur_idx][k];
        expect_intensity_or_offset[k] = intensity_or_offsets_buf[segment][cur_idx][k];
        `ASSERT_EQ(expect_x[k], x[k]);
        `ASSERT_EQ(expect_y[k], y[k]);
        `ASSERT_EQ(expect_z[k], z[k]);
        `ASSERT_EQ(expect_intensity_or_offset[k], intensity_or_offsets[k]);
      end
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
        for (int k = 0; k < params::NumFociMax; k++) begin
          x_buf[s][i][k] = sim_helper_random.range(17'h1FFFF, 0);
          y_buf[s][i][k] = sim_helper_random.range(17'h1FFFF, 0);
          z_buf[s][i][k] = sim_helper_random.range(17'h1FFFF, 0);
          intensity_or_offsets_buf[s][i][k] = sim_helper_random.range(8'hFF, 0);
        end
      end
      sim_helper_bram.write_stm_focus(s, x_buf[s], y_buf[s], z_buf[s], intensity_or_offsets_buf[s],
                                      SIZE, params::NumFociMax);
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
