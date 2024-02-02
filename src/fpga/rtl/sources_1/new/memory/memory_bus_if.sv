`timescale 1ns / 1ps
interface memory_bus_if ();

  logic BUS_CLK;
  logic EN;
  logic RD;
  logic WE;
  logic RDWR;
  logic [1:0] BRAM_SELECT;
  logic [13:0] BRAM_ADDR;
  logic [15:0] CPU_DATA;
  logic [15:0] DATA_IN;
  logic [15:0] DATA_OUT;
  logic [8:0] ENABLES;

  assign CPU_DATA = (EN & RD & RDWR) ? DATA_OUT : 16'bzzzzzzzzzzzzzzzz;
  assign DATA_IN  = CPU_DATA;

  modport bram_port(
      input BUS_CLK,
      input EN,
      input WE,
      input BRAM_SELECT,
      input BRAM_ADDR,
      input DATA_IN,
      output DATA_OUT,
      output ENABLES
  );

endinterface
