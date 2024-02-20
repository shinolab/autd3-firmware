`timescale 1ns / 1ps
interface filter_bus_if ();

  logic WE;
  logic [7:0] ADDR;
  logic [15:0] DIN;
  logic [15:0] DOUT;

  modport in_port(input WE, input ADDR, input DIN, output DOUT);
  modport out_port(output ADDR, input DOUT);

endinterface
