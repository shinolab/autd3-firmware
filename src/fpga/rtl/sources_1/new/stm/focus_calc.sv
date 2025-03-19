`timescale 1ns / 1ps
module focus_calc #(
    parameter string MODE = "NearestEven"
) (
    input wire CLK,
    input wire signed [17:0] FOCUS_X,
    input wire signed [17:0] FOCUS_Y,
    input wire signed [17:0] FOCUS_Z,
    input wire signed [15:0] TRANS_X,
    input wire signed [15:0] TRANS_Y,
    input wire [15:0] SOUND_SPEED,
    input wire [7:0] OFFSET,
    output wire [7:0] SIN,
    output wire [7:0] COS
);
  logic signed [17:0] dx, dy;
  logic [35:0] dx2, dy2, dz2, dxy2, d2;
  logic [23:0] sqrt_dout;

  logic [31:0] quo;
  logic [15:0] _unused_rem;

  addsub #(
      .WIDTH(18)
  ) addsub_x (
      .CLK(CLK),
      .A  (FOCUS_X),
      .B  ({2'b00, TRANS_X}),
      .ADD(1'b0),
      .S  (dx)
  );

  addsub #(
      .WIDTH(18)
  ) addsub_y (
      .CLK(CLK),
      .A  (FOCUS_Y),
      .B  ({2'b00, TRANS_Y}),
      .ADD(1'b0),
      .S  (dy)
  );

  mult #(
      .WIDTH_A(18),
      .WIDTH_B(18)
  ) mult_x (
      .CLK(CLK),
      .A  (dx),
      .B  (dx),
      .P  (dx2)
  );

  mult #(
      .WIDTH_A(18),
      .WIDTH_B(18)
  ) mult_y (
      .CLK(CLK),
      .A  (dy),
      .B  (dy),
      .P  (dy2)
  );

  mult #(
      .WIDTH_A(18),
      .WIDTH_B(18)
  ) mult_z (
      .CLK(CLK),
      .A  (FOCUS_Z),
      .B  (FOCUS_Z),
      .P  (dz2)
  );

  addsub #(
      .WIDTH(36)
  ) addsub_xy2 (
      .CLK(CLK),
      .A  (dx2),
      .B  (dy2),
      .ADD(1'b1),
      .S  (dxy2)
  );

  addsub #(
      .WIDTH(36)
  ) addsub_xyz2 (
      .CLK(CLK),
      .A  (dxy2),
      .B  (dz2),
      .ADD(1'b1),
      .S  (d2)
  );

  if (MODE == "NearestEven") begin
    sqrt_36 sqrt_36 (
        .aclk(CLK),
        .s_axis_cartesian_tvalid(1'b1),
        .s_axis_cartesian_tdata({4'd0, d2}),
        .m_axis_dout_tvalid(),
        .m_axis_dout_tdata(sqrt_dout)
    );
  end else if (MODE == "TRUNC") begin
    logic [23:0] sqrt_dout_buf;
    sqrt_36_trunc sqrt_36_trunc (
        .aclk(CLK),
        .s_axis_cartesian_tvalid(1'b1),
        .s_axis_cartesian_tdata({4'd0, d2}),
        .m_axis_dout_tvalid(),
        .m_axis_dout_tdata(sqrt_dout_buf)
    );
    always_ff @(posedge CLK) sqrt_dout <= sqrt_dout_buf;
  end

  div_32_16 div_32_16_quo (
      .s_axis_dividend_tdata({sqrt_dout[17:0], 14'd0}),
      .s_axis_dividend_tvalid(1'b1),
      .s_axis_divisor_tdata(SOUND_SPEED),
      .s_axis_divisor_tvalid(1'b1),
      .aclk(CLK),
      .m_axis_dout_tdata({quo, _unused_rem}),
      .m_axis_dout_tvalid()
  );

  wire [7:0] phase = quo[7:0] + OFFSET;
  sin_table sin_table (
      .a(phase),
      .d('0),
      .dpra(phase + 8'd64),
      .clk(CLK),
      .we(1'b0),
      .spo(SIN),
      .dpo(COS)
  );

endmodule
