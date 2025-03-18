`timescale 1ns / 1ps
module synchronizer (
    input wire CLK,
    input wire settings::sync_settings_t SYNC_SETTINGS,
    input wire ECAT_SYNC,
    output var [56:0] SYS_TIME,
    output var SYNC,
    output var SKIP_ONE_ASSERT
);

  localparam int AddSubLatency = 5;
  localparam bit [14:0] EcatSyncCntBase = 14'd10240;  // 500us * 20.48MHz

  logic [63:0] ecat_sync_time;
  logic [56:0] sync_time;

  logic [2:0] sync_tri;
  logic sync;
  assign SYNC = sync;

  logic [56:0] sys_time;
  logic [56:0] next_sync_time;
  logic signed [13:0] sync_time_diff;
  logic [$clog2(AddSubLatency+1)-1:0] diff_cnt;
  logic [$clog2(AddSubLatency+1)-1:0] next_cnt;
  logic set;
  logic [14:0] next_sync_cnt;

  logic [56:0] a_diff, b_diff;
  logic signed [57:0] s_diff;
  logic [56:0] a_next = 0, b_next, s_next;

  logic skip_one_assert;
  assign SKIP_ONE_ASSERT = skip_one_assert;

  ec_time_to_sys_time ec_time_to_sys_time (
      .CLK(CLK),
      .EC_TIME(ecat_sync_time),
      .DIN_VALID(1'b1),
      .SYS_TIME(sync_time),
      .DOUT_VALID()
  );

  sub57_57 sub_diff (
      .CLK(CLK),
      .A  (a_diff),
      .B  (b_diff),
      .S  (s_diff)
  );

  add57_57 add_next (
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
        sys_time <= sync_time + 1;
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
      next_sync_cnt <= {1'b0, EcatSyncCntBase[13:1]};
      skip_one_assert <= 1'b0;
    end else begin
      if (diff_cnt == AddSubLatency + 1) begin
        if (sync_time_diff == '0) begin
          sys_time <= sys_time + 1;
          skip_one_assert <= 1'b0;
        end else if (sync_time_diff < 14'sd0) begin
          sys_time <= sys_time;
          skip_one_assert <= 1'b0;
          sync_time_diff <= sync_time_diff + 1;
        end else begin
          sys_time <= sys_time + 2;
          skip_one_assert <= 1'b1;
          sync_time_diff <= sync_time_diff - 1;
        end
      end else if (diff_cnt == AddSubLatency) begin
        sync_time_diff <= {s_diff[57], s_diff[12:0]};
        diff_cnt <= diff_cnt + 1;
        sys_time <= sys_time + 1;
        skip_one_assert <= 1'b0;
      end else begin
        diff_cnt <= diff_cnt + 1;
        sys_time <= sys_time + 1;
        skip_one_assert <= 1'b0;
      end

      if (next_sync_cnt == EcatSyncCntBase - 1) begin
        next_sync_cnt <= 0;
        a_next <= next_sync_time;
        b_next <= {47'd0, EcatSyncCntBase};
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
