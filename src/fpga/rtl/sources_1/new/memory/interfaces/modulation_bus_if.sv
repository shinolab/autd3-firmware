`timescale 1ns / 1ps
interface modulation_bus_if ();

  logic [14:0] IDX;
  logic [7:0] VALUE;
  logic SEGMENT;

  modport in_port(input IDX, output VALUE, input SEGMENT);
  modport out_port(output IDX, input VALUE, output SEGMENT);

endinterface
