`timescale 1ns / 1ps
module sim_stm_timer_normal ();

  localparam int DEPTH = 249;

  logic CLK;
  logic locked;
  logic [63:0] sys_time;
  sim_helper_clk sim_helper_clk (
      .CLK_20P48M(CLK),
      .LOCKED(locked),
      .SYS_TIME(sys_time)
  );

  sim_helper_random sim_helper_random ();
  sim_helper_bram #(.DEPTH(DEPTH)) sim_helper_bram ();

  settings::stm_settings_t stm_settings;
  stm_cnt_if stm_cnt ();
  logic [15:0] idx_0, idx_1;

  assign idx_0 = stm_cnt.IDX_0;
  assign idx_1 = stm_cnt.IDX_1;

  stm_timer stm_timer (
      .CLK(CLK),
      .SYS_TIME(sys_time),
      .CYCLE_0(stm_settings.CYCLE_0),
      .FREQ_DIV_0(stm_settings.FREQ_DIV_0),
      .CYCLE_1(stm_settings.CYCLE_1),
      .FREQ_DIV_1(stm_settings.FREQ_DIV_1),
      .STM_CNT(stm_cnt.timer_port)
  );

  initial begin
    sim_helper_random.init();

    stm_settings.REQ_RD_SEGMENT = 1'b0;
    stm_settings.CYCLE_0 = 0;
    stm_settings.FREQ_DIV_0 = 8;
    stm_settings.CYCLE_1 = 0;
    stm_settings.FREQ_DIV_1 = 8 * 3;
    stm_settings.REP = 32'hFFFFFFFF;

    @(posedge locked);

    #15000;

    for (int i = 0; i < 10000; i++) begin
      @(posedge CLK);
      if ('0 !== idx_0) begin
        $error("Index[0] 0 !== %d", idx_0);
        $finish();
      end
      if ('0 !== idx_1) begin
        $error("Index[1] 0 !== %d", idx_1);
        $finish();
      end
    end

    $display("OK! sim_stm_timer_normal");
    $finish();
  end

endmodule
