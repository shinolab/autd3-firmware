`timescale 1ns / 1ps
interface stm_bus_if ();

  logic [12:0] ADDR;
  logic [511:0] VALUE;
  logic MODE;
  logic SEGMENT;

  logic [9:0] GAIN_IDX;
  logic [7:0] GAIN_ADDR;
  logic [12:0] FOCUS_IDX;

  assign ADDR = MODE ? {GAIN_IDX, GAIN_ADDR[7:5]} : FOCUS_IDX;

  modport in_port(input ADDR, output VALUE, input SEGMENT);
  modport stm_port(output MODE, output SEGMENT);
  modport out_gain_port(output GAIN_IDX, output GAIN_ADDR, input VALUE);
  modport out_focus_port(output FOCUS_IDX, input VALUE);

endinterface
