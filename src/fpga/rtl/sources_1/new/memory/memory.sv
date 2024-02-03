module memory (
    input var CLK,
    memory_bus_if.bram_port MEM_BUS,
    cnt_bus_if.in_port CNT_BUS_IF,
    modulation_delay_bus_if.in_port MOD_DELAY_BUS,
    modulation_bus_if.in_port MOD_BUS,
    normal_bus_if.in_port NORMAL_BUS,
    stm_bus_if.in_port STM_BUS,
    duty_table_bus_if.in_port DUTY_TABLE_BUS
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
  logic ctl_en;
  logic duty_table_sel;
  logic [4:0] cnt_sel;

  assign ctl_en = en & (select == BRAM_SELECT_CONTROLLER);
  assign duty_table_sel = addr[13];
  assign cnt_sel = addr[12:8];

  /////////////////////   Main   ///////////////////////
  logic ctl_main_en;

  assign ctl_main_en = ctl_en & (duty_table_sel == 1'b0) & (cnt_sel == BRAM_SELECT_CNT_CNT);

  BRAM_CONTROLLER ctl_bram (
      .clka (bus_clk),
      .ena  (ctl_main_en),
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
  /////////////////////   Main   ///////////////////////

  ///////////////////// Mod delay ///////////////////////
  logic dly_en;

  logic [7:0] dly_idx;
  logic [15:0] dly_dout;

  assign dly_en = ctl_en & (duty_table_sel == 1'b0) & (cnt_sel == BRAM_SELECT_CNT_MOD_DELAY);
  assign dly_idx = MOD_DELAY_BUS.IDX;
  assign MOD_DELAY_BUS.VALUE = dly_dout;

  BRAM_DELAY dly_bram (
      .clka (bus_clk),
      .ena  (dly_en),
      .wea  (we),
      .addra(addr[7:0]),
      .dina (data_in),
      .douta(),
      .clkb (CLK),
      .web  (1'b0),
      .addrb(dly_idx),
      .dinb (),
      .doutb(dly_dout)
  );
  ///////////////////// Mod delay ///////////////////////

  //////////////////// Duty table ///////////////////////
  logic duty_table_en;
  logic [1:0] duty_table_wr_page;

  logic [15:0] duty_table_idx;
  logic [7:0] duty_table_dout;

  assign duty_table_en = ctl_en & (duty_table_sel == 1'b1);
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
      .addrb({duty_table_wr_page, addr[12:0]}),
      .dinb (data_in),
      .doutb()
  );
  //////////////////// Duty table ///////////////////////

  ///////////////////////////// Controller ////////////////////////////

  /////////////////////////////   Normal  /////////////////////////////
  logic normal_en_0, normal_en_1;
  logic normal_page;

  logic [7:0] normal_idx;
  logic [15:0] normal_value_0, normal_value_1;

  assign normal_en_0 = (select == BRAM_SELECT_NORMAL) & en & (normal_page == 1'b0);
  assign normal_en_1 = (select == BRAM_SELECT_NORMAL) & en & (normal_page == 1'b1);
  assign normal_page = addr[8];
  assign normal_idx = NORMAL_BUS.ADDR;
  assign NORMAL_BUS.VALUE = (NORMAL_BUS.SEGMENT == 1'b0) ? normal_value_0 : normal_value_1;

  BRAM_NORMAL normal_bram_0 (
      .clka (bus_clk),
      .ena  (normal_en_0),
      .wea  (we),
      .addra(addr[7:0]),
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
      .ena  (normal_en_1),
      .wea  (we),
      .addra(addr[7:0]),
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
  logic mod_en_0, mod_en_1;

  logic [14:0] mod_idx;
  logic [7:0] mod_value_0, mod_value_1;

  logic mod_mem_wr_segment;

  assign mod_en_0 = (select == BRAM_SELECT_MOD) & en & (mod_mem_wr_segment == 1'b0);
  assign mod_en_1 = (select == BRAM_SELECT_MOD) & en & (mod_mem_wr_segment == 1'b1);
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

  assign stm_en_0 = (select == BRAM_SELECT_STM) & en & (stm_mem_wr_segment == 1'b0);
  assign stm_en_1 = (select == BRAM_SELECT_STM) & en & (stm_mem_wr_segment == 1'b1);
  assign stm_idx = STM_BUS.ADDR;
  assign STM_BUS.VALUE = (STM_BUS.SEGMENT == 1'b0) ? stm_value_0 : stm_value_1;

  BRAM_STM stm_bram_0 (
      .clka (bus_clk),
      .ena  (stm_en_0),
      .wea  (we),
      .addra({stm_mem_wr_page, addr}),
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
      .ena  (stm_en_1),
      .wea  (we),
      .addra({stm_mem_wr_page, addr}),
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
    ctl_we_edge <= {ctl_we_edge[1:0], we & ctl_main_en};
    if (ctl_we_edge == 3'b011) begin
      case (addr)
        ADDR_MOD_MEM_WR_SEGMENT: mod_mem_wr_segment <= data_in[0];
        ADDR_STM_MEM_WR_SEGMENT: stm_mem_wr_segment <= data_in[0];
        ADDR_STM_MEM_WR_PAGE: stm_mem_wr_page <= data_in[3:0];
        ADDR_DUTY_TABLE_WR_PAGE: duty_table_wr_page <= data_in[1:0];
        default: begin
        end
      endcase
    end
  end

`ifndef ASSERTION_OFF
  logic [8:0] enables = {
    ctl_main_en,
    dly_en,
    duty_table_en,
    normal_en_0,
    normal_en_1,
    mod_en_0,
    mod_en_1,
    stm_en_0,
    stm_en_1
  };

  always_ff @(posedge CLK) begin
    enable_bit :
    assume ($countones(enables) === 0 | $countones(enables) === 1)
    else begin
      $error("multiple enabled bram: %b", enables);
      $finish();
    end
  end
`endif

endmodule
