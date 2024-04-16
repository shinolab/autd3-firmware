`timescale 1ns / 1ps
module sim_mod_swapchain ();

  `define ASSERT_EQ(expected, actual) \
  if (expected !== actual) begin \
    $error("%s:%d: expected is %s, but actual is %s", `__FILE__, `__LINE__, $sformatf("%0d", expected), $sformatf("%0d", actual));\
    $finish();\
  end

  localparam int AddSubLatency = 6;
  localparam int DEPTH = 249;

  logic CLK;
  logic locked;
  logic [63:0] SYS_TIME;
  sim_helper_clk sim_helper_clk (
      .CLK_20P48M(CLK),
      .LOCKED(locked),
      .SYS_TIME(SYS_TIME)
  );

  logic update_settings;
  logic req_rd_segment;
  logic [7:0] transition_mode;
  logic [63:0] transition_value;
  logic gpio_in[4];
  logic [31:0] rep[2];
  logic [14:0] cycle[2];
  logic [14:0] sync_idx[2];
  logic [14:0] idx[2];
  logic segment;
  logic stop;

  modulation_swapchain modulation_swapchain (
      .CLK(CLK),
      .SYS_TIME(SYS_TIME),
      .UPDATE_SETTINGS(update_settings),
      .REQ_RD_SEGMENT(req_rd_segment),
      .TRANSITION_MODE(transition_mode),
      .TRANSITION_VALUE(transition_value),
      .CYCLE(cycle),
      .REP(rep),
      .SYNC_IDX(sync_idx),
      .GPIO_IN(gpio_in),
      .SEGMENT(segment),
      .STOP(stop),
      .IDX(idx)
  );

  task automatic reset();
    @(posedge CLK);
    sync_idx[0] <= 0;
    sync_idx[1] <= 0;
    rep[0] <= 32'hFFFFFFFF;
    rep[1] <= 32'hFFFFFFFF;
    transition_mode <= params::TRANSITION_MODE_SYNC_IDX;
    transition_value <= 0;
    req_rd_segment <= 0;
    update_settings <= 1;
    @(posedge CLK);
    update_settings <= 0;
    @(negedge CLK);
    `ASSERT_EQ(0, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(0, idx[0]);
    `ASSERT_EQ(0, idx[1]);
  endtask

  task automatic test_sync_idx();
    @(posedge CLK);
    sync_idx[0] <= 0;
    sync_idx[1] <= 0;
    transition_mode <= params::TRANSITION_MODE_SYNC_IDX;
    transition_value <= 0;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(0, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(0, idx[0]);
    `ASSERT_EQ(0, idx[1]);

    // Index change
    @(posedge CLK);
    sync_idx[0] <= 1;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(0, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(1, idx[0]);
    `ASSERT_EQ(0, idx[1]);

    // segment change to 1, immidiate
    @(posedge CLK);
    sync_idx[1] <= 1;
    rep[1] <= 32'hFFFFFFFF;
    req_rd_segment <= 1;
    update_settings <= 1;
    @(posedge CLK);
    update_settings <= 0;
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(1, idx[0]);
    `ASSERT_EQ(1, idx[1]);

    // segment change to 0, wait for idx[0] == 0, repeat one time
    @(posedge CLK);
    sync_idx[1] <= 1;
    rep[0] <= 32'h0;
    req_rd_segment <= 0;
    update_settings <= 1;
    @(posedge CLK);
    update_settings <= 0;
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(1, idx[0]);
    `ASSERT_EQ(1, idx[1]);

    // Index change
    @(posedge CLK);
    sync_idx[0] <= 2;
    sync_idx[1] <= 2;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(2, idx[0]);
    `ASSERT_EQ(2, idx[1]);

    // Index change to 0, change segment
    @(posedge CLK);
    sync_idx[0] <= 0;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(0, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(0, idx[0]);
    `ASSERT_EQ(2, idx[1]);

    // Index change
    @(posedge CLK);
    sync_idx[0] <= 1;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(0, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(1, idx[0]);
    `ASSERT_EQ(2, idx[1]);

    // Index change, first loop done
    @(posedge CLK);
    sync_idx[0] <= 0;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(0, segment);
    `ASSERT_EQ(1, stop);
    `ASSERT_EQ(0, idx[0]);
    `ASSERT_EQ(2, idx[1]);

    // segment change to 1, wait for idx[1] == 0, repeat 2 times
    @(posedge CLK);
    rep[1] <= 32'h1;
    req_rd_segment <= 1;
    update_settings <= 1;
    @(posedge CLK);
    update_settings <= 0;
    @(negedge CLK);
    `ASSERT_EQ(0, segment);
    `ASSERT_EQ(1, stop);
    `ASSERT_EQ(0, idx[0]);
    `ASSERT_EQ(2, idx[1]);

    // Index change to 0, change segment
    @(posedge CLK);
    sync_idx[1] <= 0;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(0, idx[0]);
    `ASSERT_EQ(0, idx[1]);

    // Index change
    @(posedge CLK);
    sync_idx[1] <= 1;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(0, idx[0]);
    `ASSERT_EQ(1, idx[1]);

    // Index change, first loop done
    @(posedge CLK);
    sync_idx[1] <= 0;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(0, idx[0]);
    `ASSERT_EQ(0, idx[1]);

    // Index change
    @(posedge CLK);
    sync_idx[1] <= 1;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(0, idx[0]);
    `ASSERT_EQ(1, idx[1]);

    // Index change, second loop done, assert stop
    @(posedge CLK);
    sync_idx[1] <= 0;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(1, stop);
    `ASSERT_EQ(0, idx[0]);
    `ASSERT_EQ(0, idx[1]);

    // segment change to 1, immidiate
    @(posedge CLK);
    rep[1] <= 32'hFFFFFFFF;
    req_rd_segment <= 1;
    update_settings <= 1;
    @(posedge CLK);
    update_settings <= 0;
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(0, idx[0]);
    `ASSERT_EQ(0, idx[1]);
  endtask

  task automatic test_gpio();
    @(posedge CLK);
    sync_idx[0] <= 0;
    sync_idx[1] <= 0;
    transition_mode <= params::TRANSITION_MODE_GPIO;
    transition_value <= 0;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(0, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(0, idx[0]);
    `ASSERT_EQ(0, idx[1]);

    // Index change
    @(posedge CLK);
    sync_idx[0] <= 1;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(0, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(1, idx[0]);
    `ASSERT_EQ(0, idx[1]);

    // segment change to 1, immidiate
    @(posedge CLK);
    sync_idx[1] <= 1;
    rep[1] <= 32'hFFFFFFFF;
    req_rd_segment <= 1;
    update_settings <= 1;
    @(posedge CLK);
    update_settings <= 0;
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(1, idx[0]);
    `ASSERT_EQ(1, idx[1]);

    // segment change to 0, wait for GPIO[0] and idx[0] changed, repeat one time
    @(posedge CLK);
    sync_idx[1] <= 1;
    rep[0] <= 32'h0;
    req_rd_segment <= 0;
    gpio_in[0] <= 1'b1;
    update_settings <= 1;
    @(posedge CLK);
    update_settings <= 0;
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(1, idx[0]);
    `ASSERT_EQ(1, idx[1]);

    // Index change, change segment
    @(posedge CLK);
    sync_idx[0] <= 2;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(0, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(0, idx[0]);

    // Index change
    @(posedge CLK);
    sync_idx[0] <= sync_idx[0] + 1;
    gpio_in[0]  <= 1'b0;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(0, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(1, idx[0]);

    // Index change
    @(posedge CLK);
    sync_idx[0] <= sync_idx[0] + 1;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(0, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(2, idx[0]);

    // Index change, first loop done
    @(posedge CLK);
    sync_idx[0] <= sync_idx[0] + 1;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(0, segment);
    `ASSERT_EQ(1, stop);
    `ASSERT_EQ(0, idx[0]);

    // segment change to 1, wait for idx[1] changed, repeat 2 times
    @(posedge CLK);
    rep[1] <= 32'h1;
    req_rd_segment <= 1;
    gpio_in[0] <= 1'b1;
    update_settings <= 1;
    @(posedge CLK);
    update_settings <= 0;
    @(negedge CLK);
    `ASSERT_EQ(0, segment);
    `ASSERT_EQ(1, stop);
    `ASSERT_EQ(0, idx[0]);

    // Index change, change segment
    @(posedge CLK);
    sync_idx[1] <= sync_idx[1] + 1;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(0, idx[1]);

    // Index change
    @(posedge CLK);
    sync_idx[1] <= sync_idx[1] + 1;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(1, idx[1]);

    // Index change
    @(posedge CLK);
    sync_idx[1] <= sync_idx[1] + 1;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(2, idx[1]);

    // Index change, first loop done
    @(posedge CLK);
    sync_idx[1] <= sync_idx[1] + 1;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(0, idx[1]);

    // Index change
    @(posedge CLK);
    sync_idx[1] <= sync_idx[1] + 1;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(1, idx[1]);

    // Index change
    @(posedge CLK);
    sync_idx[1] <= sync_idx[1] + 1;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(2, idx[1]);

    // Index change, second loop done, assert stop
    @(posedge CLK);
    sync_idx[1] <= sync_idx[1] + 1;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(1, stop);
    `ASSERT_EQ(0, idx[1]);

    // segment change to 1, immidiate
    @(posedge CLK);
    sync_idx[0] <= 0;
    sync_idx[1] <= 0;
    rep[1] <= 32'hFFFFFFFF;
    req_rd_segment <= 1;
    update_settings <= 1;
    @(posedge CLK);
    update_settings <= 0;
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(0, idx[0]);
    `ASSERT_EQ(0, idx[1]);
  endtask

  task automatic test_sys_time();
    @(posedge CLK);
    sync_idx[0] <= 0;
    sync_idx[1] <= 0;
    transition_mode <= params::TRANSITION_MODE_SYS_TIME;
    transition_value <= 0;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(0, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(0, idx[0]);
    `ASSERT_EQ(0, idx[1]);

    // Index change
    @(posedge CLK);
    sync_idx[0] <= 1;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(0, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(1, idx[0]);
    `ASSERT_EQ(0, idx[1]);

    // segment change to 1, immidiate
    @(posedge CLK);
    sync_idx[1] <= 1;
    rep[1] <= 32'hFFFFFFFF;
    req_rd_segment <= 1;
    update_settings <= 1;
    @(posedge CLK);
    update_settings <= 0;
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(1, idx[0]);
    `ASSERT_EQ(1, idx[1]);

    @(posedge CLK);
    transition_value <= SYS_TIME + 5;
    repeat (AddSubLatency) @(posedge CLK);

    // segment change to 0, wait for 5 clocks, repeat one time
    @(posedge CLK);
    sync_idx[1] <= sync_idx[1] + 1;
    rep[0] <= 32'h0;
    req_rd_segment <= 0;
    update_settings <= 1;
    @(posedge CLK);
    update_settings <= 0;
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(sync_idx[1], idx[1]);

    // wait for 3 clocks
    for (int i = 0; i < 3; i++) begin
      @(posedge CLK);
      @(negedge CLK);
      `ASSERT_EQ(1, segment);
      `ASSERT_EQ(0, stop);
    end

    // change segment
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(0, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(0, idx[0]);

    // Index change
    @(posedge CLK);
    sync_idx[0] <= sync_idx[0] + 100;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(0, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(1, idx[0]);

    // Index change
    @(posedge CLK);
    sync_idx[0] <= sync_idx[0] + 1;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(0, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(2, idx[0]);

    // Index change, first loop done
    @(posedge CLK);
    sync_idx[0] <= sync_idx[0] + 1;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(0, segment);
    `ASSERT_EQ(1, stop);
    `ASSERT_EQ(0, idx[0]);

    @(posedge CLK);
    transition_value <= SYS_TIME + 5;
    repeat (AddSubLatency) @(posedge CLK);

    // segment change to 1, wait for for 5 clocks, repeat 2 times
    @(posedge CLK);
    rep[1] <= 32'h1;
    req_rd_segment <= 1;
    update_settings <= 1;
    @(posedge CLK);
    update_settings <= 0;
    @(negedge CLK);
    `ASSERT_EQ(0, segment);
    `ASSERT_EQ(1, stop);
    `ASSERT_EQ(0, idx[0]);

    // wait for 3 clocks
    for (int i = 0; i < 3; i++) begin
      @(posedge CLK);
      @(negedge CLK);
      `ASSERT_EQ(0, segment);
      `ASSERT_EQ(1, stop);
    end

    // change segment
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(0, idx[1]);

    // Index change
    @(posedge CLK);
    sync_idx[1] <= sync_idx[1] + 1;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(1, idx[1]);

    // Index change
    @(posedge CLK);
    sync_idx[1] <= sync_idx[1] + 1;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(2, idx[1]);

    // Index change, first loop done
    @(posedge CLK);
    sync_idx[1] <= sync_idx[1] + 1;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(0, idx[1]);

    // Index change
    @(posedge CLK);
    sync_idx[1] <= sync_idx[1] + 1;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(1, idx[1]);

    // Index change
    @(posedge CLK);
    sync_idx[1] <= sync_idx[1] + 1;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(2, idx[1]);

    // Index change, second loop done, assert stop
    @(posedge CLK);
    sync_idx[1] <= sync_idx[1] + 1;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(1, stop);
    `ASSERT_EQ(0, idx[1]);

    // segment change to 1, immidiate
    @(posedge CLK);
    sync_idx[0] <= 0;
    sync_idx[1] <= 0;
    rep[1] <= 32'hFFFFFFFF;
    req_rd_segment <= 1;
    update_settings <= 1;
    @(posedge CLK);
    update_settings <= 0;
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(0, idx[0]);
    `ASSERT_EQ(0, idx[1]);
  endtask

  initial begin
    update_settings = 0;
    transition_mode = params::TRANSITION_MODE_SYNC_IDX;
    transition_value = '0;
    req_rd_segment = 0;
    sync_idx[0] = 0;
    sync_idx[1] = 0;
    cycle[0] = 3 - 1;
    cycle[1] = 3 - 1;
    rep[0] = 32'hFFFFFFFF;
    rep[1] = 32'hFFFFFFFF;
    gpio_in = {1'b0, 1'b0, 1'b0, 1'b0};

    @(posedge locked);

    reset();
    test_sync_idx();

    reset();
    test_gpio();

    reset();
    test_sys_time();

    $display("OK! sim_mod_swapchain");
    $finish();
  end

endmodule
