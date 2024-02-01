`timescale 1ns / 1ps
interface modulation_bus_if ();

  logic [14:0] ADDR;
  logic [7:0] VALUE;
  logic PAGE;

  modport memory_port(input ADDR, output VALUE, input PAGE);
  modport sampler_port(output ADDR, input VALUE, output PAGE);

endinterface
