`timescale 1ns / 1ps
module delay_fifo #(
    parameter int WIDTH = 8,
    parameter int DEPTH = 16
) (
    input wire CLK,
    input wire [WIDTH-1:0] DIN,
    output wire [WIDTH-1:0] DOUT
);

  logic [WIDTH-1:0] buffer[DEPTH];
  assign DOUT = buffer[DEPTH-1];

  always_ff @(posedge CLK) buffer[0] <= DIN;
  for (genvar i = 1; i < DEPTH; i++) begin : gen_buffer
    always_ff @(posedge CLK) buffer[i] <= buffer[i-1];
  end

endmodule
