`timescale 1ns / 1ps
module memory (
    input wire CLK,
    input wire MRCC_25P6M,
    memory_bus_if.bram_port MEM_BUS,
    cnt_bus_if.in_port CNT_BUS,
    phase_corr_bus_if.in_port PHASE_CORR_BUS,
    output_mask_bus_if.in_port OUTPUT_MASK_BUS,
    modulation_bus_if.in_port MOD_BUS,
    stm_bus_if.in_port STM_BUS,
    pwe_table_bus_if.in_port PWE_TABLE_BUS
);

  import params::*;

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

  assign ctl_en = (cnt_sel == BRAM_CNT_SELECT_MAIN) & (select == BRAM_SELECT_CONTROLLER) & en;

  BRAM_CONTROLLER ctl_bram (
      .clka (bus_clk),
      .ena  (ctl_en),
      .wea  (we),
      .addra(addr[7:0]),
      .dina (data_in),
      .douta(data_out),
      .clkb (CLK),
      .web  (CNT_BUS.WE),
      .addrb(CNT_BUS.ADDR),
      .dinb (CNT_BUS.DIN),
      .doutb(CNT_BUS.DOUT)
  );
  ///////////////////////////// Controller ////////////////////////////

  ///////////////////////// Phase correction //////////////////////////
  logic phase_corr_en;

  logic [7:0] phase_corr_idx;
  logic [7:0] phase_corr_dout;

  assign phase_corr_en = (cnt_sel == BRAM_CNT_SELECT_PHASE_CORR) & (select == BRAM_SELECT_CONTROLLER) & en;
  assign phase_corr_idx = PHASE_CORR_BUS.IDX;
  assign PHASE_CORR_BUS.VALUE = phase_corr_dout;

  BRAM_PHASE_CORR phase_corr_bram (
      .clka (bus_clk),
      .ena  (phase_corr_en),
      .wea  (we),
      .addra(addr[6:0]),
      .dina (data_in),
      .douta(),
      .clkb (CLK),
      .web  (1'b0),
      .addrb(phase_corr_idx),
      .dinb (),
      .doutb(phase_corr_dout)
  );
  ///////////////////////// Phase correction //////////////////////////

  //////////////////////////// Output mask ////////////////////////////
  logic output_mask_en;

  logic output_mask_idx;
  logic [255:0] output_mask_dout;

  assign output_mask_en = (cnt_sel == BRAM_CNT_SELECT_OUTPUT_MASK) & (select == BRAM_SELECT_CONTROLLER) & en;
  assign output_mask_idx = OUTPUT_MASK_BUS.SEGMENT;
  assign OUTPUT_MASK_BUS.VALUE = output_mask_dout;
  BRAM_OUTPUT_MASK output_mask_bram (
      .clka (bus_clk),
      .ena  (output_mask_en),
      .wea  (we),
      .addra({addr[4:0]}),
      .dina (data_in),
      .douta(),
      .clkb (CLK),
      .web  (1'b0),
      .addrb(output_mask_idx),
      .dinb (),
      .doutb(output_mask_dout)
  );
  //////////////////////////// Output mask ////////////////////////////

  ///////////////////////////// PWE table ////////////////////////////
  logic pwe_table_en;

  logic [7:0] pwe_table_idx;
  logic [15:0] pwe_table_dout;

  assign pwe_table_en = (select == BRAM_SELECT_PWE_TABLE) & en;
  assign pwe_table_idx = PWE_TABLE_BUS.IDX;
  assign PWE_TABLE_BUS.VALUE = pwe_table_dout[8:0];

  BRAM_PWE_TABLE pwe_table_bram (
      .clka (bus_clk),
      .ena  (pwe_table_en),
      .wea  (we),
      .addra(addr[7:0]),
      .dina (data_in),
      .douta(),
      .clkb (CLK),
      .web  (1'b0),
      .addrb(pwe_table_idx),
      .dinb (),
      .doutb(pwe_table_dout)
  );
  ///////////////////////////// PWE table ////////////////////////////

  ///////////////////////////// Modulator /////////////////////////////
  logic mod_en[NumSegment];

  logic [15:0] mod_idx;
  logic [7:0] mod_value[NumSegment];

  logic mod_mem_wr_segment;
  logic mod_mem_wr_page;

  assign mod_idx = MOD_BUS.IDX;
  assign MOD_BUS.VALUE = mod_value[MOD_BUS.SEGMENT];
  for (genvar i = 0; i < NumSegment; i++) begin : gen_mod_bram
    assign mod_en[i] = (select == BRAM_SELECT_MOD) & en & (mod_mem_wr_segment == i);
    BRAM_MOD mod_bram (
        .clka (bus_clk),
        .ena  (mod_en[i]),
        .wea  (we),
        .addra({mod_mem_wr_page, addr}),
        .dina (data_in),
        .douta(),
        .clkb (CLK),
        .web  ('0),
        .addrb(mod_idx),
        .dinb ('0),
        .doutb(mod_value[i])
    );
  end
  ///////////////////////////// Modulator /////////////////////////////

  /////////////////////////////    STM   /////////////////////////////
  logic stm_en[NumSegment];

  logic [15:0] stm_idx;
  logic [63:0] stm_value[NumSegment];

  logic stm_mem_wr_segment;
  logic [3:0] stm_mem_wr_page;

  assign stm_idx = STM_BUS.ADDR;
  assign STM_BUS.VALUE = stm_value[STM_BUS.SEGMENT];
  for (genvar i = 0; i < NumSegment; i++) begin : gen_stm_bram
    assign stm_en[i] = (select == BRAM_SELECT_STM) & en & (stm_mem_wr_segment == i);
    bram_stm stm_bram (
        .clka (bus_clk),
        .ena  (stm_en[i]),
        .wea  (we),
        .addra({stm_mem_wr_page, addr}),
        .dina (data_in),
        .clkb (CLK),
        .addrb(stm_idx),
        .doutb(stm_value[i])
    );
  end
  /////////////////////////////    STM   /////////////////////////////

  logic [2:0] ctl_we_edge = 3'b000;
  always_ff @(posedge bus_clk) begin
    ctl_we_edge <= {ctl_we_edge[1:0], we & ctl_en};
    if (ctl_we_edge == 3'b011) begin
      case (addr)
        ADDR_MOD_MEM_WR_SEGMENT: mod_mem_wr_segment <= data_in[0];
        ADDR_MOD_MEM_WR_PAGE: mod_mem_wr_page <= data_in[0];
        ADDR_STM_MEM_WR_SEGMENT: stm_mem_wr_segment <= data_in[0];
        ADDR_STM_MEM_WR_PAGE: stm_mem_wr_page <= data_in[3:0];
        default: begin
        end
      endcase
    end
  end

endmodule
