`timescale 1ns / 1ps
module time_cnt_generator #(
    parameter int DEPTH = 249
) (
    input wire CLK,
    input wire [60:0] SYS_TIME,
    input wire SKIP_ONE_ASSERT,
    output wire [8:0] TIME_CNT,
    output wire UPDATE
);
  logic [8:0] t_buf0, t_buf1, t;
  logic update;

  wire  cross0 = t_buf0 == 8'd0;
  wire  cross0_with_skip = (t_buf0 == 8'd1) & SKIP_ONE_ASSERT;

  assign t_buf0   = SYS_TIME[8:0];
  assign UPDATE   = update;
  assign TIME_CNT = t;

  always_ff @(posedge CLK) begin
    t_buf1 <= t_buf0;
    t <= t_buf1;
    update <= cross0 | cross0_with_skip;
  end

endmodule
