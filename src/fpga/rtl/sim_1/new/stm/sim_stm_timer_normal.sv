`timescale 1ns / 1ps
module sim_stm_timer_normal ();

  `include "define.vh"

  localparam int DivLatency = 58;
  localparam int DEPTH = 249;

  logic CLK;
  logic locked;
  logic [56:0] sys_time;
  sim_helper_clk sim_helper_clk (
      .MRCC_25P6M(),
      .CLK(CLK),
      .LOCKED(locked),
      .SYS_TIME(sys_time)
  );

  sim_helper_random sim_helper_random ();
  sim_helper_bram #(.DEPTH(DEPTH)) sim_helper_bram ();

  settings::stm_settings_t stm_settings;
  logic update_settings;
  logic [15:0] idx[params::NumSegment];

  stm_timer stm_timer (
      .CLK(CLK),
      .UPDATE_SETTINGS_IN(update_settings),
      .SYS_TIME(sys_time),
      .CYCLE(stm_settings.CYCLE),
      .FREQ_DIV(stm_settings.FREQ_DIV),
      .IDX(idx),
      .UPDATE_SETTINGS_OUT()
  );

  initial begin
    sim_helper_random.init();

    stm_settings.REQ_RD_SEGMENT = 1'b0;
    stm_settings.CYCLE[0] = 0;
    stm_settings.FREQ_DIV[0] = 1;
    stm_settings.CYCLE[1] = 0;
    stm_settings.FREQ_DIV[1] = 3;
    stm_settings.REP[0] = 16'hFFFF;
    stm_settings.REP[1] = 16'hFFFF;
    update_settings = 1'b0;

    @(posedge locked);

    while (sys_time < 2 * DivLatency) begin
      @(posedge CLK);
    end

    @(posedge CLK);
    update_settings <= 1'b1;
    @(posedge CLK);
    update_settings <= 1'b0;

    #15000;

    for (int i = 0; i < 10000; i++) begin
      @(posedge CLK);
      for (int s = 0; s < params::NumSegment; s++) begin
        `ASSERT_EQ('0, idx[s]);
      end
    end

    $display("OK! sim_stm_timer_normal");
    $finish();
  end

endmodule
