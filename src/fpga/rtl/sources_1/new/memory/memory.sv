module memory (
    input var CLK,
    memory_bus_if.mod_port MEM_BUS,
    modulation_bus_if.memory_port MOD_BUS
);

  ///////////////////////////// Modulator /////////////////////////////
  logic mod_bus_clk;
  logic mod_ena_0, mod_ena_1;
  logic mod_we;
  logic [13:0] mod_addr;
  logic [15:0] mod_data_in;

  logic [14:0] mod_idx;
  logic [7:0] mod_value_0, mod_value_1;

  assign mod_bus_clk = MEM_BUS.BUS_CLK;
  assign mod_ena_0 = MEM_BUS.MOD_EN & (MEM_BUS.MOD_MEM_WR_PAGE == 1'b0);
  assign mod_ena_1 = MEM_BUS.MOD_EN & (MEM_BUS.MOD_MEM_WR_PAGE == 1'b1);
  assign mod_we = MEM_BUS.WE;
  assign mod_addr = MEM_BUS.BRAM_ADDR;
  assign mod_data_in = MEM_BUS.DATA_IN;
  assign mod_idx = MOD_BUS.ADDR;
  assign MOD_BUS.VALUE = (MOD_BUS.PAGE == 1'b0) ? mod_value_0 : mod_value_1;

  BRAM_MOD mod_bram_0 (
      .clka (mod_bus_clk),
      .ena  (mod_ena_0),
      .wea  (mod_we),
      .addra(mod_addr),
      .dina (mod_data_in),
      .douta(),
      .clkb (CLK),
      .web  ('0),
      .addrb(mod_idx),
      .dinb ('0),
      .doutb(mod_value_0)
  );

  BRAM_MOD mod_bram_1 (
      .clka (mod_bus_clk),
      .ena  (mod_ena_1),
      .wea  (mod_we),
      .addra(mod_addr),
      .dina (mod_data_in),
      .douta(),
      .clkb (CLK),
      .web  ('0),
      .addrb(mod_idx),
      .dinb ('0),
      .doutb(mod_value_1)
  );
  ///////////////////////////// Modulator /////////////////////////////

endmodule
