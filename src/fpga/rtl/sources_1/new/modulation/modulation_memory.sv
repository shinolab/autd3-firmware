/*
 * File: modulation_memory.sv
 * Project: modulation
 * Created Date: 24/03/2022
 * Author: Shun Suzuki
 * -----
 * Last Modified: 17/11/2023
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2022-2023 Shun Suzuki. All rights reserved.
 *
 */

`timescale 1ns / 1ps
module modulation_memory (
    input var CLK,
    cpu_bus_if.mod_port CPU_BUS,
    modulation_bus_if.memory_port M_BUS
);

  logic bus_clk;
  logic mod_ena;
  logic we;
  logic [14:0] mod_addr;
  logic [15:0] data_in;

  logic [15:0] idx;
  logic [7:0] m;

  assign bus_clk = CPU_BUS.BUS_CLK;
  assign mod_ena = CPU_BUS.MOD_EN;
  assign we = CPU_BUS.WE;
  assign mod_addr = {CPU_BUS.MOD_MEM_PAGE, CPU_BUS.BRAM_ADDR};
  assign data_in = CPU_BUS.DATA_IN;
  assign idx = M_BUS.ADDR;
  assign M_BUS.M = m;

  BRAM_MOD mod_bram (
      .clka (bus_clk),
      .ena  (mod_ena),
      .wea  (we),
      .addra(mod_addr),
      .dina (data_in),
      .douta(),
      .clkb (CLK),
      .web  ('0),
      .addrb(idx),
      .dinb ('0),
      .doutb(m)
  );

endmodule
