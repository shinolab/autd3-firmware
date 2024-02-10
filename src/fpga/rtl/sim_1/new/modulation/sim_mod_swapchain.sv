`timescale 1ns / 1ps
module sim_mod_swapchain ();

  localparam int DEPTH = 249;
  localparam int SIZE = 1024;

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

  settings::mod_settings_t mod_settings;
  logic update_settings;
  logic [14:0] idx_0, idx_1;
  logic segment;
  logic stop;

  modulation_timer modulation_timer (
      .CLK(CLK),
      .UPDATE_SETTINGS_IN(update_settings),
      .SYS_TIME(sys_time),
      .CYCLE_0(mod_settings.CYCLE_0),
      .FREQ_DIV_0(mod_settings.FREQ_DIV_0),
      .CYCLE_1(mod_settings.CYCLE_1),
      .FREQ_DIV_1(mod_settings.FREQ_DIV_1),
      .IDX_0(idx_0),
      .IDX_1(idx_1),
      .UPDATE_SETTINGS_OUT(update_settings_t)
  );

  modulation_swapchain modulation_swapchain (
      .CLK(CLK),
      .UPDATE_SETTINGS(update_settings_t),
      .REQ_RD_SEGMENT(mod_settings.REQ_RD_SEGMENT),
      .REP(mod_settings.REP),
      .IDX_0_IN(idx_0),
      .IDX_1_IN(idx_1),
      .SEGMENT(segment),
      .STOP(stop)
  );

  task automatic update(input logic req_segment, input logic [31:0] rep);
    @(posedge CLK);
    update_settings <= 1'b1;
    mod_settings.REQ_RD_SEGMENT <= req_segment;
    mod_settings.REP <= rep;
    if (req_segment === 1'b0) begin
      mod_settings.CYCLE_0 <= 20 - 1;
      mod_settings.FREQ_DIV_0 <= 10;
    end else begin
      mod_settings.CYCLE_1 <= 10 - 1;
      mod_settings.FREQ_DIV_1 <= 10 * 3;
    end
    @(posedge CLK);
    update_settings <= 1'b0;
  endtask

  initial begin
    sim_helper_random.init();

    @(posedge locked);

    update(0, 32'hFFFFFFFF);

    #(200 * 1000);

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
