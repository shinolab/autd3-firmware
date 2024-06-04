`timescale 1ns / 1ps
interface duty_table_bus_if ();

  logic [14:0] IDX;
  logic [ 7:0] VALUE;

  modport in_port(input IDX, output VALUE);
  modport out_port(output IDX, input VALUE);

endinterface
