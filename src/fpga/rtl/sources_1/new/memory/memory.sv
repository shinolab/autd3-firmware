module memory (
    input wire CLK,
    memory_bus_if.bram_port MEM_BUS,
    cnt_bus_if.in_port CNT_BUS_IF,
    modulation_bus_if.in_port MOD_BUS,
    stm_bus_if.in_port STM_BUS,
    duty_table_bus_if.in_port DUTY_TABLE_BUS,
    filter_bus_if.in_port FILTER_BUS
);

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

  logic [5:0] cnt_sel;
  assign cnt_sel = addr[13:8];

  ///////////////////////////// Controller ////////////////////////////
  logic ctl_en;

  assign ctl_en = (cnt_sel == params::BRAM_CNT_SELECT_MAIN) & (select == params::BRAM_SELECT_CONTROLLER) & en;

  BRAM_CONTROLLER ctl_bram (
      .clka (bus_clk),
      .ena  (ctl_en),
      .wea  (we),
      .addra(addr[7:0]),
      .dina (data_in),
      .douta(data_out),
      .clkb (CLK),
      .web  (CNT_BUS_IF.WE),
      .addrb(CNT_BUS_IF.ADDR),
      .dinb (CNT_BUS_IF.DIN),
      .doutb(CNT_BUS_IF.DOUT)
  );
  ///////////////////////////// Controller ////////////////////////////

  /////////////////////////////// Filter //////////////////////////////
  logic filter_en;

  assign filter_en = (cnt_sel == params::BRAM_CNT_SELECT_FILTER) & (select == params::BRAM_SELECT_CONTROLLER) & en;

  BRAM_FILTER filter_bram (
      .clka (bus_clk),
      .ena  (filter_en),
      .wea  (we),
      .addra(addr[6:0]),
      .dina (data_in),
      .douta(),
      .clkb (CLK),
      .web  ('0),
      .addrb(FILTER_BUS.ADDR),
      .dinb ('0),
      .doutb(FILTER_BUS.DOUT)
  );
  /////////////////////////////// Filter //////////////////////////////

  ///////////////////////////// Duty table ////////////////////////////
  logic duty_table_en;
  logic duty_table_wr_page;

  logic [15:0] duty_table_idx;
  logic [7:0] duty_table_dout;

  assign duty_table_en = (select == params::BRAM_SELECT_DUTY_TABLE) & en;
  assign duty_table_idx = DUTY_TABLE_BUS.IDX;
  assign DUTY_TABLE_BUS.VALUE = duty_table_dout;

  BRAM_ASIN duty_table_bram (
      .clka (CLK),
      .wea  (1'b0),
      .addra(duty_table_idx),
      .dina (),
      .douta(duty_table_dout),
      .clkb (bus_clk),
      .enb  (duty_table_en),
      .web  (we),
      .addrb({duty_table_wr_page, addr[13:0]}),
      .dinb (data_in),
      .doutb()
  );
  ///////////////////////////// Duty table ////////////////////////////

  ///////////////////////////// Modulator /////////////////////////////
  logic mod_en_0, mod_en_1;

  logic [14:0] mod_idx;
  logic [7:0] mod_value_0, mod_value_1;

  logic mod_mem_wr_segment;

  assign mod_en_0 = (select == params::BRAM_SELECT_MOD) & en & (mod_mem_wr_segment == 1'b0);
  assign mod_en_1 = (select == params::BRAM_SELECT_MOD) & en & (mod_mem_wr_segment == 1'b1);
  assign mod_idx = MOD_BUS.IDX;
  assign MOD_BUS.VALUE = (MOD_BUS.SEGMENT == 1'b0) ? mod_value_0 : mod_value_1;

  BRAM_MOD mod_bram_0 (
      .clka (bus_clk),
      .ena  (mod_en_0),
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
      .ena  (mod_en_1),
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
  logic stm_en_0, stm_en_1;

  logic [15:0] stm_idx;
  logic [63:0] stm_value_0, stm_value_1;

  logic stm_mem_wr_segment;
  logic [3:0] stm_mem_wr_page;

  assign stm_en_0 = (select == params::BRAM_SELECT_STM) & en & (stm_mem_wr_segment == 1'b0);
  assign stm_en_1 = (select == params::BRAM_SELECT_STM) & en & (stm_mem_wr_segment == 1'b1);
  assign stm_idx = STM_BUS.ADDR;
  assign STM_BUS.VALUE = (STM_BUS.SEGMENT == 1'b0) ? stm_value_0 : stm_value_1;

  bram_stm stm_bram_0 (
      .clka (bus_clk),
      .ena  (stm_en_0),
      .wea  (we),
      .addra({stm_mem_wr_page, addr}),
      .dina (data_in),
      .clkb (CLK),
      .addrb(stm_idx),
      .doutb(stm_value_0)
  );

  bram_stm stm_bram_1 (
      .clka (bus_clk),
      .ena  (stm_en_1),
      .wea  (we),
      .addra({stm_mem_wr_page, addr}),
      .dina (data_in),
      .clkb (CLK),
      .addrb(stm_idx),
      .doutb(stm_value_1)
  );

  /////////////////////////////    STM   /////////////////////////////

  logic [2:0] ctl_we_edge = 3'b000;
  always_ff @(posedge bus_clk) begin
    ctl_we_edge <= {ctl_we_edge[1:0], we & ctl_en};
    if (ctl_we_edge == 3'b011) begin
      case (addr)
        params::ADDR_MOD_MEM_WR_SEGMENT: mod_mem_wr_segment <= data_in[0];
        params::ADDR_STM_MEM_WR_SEGMENT: stm_mem_wr_segment <= data_in[0];
        params::ADDR_STM_MEM_WR_PAGE: stm_mem_wr_page <= data_in[3:0];
        params::ADDR_PULSE_WIDTH_ENCODER_TABLE_WR_PAGE: duty_table_wr_page <= data_in[0];
        default: begin
        end
      endcase
    end
  end

endmodule
