module memory (
    input var CLK,
    memory_bus_if.normal_port MEM_NORMAL_BUS,
    memory_bus_if.mod_port MEM_MOD_BUS,
    memory_bus_if.stm_port MEM_STM_BUS,
    modulation_bus_if.in_port MOD_BUS,
    normal_bus_if.in_port NORMAL_BUS,
    stm_bus_if.in_port STM_BUS
);

  /////////////////////////////   Normal  /////////////////////////////
  logic normal_bus_clk;
  logic normal_ena_0, normal_ena_1;
  logic normal_we;
  logic normal_page;
  logic [7:0] normal_addr;
  logic [15:0] normal_data_in;

  logic [7:0] normal_idx;
  logic [15:0] normal_value_0, normal_value_1;

  assign normal_bus_clk = MEM_NORMAL_BUS.BUS_CLK;
  assign normal_ena_0 = (MEM_NORMAL_BUS.NORMAL_EN) & (normal_page == 1'b0);
  assign normal_ena_1 = (MEM_NORMAL_BUS.NORMAL_EN) & (normal_page == 1'b1);
  assign normal_we = MEM_NORMAL_BUS.WE;
  assign normal_page = MEM_NORMAL_BUS.BRAM_ADDR[8];
  assign normal_addr = MEM_NORMAL_BUS.BRAM_ADDR[7:0];
  assign normal_data_in = MEM_NORMAL_BUS.DATA_IN;
  assign normal_idx = NORMAL_BUS.ADDR;
  assign NORMAL_BUS.VALUE = (NORMAL_BUS.SEGMENT == 1'b0) ? normal_value_0 : normal_value_1;

  BRAM_NORMAL normal_bram_0 (
      .clka (normal_bus_clk),
      .ena  (normal_ena_0),
      .wea  (normal_we),
      .addra(normal_addr),
      .dina (normal_data_in),
      .douta(),
      .clkb (CLK),
      .web  ('0),
      .addrb(normal_idx),
      .dinb ('0),
      .doutb(normal_value_0)
  );

  BRAM_NORMAL normal_bram_1 (
      .clka (normal_bus_clk),
      .ena  (normal_ena_1),
      .wea  (normal_we),
      .addra(normal_addr),
      .dina (normal_data_in),
      .douta(),
      .clkb (CLK),
      .web  ('0),
      .addrb(normal_idx),
      .dinb ('0),
      .doutb(normal_value_1)
  );
  /////////////////////////////   Normal  /////////////////////////////

  ///////////////////////////// Modulator /////////////////////////////
  logic mod_bus_clk;
  logic mod_ena_0, mod_ena_1;
  logic mod_we;
  logic [13:0] mod_addr;
  logic [15:0] mod_data_in;

  logic [14:0] mod_idx;
  logic [7:0] mod_value_0, mod_value_1;

  assign mod_bus_clk = MEM_MOD_BUS.BUS_CLK;
  assign mod_ena_0 = MEM_MOD_BUS.MOD_EN & (MEM_MOD_BUS.MOD_MEM_WR_SEGMENT == 1'b0);
  assign mod_ena_1 = MEM_MOD_BUS.MOD_EN & (MEM_MOD_BUS.MOD_MEM_WR_SEGMENT == 1'b1);
  assign mod_we = MEM_MOD_BUS.WE;
  assign mod_addr = MEM_MOD_BUS.BRAM_ADDR;
  assign mod_data_in = MEM_MOD_BUS.DATA_IN;
  assign mod_idx = MOD_BUS.IDX;
  assign MOD_BUS.VALUE = (MOD_BUS.SEGMENT == 1'b0) ? mod_value_0 : mod_value_1;

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

  /////////////////////////////    STM   /////////////////////////////
  logic stm_bus_clk;
  logic stm_ena_0, stm_ena_1;
  logic stm_we;
  logic [17:0] stm_addr;
  logic [15:0] stm_data_in;

  logic [14:0] stm_idx;
  logic [127:0] stm_value_0, stm_value_1;

  assign stm_bus_clk = MEM_STM_BUS.BUS_CLK;
  assign stm_ena_0 = MEM_STM_BUS.STM_EN & (MEM_STM_BUS.STM_MEM_WR_SEGMENT == 1'b0);
  assign stm_ena_1 = MEM_STM_BUS.STM_EN & (MEM_STM_BUS.STM_MEM_WR_SEGMENT == 1'b1);
  assign stm_we = MEM_STM_BUS.WE;
  assign stm_addr = {MEM_STM_BUS.STM_MEM_WR_PAGE, MEM_STM_BUS.BRAM_ADDR};
  assign stm_data_in = MEM_STM_BUS.DATA_IN;
  assign stm_idx = STM_BUS.ADDR;
  assign STM_BUS.VALUE = (STM_BUS.SEGMENT == 1'b0) ? stm_value_0 : stm_value_1;

  BRAM_STM stm_bram_0 (
      .clka (stm_bus_clk),
      .ena  (stm_ena_0),
      .wea  (stm_we),
      .addra(stm_addr),
      .dina (stm_data_in),
      .douta(),
      .clkb (CLK),
      .web  ('0),
      .addrb(stm_idx),
      .dinb ('0),
      .doutb(stm_value_0)
  );

  BRAM_STM stm_bram_1 (
      .clka (stm_bus_clk),
      .ena  (stm_ena_1),
      .wea  (stm_we),
      .addra(stm_addr),
      .dina (stm_data_in),
      .douta(),
      .clkb (CLK),
      .web  ('0),
      .addrb(stm_idx),
      .dinb ('0),
      .doutb(stm_value_1)
  );
  /////////////////////////////    STM   /////////////////////////////

endmodule
