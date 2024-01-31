`timescale 1ns / 1ps
interface modulation_bus_if ();

  logic [15:0] ADDR;
  logic [ 7:0] M;

  modport memory_port(input ADDR, output M);
  modport sampler_port(output ADDR, input M);

endinterface
