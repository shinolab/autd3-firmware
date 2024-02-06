`timescale 1ns / 1ps
module sim_mod_swapchain ();

  localparam int DEPTH = 249;
  localparam int SIZE = 1024;

  localparam int US = 1000;

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

  logic update_settings;
  autd3::mod_settings mod_settings;
  mod_cnt_if mod_cnt ();

  modulation_swapchain modulation_swapchain (
      .CLK(CLK),
      .UPDATE_SETTINGS(update_settings),
      .REQ_RD_SEGMENT(mod_settings.REQ_RD_SEGMENT),
      .REP(mod_settings.REP),
      .MOD_CNT(mod_cnt.swapchain_port)
  );

  modulation_timer modulation_timer (
      .CLK(CLK),
      .SYS_TIME(sys_time),
      .CYCLE_0(mod_settings.CYCLE_0),
      .FREQ_DIV_0(mod_settings.FREQ_DIV_0),
      .CYCLE_1(mod_settings.CYCLE_1),
      .FREQ_DIV_1(mod_settings.FREQ_DIV_1),
      .MOD_CNT(mod_cnt.sampler_port)
  );


  logic [14:0] idx_0, idx_1;
  logic segment;
  logic stop;

  assign idx_0 = mod_cnt.IDX_0;
  assign idx_1 = mod_cnt.IDX_1;
  assign segment = mod_cnt.SEGMENT;
  assign stop = mod_cnt.STOP;

  task automatic update(logic req_segment, logic [31:0] rep);
    @(posedge CLK);
    update_settings <= 1'b1;
    mod_settings.REQ_RD_SEGMENT = req_segment;
    mod_settings.REP = rep;
    @(posedge CLK);
    update_settings <= 1'b0;
  endtask

  initial begin
    sim_helper_random.init();

    mod_settings.CYCLE_0 = 20 - 1;
    mod_settings.FREQ_DIV_0 = 10;
    mod_settings.CYCLE_1 = 10 - 1;
    mod_settings.FREQ_DIV_1 = 10 * 3;
    update(0, 32'hFFFFFFFF);

    while (1'b1) begin
      if (idx_1 === 5) break;
      @(posedge CLK);
    end
    update(1, 32'd1);

    while (1'b1) begin
      if (stop) break;
      @(posedge CLK);
    end
    #1000;
    update(0, 32'd2);

    @(negedge stop);
    while (1'b1) begin
      if (stop) break;
      @(posedge CLK);
    end
    #1000;
    update(1, 32'hFFFFFFFF);

    $display("OK! sim_mod_swapchain");
  end

endmodule
