`timescale 1ns / 1ps
module sim_stm_swapchain ();

  `define ASSERT_EQ(expected, actual) \
  if (expected !== actual) begin \
    $error("%s:%d: expected is %s, but actual is %s", `__FILE__, `__LINE__, $sformatf("%0d", expected), $sformatf("%0d", actual));\
    $finish();\
  end

  localparam int DivLatency = 66;
  localparam int DEPTH = 249;

  logic CLK;
  logic locked;
  sim_helper_clk sim_helper_clk (
      .CLK_20P48M(CLK),
      .LOCKED(locked),
      .SYS_TIME()
  );

  logic update_settings;
  logic req_rd_segment;
  logic [31:0] rep[2];
  logic [15:0] sync_idx[2];
  logic [15:0] idx[2];
  logic segment;
  logic stop;

  stm_swapchain stm_swapchain (
      .CLK(CLK),
      .UPDATE_SETTINGS(update_settings),
      .REQ_RD_SEGMENT(req_rd_segment),
      .REP(rep),
      .IDX_IN(sync_idx),
      .SEGMENT(segment),
      .STOP(stop),
      .IDX_OUT(idx)
  );

  task automatic test_sync_idx();
    @(posedge CLK);
    sync_idx[0] <= 0;
    sync_idx[1] <= 0;
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

  initial begin
    update_settings = 0;
    req_rd_segment = 0;
    sync_idx[0] = 0;
    sync_idx[1] = 0;
    rep[0] = 32'hFFFFFFFF;
    rep[1] = 32'hFFFFFFFF;

    @(posedge locked);

    test_sync_idx();

    $display("OK! sim_stm_swapchain");
    $finish();
  end

endmodule
