`timescale 1ns / 1ps
module sim_stm_timer_normal ();

  `define ASSERT_EQ(expected, actual) \
  if (expected !== actual) begin \
    $error("%s:%d: expected is %s, but actual is %s", `__FILE__, `__LINE__, $sformatf("%0d", expected), $sformatf("%0d", actual));\
    $finish();\
  end

  localparam int DivLatency = 58;
  localparam int DEPTH = 249;

  logic CLK;
  logic locked;
  logic [63:0] sys_time;
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
  logic [12:0] idx[2];

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
      `ASSERT_EQ('0, idx[0]);
      `ASSERT_EQ('0, idx[1]);
    end

    $display("OK! sim_stm_timer_normal");
    $finish();
  end

endmodule
