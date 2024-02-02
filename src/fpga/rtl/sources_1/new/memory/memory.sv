module memory (
    input var CLK,
    memory_bus_if.bram_port MEM_BUS,
    modulation_bus_if.in_port MOD_BUS,
    normal_bus_if.in_port NORMAL_BUS,
    stm_bus_if.in_port STM_BUS
);

  `include "params.vh"

  logic bus_clk;
  logic en;
  logic we;
  logic [1:0] select;
  logic [13:0] addr;
  logic [15:0] data_in;
  logic [15:0] data_out;

  assign bus_clk = MEM_BUS.BUS_CLK;
  assign select = MEM_BUS.BRAM_SELECT;
  assign en = MEM_BUS.EN;
  assign we = MEM_BUS.WE;
  assign addr = MEM_BUS.BRAM_ADDR;
  assign data_in = MEM_BUS.DATA_IN;
  assign MEM_BUS.DATA_OUT = data_out;

  ///////////////////////////// Controller ////////////////////////////

  ///////////////////////////// Controller ////////////////////////////

  /////////////////////////////   Normal  /////////////////////////////
  logic normal_ena_0, normal_ena_1;
  logic normal_page;
  logic [7:0] normal_addr;

  logic [7:0] normal_idx;
  logic [15:0] normal_value_0, normal_value_1;

  assign normal_ena_0 = (select == BRAM_SELECT_NORMAL) & en & (normal_page == 1'b0);
  assign normal_ena_1 = (select == BRAM_SELECT_NORMAL) & en & (normal_page == 1'b1);
  assign normal_page = addr[8];
  assign normal_addr = addr[7:0];
  assign normal_idx = NORMAL_BUS.ADDR;
  assign NORMAL_BUS.VALUE = (NORMAL_BUS.SEGMENT == 1'b0) ? normal_value_0 : normal_value_1;

  BRAM_NORMAL normal_bram_0 (
      .clka (bus_clk),
      .ena  (normal_ena_0),
      .wea  (we),
      .addra(normal_addr),
      .dina (data_in),
      .douta(),
      .clkb (CLK),
      .web  ('0),
      .addrb(normal_idx),
      .dinb ('0),
      .doutb(normal_value_0)
  );

  BRAM_NORMAL normal_bram_1 (
      .clka (bus_clk),
      .ena  (normal_ena_1),
      .wea  (we),
      .addra(normal_addr),
      .dina (data_in),
      .douta(),
      .clkb (CLK),
      .web  ('0),
      .addrb(normal_idx),
      .dinb ('0),
      .doutb(normal_value_1)
  );
  /////////////////////////////   Normal  /////////////////////////////

  ///////////////////////////// Modulator /////////////////////////////
  logic mod_ena_0, mod_ena_1;

  logic [14:0] mod_idx;
  logic [7:0] mod_value_0, mod_value_1;

  logic mod_mem_wr_segment;

  assign mod_ena_0 = (select == BRAM_SELECT_MOD) & en & (mod_mem_wr_segment == 1'b0);
  assign mod_ena_1 = (select == BRAM_SELECT_MOD) & en & (mod_mem_wr_segment == 1'b1);
  assign mod_idx = MOD_BUS.IDX;
  assign MOD_BUS.VALUE = (MOD_BUS.SEGMENT == 1'b0) ? mod_value_0 : mod_value_1;

  BRAM_MOD mod_bram_0 (
      .clka (bus_clk),
      .ena  (mod_ena_0),
      .wea  (we),
      .addra(addr),
      .dina (data_in),
      .douta(),
      .clkb (CLK),
      .web  ('0),
      .addrb(mod_idx),
      .dinb ('0),
      .doutb(mod_value_0)
  );

  BRAM_MOD mod_bram_1 (
      .clka (bus_clk),
      .ena  (mod_ena_1),
      .wea  (we),
      .addra(addr),
      .dina (data_in),
      .douta(),
      .clkb (CLK),
      .web  ('0),
      .addrb(mod_idx),
      .dinb ('0),
      .doutb(mod_value_1)
  );
  ///////////////////////////// Modulator /////////////////////////////

  /////////////////////////////    STM   /////////////////////////////
  logic stm_ena_0, stm_ena_1;
  logic [17:0] stm_addr;

  logic [15:0] stm_idx;
  logic [63:0] stm_value_0, stm_value_1;

  logic stm_mem_wr_segment;
  logic [3:0] stm_mem_wr_page;

  assign stm_ena_0 = (select == BRAM_SELECT_STM) & en & (stm_mem_wr_segment == 1'b0);
  assign stm_ena_1 = (select == BRAM_SELECT_STM) & en & (stm_mem_wr_segment == 1'b1);
  assign stm_addr = {stm_mem_wr_page, addr};
  assign stm_idx = STM_BUS.ADDR;
  assign STM_BUS.VALUE = (STM_BUS.SEGMENT == 1'b0) ? stm_value_0 : stm_value_1;

  BRAM_STM stm_bram_0 (
      .clka (bus_clk),
      .ena  (stm_ena_0),
      .wea  (we),
      .addra(stm_addr),
      .dina (data_in),
      .douta(),
      .clkb (CLK),
      .web  ('0),
      .addrb(stm_idx),
      .dinb ('0),
      .doutb(stm_value_0)
  );

  BRAM_STM stm_bram_1 (
      .clka (bus_clk),
      .ena  (stm_ena_1),
      .wea  (we),
      .addra(stm_addr),
      .dina (data_in),
      .douta(),
      .clkb (CLK),
      .web  ('0),
      .addrb(stm_idx),
      .dinb ('0),
      .doutb(stm_value_1)
  );
  /////////////////////////////    STM   /////////////////////////////

  logic [2:0] ctl_we_edge = 3'b000;
  always_ff @(posedge bus_clk) begin
    ctl_we_edge <= {ctl_we_edge[1:0], we & (select == BRAM_SELECT_CONTROLLER) & en};
    if (ctl_we_edge == 3'b011) begin
      case (addr)
        ADDR_MOD_MEM_WR_SEGMENT: mod_mem_wr_segment <= data_in[0];
        ADDR_STM_MEM_WR_SEGMENT: stm_mem_wr_segment <= data_in[0];
        ADDR_STM_MEM_WR_PAGE: stm_mem_wr_page <= data_in[3:0];
        default: begin
        end
      endcase
    end
  end

endmodule
