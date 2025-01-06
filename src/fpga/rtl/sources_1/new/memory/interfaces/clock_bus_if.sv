`timescale 1ns / 1ps
interface clock_bus_if ();

  logic WE;
  logic [4:0] ADDR;
  logic [63:0] DIN;
  logic [63:0] DOUT;

  modport in_port(input WE, input ADDR, input DIN, output DOUT);
  modport out_port(output WE, output ADDR, output DIN, input DOUT);

endinterface
