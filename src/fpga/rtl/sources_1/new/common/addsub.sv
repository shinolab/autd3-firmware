`timescale 1ns / 1ps
module addsub #(
    parameter int WIDTH = 16
) (
    input var CLK,
    input var [WIDTH-1:0] A,
    input var [WIDTH-1:0] B,
    input var ADD,
    output var [WIDTH-1:0] S
);

  ADDSUB_MACRO #(
      .DEVICE ("7SERIES"),
      .LATENCY(2),
      .WIDTH  (WIDTH)
  ) ADDSUB_MACRO_inst (
      .CARRYOUT(),
      .RESULT(S),
      .A(A),
      .ADD_SUB(ADD),
      .B(B),
      .CARRYIN(1'b0),
      .CE(1'b1),
      .CLK(CLK),
      .RST()
  );

endmodule
