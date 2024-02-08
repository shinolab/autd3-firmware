`timescale 1ns / 1ps
interface mod_cnt_if ();

  logic [14:0] IDX_0;
  logic [14:0] IDX_1;
  logic SEGMENT;
  logic STOP;

  modport timer_port(output IDX_0, output IDX_1);
  modport swapchain_port(input IDX_0, input IDX_1, output SEGMENT, output STOP);
  modport multiplier_port(input IDX_0, input IDX_1, input SEGMENT, input STOP);

endinterface
