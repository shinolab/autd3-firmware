`timescale 1ns / 1ps
module sim_stm_swapchain ();

  `include "define.vh"

  localparam int DEPTH = 249;
  localparam int ECAT_SYNC_BASE_CNT = 40000 * 256 / 2000;

  logic CLK;
  logic locked;
  logic [55:0] SYS_TIME;
  sim_helper_clk sim_helper_clk (
      .MRCC_25P6M(),
      .CLK(CLK),
      .LOCKED(locked),
      .SYS_TIME(SYS_TIME)
  );

  logic update_settings;
  logic req_rd_segment;
  logic [7:0] transition_mode;
  logic [63:0] transition_value;
  logic gpio_in[4];
  logic [15:0] rep[params::NumSegment];
  logic [12:0] cycle[params::NumSegment];
  logic [12:0] sync_idx[params::NumSegment];
  logic [12:0] idx[params::NumSegment];
  logic segment;
  logic stop;

  stm_swapchain stm_swapchain (
      .CLK(CLK),
      .SYS_TIME(SYS_TIME),
      .UPDATE_SETTINGS(update_settings),
      .REQ_RD_SEGMENT(req_rd_segment),
      .TRANSITION_MODE(transition_mode),
      .TRANSITION_VALUE(transition_value),
      .UFREQ_MULT(320),
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
    rep[0] <= 16'hFFFF;
    rep[1] <= 16'hFFFF;
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
    rep[1] <= 16'hFFFF;
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
    rep[0] <= 16'h0000;
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
    rep[1] <= 16'hFFFF;
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
    rep[1] <= 16'hFFFF;
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
    rep[0] <= 16'h0000;
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
    rep[1] <= 16'hFFFF;
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
    #500000;
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
    rep[1] <= 16'hFFFF;
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
    transition_value <= (SYS_TIME / ECAT_SYNC_BASE_CNT + 1) * 500000;

    // segment change to 0, repeat one time
    @(posedge CLK);
    sync_idx[1] <= sync_idx[1] + 1;
    rep[0] <= 16'h0000;
    req_rd_segment <= 0;
    update_settings <= 1;
    @(posedge CLK);
    update_settings <= 0;
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(sync_idx[1], idx[1]);

    // wait
    while (1'b1) begin
      @(posedge CLK);
      @(negedge CLK);
      `ASSERT_EQ(1, segment);
      `ASSERT_EQ(0, stop);
      if (SYS_TIME == ECAT_SYNC_BASE_CNT * 2 + 5) break;
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
    transition_value <= (SYS_TIME / ECAT_SYNC_BASE_CNT + 2) * 500000;

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

    // wait
    while (1'b1) begin
      @(posedge CLK);
      @(negedge CLK);
      `ASSERT_EQ(0, segment);
      `ASSERT_EQ(1, stop);
      if (SYS_TIME == ECAT_SYNC_BASE_CNT * 4 + 5) break;
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
    rep[1] <= 16'hFFFF;
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

  task automatic test_ext();
    @(posedge CLK);
    sync_idx[0] <= 0;
    sync_idx[1] <= 0;
    transition_mode <= params::TRANSITION_MODE_EXT;
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
    rep[1] <= 16'hFFFF;
    req_rd_segment <= 1;
    update_settings <= 1;
    @(posedge CLK);
    update_settings <= 0;
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(1, idx[0]);
    `ASSERT_EQ(1, idx[1]);

    // segment change to 0, wait for idx[1] == 0
    @(posedge CLK);
    sync_idx[1] <= 1;
    @(posedge CLK);
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

    // Index change, change segment to 1
    @(posedge CLK);
    sync_idx[0] <= 0;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(0, idx[0]);
    `ASSERT_EQ(0, idx[1]);

    // Index change
    @(posedge CLK);
    sync_idx[0] <= 1;
    sync_idx[1] <= 3;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(1, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(1, idx[0]);
    `ASSERT_EQ(3, idx[1]);

    // Index change, change segment to 0
    @(posedge CLK);
    sync_idx[0] <= 2;
    sync_idx[1] <= 0;
    @(posedge CLK);
    @(negedge CLK);
    `ASSERT_EQ(0, segment);
    `ASSERT_EQ(0, stop);
    `ASSERT_EQ(2, idx[0]);
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
    rep[0] = 16'hFFFF;
    rep[1] = 16'hFFFF;
    gpio_in = {1'b0, 1'b0, 1'b0, 1'b0};

    @(posedge locked);

    reset();
    test_sync_idx();

    reset();
    test_gpio();

    reset();
    test_sys_time();

    reset();
    test_ext();

    reset();

    $display("OK! sim_stm_swapchain");
    $finish();
  end

endmodule
