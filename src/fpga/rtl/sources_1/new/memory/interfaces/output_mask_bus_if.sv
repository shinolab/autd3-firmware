`timescale 1ns / 1ps
interface output_mask_bus_if ();

  logic SEGMENT;
  logic [255:0] VALUE;

  modport in_port(input SEGMENT, output VALUE);
  modport out_port(output SEGMENT, input VALUE);

endinterface
