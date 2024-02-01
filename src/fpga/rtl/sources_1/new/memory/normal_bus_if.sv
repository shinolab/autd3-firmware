`timescale 1ns / 1ps
interface normal_bus_if ();

  logic [7:0] ADDR;
  logic [15:0] VALUE;
  logic PAGE;

  modport in_port(input ADDR, output VALUE, input PAGE);
  modport out_port(output ADDR, input VALUE, output PAGE);

endinterface
