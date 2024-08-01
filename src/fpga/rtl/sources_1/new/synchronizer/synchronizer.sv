`timescale 1ns / 1ps
module synchronizer (
    input wire CLK,
    input wire settings::sync_settings_t SYNC_SETTINGS,
    input wire ECAT_SYNC,
    output var [63:0] SYS_TIME,
    output var SYNC,
    output var SKIP_ONE_ASSERT
);

  localparam int AddSubLatency = 6;

  localparam logic [12:0] ECATSyncBaseCnt = 13'd5120;  // 10.24MHz * 500000ns

  logic [63:0] ecat_sync_time;
  logic [63:0] sync_time;

  logic [2:0] sync_tri;
  logic sync;
  assign SYNC = sync;

  logic [63:0] sys_time;
  logic [63:0] next_sync_time;
  logic signed [18:0] sync_time_diff;
  logic [$clog2(AddSubLatency+1+1)-1:0] diff_cnt;
  logic [$clog2(AddSubLatency+1+1)-1:0] next_cnt;
  logic set;
  logic [12:0] next_sync_cnt;

  logic [63:0] a_diff, b_diff;
  logic signed [64:0] s_diff;
  logic [63:0] a_next, b_next, s_next;

  logic skip_one_assert;
  assign SKIP_ONE_ASSERT = skip_one_assert;

  ec_time_to_sys_time ec_time_to_sys_time (
      .CLK(CLK),
      .EC_TIME(ecat_sync_time),
      .DIN_VALID(1'b1),
      .SYS_TIME(sync_time),
      .DOUT_VALID()
  );

  sub64_64 sub_diff (
      .CLK(CLK),
      .A  (a_diff),
      .B  (b_diff),
      .S  (s_diff)
  );

  add64_64 add_next (
      .CLK(CLK),
      .A  (a_next),
      .B  (b_next),
      .S  (s_next)
  );

  assign sync = sync_tri == 3'b011;
  assign SYS_TIME = sys_time;

  always_ff @(posedge CLK) begin
    if (set & sync) begin
      set <= 1'b0;
    end else if (SYNC_SETTINGS.UPDATE) begin
      set <= 1'b1;
      ecat_sync_time <= SYNC_SETTINGS.ECAT_SYNC_TIME;
    end
  end

  always_ff @(posedge CLK) begin
    if (sync) begin
      if (set) begin
        sys_time <= sync_time;
        a_diff <= '0;
        b_diff <= '0;
        next_sync_time <= sync_time;
        sync_time_diff <= '0;
      end else begin
        a_diff   <= next_sync_time;
        b_diff   <= sys_time;
        sys_time <= sys_time + 1;
      end
      diff_cnt <= '0;
      next_sync_cnt <= {1'b0, ECATSyncBaseCnt[12:1]};
      skip_one_assert <= 1'b0;
    end else begin
      if (diff_cnt == AddSubLatency + 1) begin
        if (sync_time_diff == '0) begin
          sys_time <= sys_time + 1;
          skip_one_assert <= 1'b0;
        end else if (sync_time_diff < 19'sd0) begin
          sys_time <= sys_time;
          skip_one_assert <= 1'b0;
          sync_time_diff <= sync_time_diff + 1;
        end else begin
          sys_time <= sys_time + 2;
          skip_one_assert <= 1'b1;
          sync_time_diff <= sync_time_diff - 1;
        end
      end else if (diff_cnt == AddSubLatency) begin
        sync_time_diff <= {s_diff[64], s_diff[17:0]};
        diff_cnt <= diff_cnt + 1;
        sys_time <= sys_time + 1;
        skip_one_assert <= 1'b0;
      end else begin
        diff_cnt <= diff_cnt + 1;
        sys_time <= sys_time + 1;
        skip_one_assert <= 1'b0;
      end

      if (next_sync_cnt == ECATSyncBaseCnt - 1) begin
        next_sync_cnt <= 0;
        a_next <= next_sync_time;
        b_next <= {51'd0, ECATSyncBaseCnt};
        next_cnt <= 0;
      end else begin
        if (next_cnt == AddSubLatency + 1) begin
          next_cnt <= next_cnt;
        end else if (next_cnt == AddSubLatency) begin
          next_sync_time <= s_next;
          next_cnt <= next_cnt + 1;
        end else begin
          next_cnt <= next_cnt + 1;
        end
        next_sync_cnt <= next_sync_cnt + 1;
      end
    end
  end

  always_ff @(posedge CLK) sync_tri <= {sync_tri[1:0], ECAT_SYNC};


endmodule
