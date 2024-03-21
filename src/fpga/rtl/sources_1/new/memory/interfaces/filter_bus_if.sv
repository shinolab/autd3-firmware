`timescale 1ns / 1ps
interface filter_bus_if ();

  logic [7:0] ADDR;
  logic [7:0] DOUT;

  modport in_port(input ADDR, output DOUT);
  modport out_port(output ADDR, input DOUT);

endinterface
