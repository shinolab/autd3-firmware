`timescale 1ns / 1ps
module clock (
    input  wire MRCC_25P6M,
    input  wire RESET,
    output wire CLK,
    output wire LOCKED
);

  clk_wiz clk_wiz (
      .reset(RESET),
      .clk_in1(MRCC_25P6M),
      .clk_out1(CLK),
      .locked(LOCKED)
  );

endmodule
