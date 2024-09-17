`timescale 1ns / 1ps
interface phase_corr_bus_if ();

  logic [7:0] IDX;
  logic [7:0] VALUE;

  modport in_port(input IDX, output VALUE);
  modport out_port(output IDX, input VALUE);

endinterface
