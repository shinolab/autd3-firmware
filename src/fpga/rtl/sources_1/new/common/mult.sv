`timescale 1ns / 1ps
module mult #(
    parameter int WIDTH_A = 16,
    parameter int WIDTH_B = 16
) (
    input wire CLK,
    input wire signed [WIDTH_A-1:0] A,
    input wire signed [WIDTH_B-1:0] B,
    output wire signed [WIDTH_A+WIDTH_B-1:0] P
);

  MULT_MACRO #(
      .DEVICE ("7SERIES"),
      .LATENCY(3),
      .WIDTH_A(WIDTH_A),
      .WIDTH_B(WIDTH_B)
  ) MULT_MACRO_inst (
      .P  (P),
      .A  (A),
      .B  (B),
      .CE (1'b1),
      .CLK(CLK),
      .RST()
  );

endmodule
