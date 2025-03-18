`timescale 1ns / 1ps
module sim_stm_gain ();

  `include "define.vh"

  logic CLK;
  logic locked;
  logic [56:0] SYS_TIME;

  localparam int DEPTH = 249;
  localparam int SIZE = 16;

  sim_helper_bram sim_helper_bram ();
  sim_helper_random sim_helper_random ();

  settings::stm_settings_t stm_settings;

  logic [7:0] intensity;
  logic [7:0] phase;
  logic [12:0] debug_idx;
  logic debug_segment;
  logic dout_valid;

  logic [13:0] cycle_buf[params::NumSegment];
  logic [15:0] freq_div_buf[params::NumSegment];
  logic [7:0] intensity_buf[params::NumSegment][SIZE][DEPTH];
  logic [7:0] phase_buf[params::NumSegment][SIZE][DEPTH];

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
      .SYS_TIME(SYS_TIME)
  );

  time_cnt_generator #(
      .DEPTH(DEPTH)
  ) time_cnt_generator (
      .CLK(CLK),
      .SYS_TIME(SYS_TIME),
      .SKIP_ONE_ASSERT(1'b0),
      .TIME_CNT(),
      .UPDATE(UPDATE)
  );

  stm #(
      .DEPTH(DEPTH)
  ) stm (
      .CLK(CLK),
      .SYS_TIME(SYS_TIME),
      .UPDATE(UPDATE),
      .STM_SETTINGS(stm_settings),
      .STM_BUS(stm_bus.stm_port),
      .STM_BUS_FOCUS(stm_bus.out_focus_port),
      .STM_BUS_GAIN(stm_bus.out_gain_port),
      .INTENSITY(intensity),
      .PHASE(phase),
      .DOUT_VALID(dout_valid),
      .DEBUG_IDX(debug_idx),
      .DEBUG_SEGMENT(debug_segment)
  );

  task automatic update(input logic req_segment, input logic [15:0] rep);
    @(posedge CLK);
    stm_settings.UPDATE <= 1'b1;
    stm_settings.REQ_RD_SEGMENT <= req_segment;
    stm_settings.REP[req_segment] <= rep;
    stm_settings.CYCLE[req_segment] <= cycle_buf[req_segment] - 1;
    stm_settings.FREQ_DIV[req_segment] <= freq_div_buf[req_segment];
    @(posedge CLK);
    stm_settings.UPDATE <= 1'b0;
  endtask

  task automatic wait_segment(input logic segment);
    while (1) begin
      @(posedge CLK);
      if (debug_segment === segment) begin
        break;
      end
    end
  endtask

  task automatic check(input logic segment);
    while (1) begin
      @(posedge CLK);
      if (~dout_valid) begin
        break;
      end
    end

    for (int j = 0; j < cycle_buf[segment] * freq_div_buf[segment]; j++) begin
      while (1) begin
        @(posedge CLK);
        if (dout_valid) begin
          break;
        end
      end
      $display("check %d/%d", j + 1, cycle_buf[segment]);
      for (int i = 0; i < DEPTH; i++) begin
        `ASSERT_EQ(intensity_buf[segment][debug_idx][i], intensity);
        `ASSERT_EQ(phase_buf[segment][debug_idx][i], phase);
        @(posedge CLK);
      end
    end
  endtask

  initial begin
    sim_helper_random.init();

    cycle_buf[0] = SIZE;
    cycle_buf[1] = SIZE / 4;
    freq_div_buf[0] = 1;
    freq_div_buf[1] = 3;

    stm_settings.UPDATE = 0;
    stm_settings.TRANSITION_MODE = params::TRANSITION_MODE_SYNC_IDX;
    stm_settings.TRANSITION_VALUE = 0;
    stm_settings.MODE[0] = params::STM_MODE_GAIN;
    stm_settings.MODE[1] = params::STM_MODE_GAIN;
    stm_settings.CYCLE[0] = '0;
    stm_settings.FREQ_DIV[0] = '1;
    stm_settings.CYCLE[1] = '0;
    stm_settings.FREQ_DIV[1] = '1;

    @(posedge locked);

    for (int segment = 0; segment < params::NumSegment; segment++) begin
      for (int i = 0; i < SIZE; i++) begin
        for (int j = 0; j < DEPTH; j++) begin
          intensity_buf[segment][i][j] = sim_helper_random.range(8'hFF, 0);
          phase_buf[segment][i][j] = sim_helper_random.range(8'hFF, 0);
        end
      end
      sim_helper_bram.write_stm_gain_intensity_phase(segment, intensity_buf[segment],
                                                     phase_buf[segment], cycle_buf[segment]);
    end

    $display("memory initialized");

    fork
      update(0, 32'hFFFFFFFF);
      wait_segment(0);
    join
    check(0);

    fork
      update(1, 32'd0);
      wait_segment(1);
    join
    check(1);

    $display("OK! sim_stm_gain");
    $finish();
  end

endmodule
