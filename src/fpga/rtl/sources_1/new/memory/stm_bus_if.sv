`timescale 1ns / 1ps
interface stm_bus_if ();

  logic [14:0] ADDR;
  logic [127:0] VALUE;
  logic GAIN_STM_MODE;
  logic SEGMENT;

  logic [9:0] GAIN_IDX;
  logic [7:0] GAIN_ADDR;
  logic [14:0] FOCUS_IDX;

  assign ADDR = GAIN_STM_MODE ? {GAIN_IDX, GAIN_ADDR[7:3]} : FOCUS_IDX;

  modport in_port(input ADDR, output VALUE, input SEGMENT);
  modport out_gain_port(output GAIN_IDX, output GAIN_ADDR, input VALUE, output SEGMENT);
  modport out_focus_port(output FOCUS_IDX, input VALUE, output SEGMENT);

endinterface
