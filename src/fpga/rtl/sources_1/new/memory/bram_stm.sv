`timescale 1ns / 1ps
module bram_stm (
    input var clka,
    input var ena,
    input var wea,
    input var [17:0] addra,
    input var [15:0] dina,
    input var clkb,
    input var [15:0] addrb,
    output var [63:0] doutb
);

  blk_mem_gen_v8_4_7 #(
      .C_FAMILY("artix7"),
      .C_XDEVICEFAMILY("artix7"),
      .C_ELABORATION_DIR("./"),
      .C_INTERFACE_TYPE(0),
      .C_AXI_TYPE(1),
      .C_AXI_SLAVE_TYPE(0),
      .C_USE_BRAM_BLOCK(0),
      .C_ENABLE_32BIT_ADDRESS(0),
      .C_CTRL_ECC_ALGO("NONE"),
      .C_HAS_AXI_ID(0),
      .C_AXI_ID_WIDTH(4),
      .C_MEM_TYPE(2),
      .C_BYTE_SIZE(9),
      .C_ALGORITHM(1),
      .C_PRIM_TYPE(1),
      .C_LOAD_INIT_FILE(0),
      .C_INIT_FILE_NAME("no_coe_file_loaded"),
      .C_INIT_FILE("BRAM_STM.mem"),
      .C_USE_DEFAULT_DATA(1),
      .C_DEFAULT_DATA("0"),
      .C_HAS_RSTA(0),
      .C_RST_PRIORITY_A("CE"),
      .C_RSTRAM_A(0),
      .C_INITA_VAL("0"),
      .C_HAS_ENA(1),
      .C_HAS_REGCEA(0),
      .C_USE_BYTE_WEA(0),
      .C_WEA_WIDTH(1),
      .C_WRITE_MODE_A("WRITE_FIRST"),
      .C_WRITE_WIDTH_A(16),
      .C_READ_WIDTH_A(16),
      .C_WRITE_DEPTH_A(params::GAIN_STM_SIZE * 256),
      .C_READ_DEPTH_A(params::GAIN_STM_SIZE * 256),
      .C_ADDRA_WIDTH(params::STM_WR_ADDR_WIDTH),
      .C_HAS_RSTB(0),
      .C_RST_PRIORITY_B("CE"),
      .C_RSTRAM_B(0),
      .C_INITB_VAL("0"),
      .C_HAS_ENB(0),
      .C_HAS_REGCEB(0),
      .C_USE_BYTE_WEB(0),
      .C_WEB_WIDTH(1),
      .C_WRITE_MODE_B("WRITE_FIRST"),
      .C_WRITE_WIDTH_B(64),
      .C_READ_WIDTH_B(64),
      .C_WRITE_DEPTH_B(params::GAIN_STM_SIZE * 64),
      .C_READ_DEPTH_B(params::GAIN_STM_SIZE * 64),
      .C_ADDRB_WIDTH(params::STM_RD_ADDR_WIDTH),
      .C_HAS_MEM_OUTPUT_REGS_A(0),
      .C_HAS_MEM_OUTPUT_REGS_B(1),
      .C_HAS_MUX_OUTPUT_REGS_A(0),
      .C_HAS_MUX_OUTPUT_REGS_B(0),
      .C_MUX_PIPELINE_STAGES(0),
      .C_HAS_SOFTECC_INPUT_REGS_A(0),
      .C_HAS_SOFTECC_OUTPUT_REGS_B(0),
      .C_USE_SOFTECC(0),
      .C_USE_ECC(0),
      .C_EN_ECC_PIPE(0),
      .C_READ_LATENCY_A(1),
      .C_READ_LATENCY_B(1),
      .C_HAS_INJECTERR(0),
      .C_SIM_COLLISION_CHECK("ALL"),
      .C_COMMON_CLK(0),
      .C_DISABLE_WARN_BHV_COLL(0),
      .C_EN_SLEEP_PIN(0),
      .C_USE_URAM(0),
      .C_EN_RDADDRA_CHG(0),
      .C_EN_RDADDRB_CHG(0),
      .C_EN_DEEPSLEEP_PIN(0),
      .C_EN_SHUTDOWN_PIN(0),
      .C_EN_SAFETY_CKT(0),
      .C_DISABLE_WARN_BHV_RANGE(0),
      .C_COUNT_36K_BRAM("120"),
      .C_COUNT_18K_BRAM("0"),
      .C_EST_POWER_SUMMARY("Estimated Power for IP     :     39.654608 mW")
  ) bram_mem (
      .clka(clka),
      .rsta(0),
      .ena(ena),
      .regcea(0),
      .wea(wea),
      .addra(addra),
      .dina(dina),
      .douta(douta),
      .clkb(clkb),
      .rstb(0),
      .enb(0),
      .regceb(0),
      .web(web),
      .addrb(addrb),
      .dinb(dinb),
      .doutb(doutb),
      .injectsbiterr(0),
      .injectdbiterr(0),
      .eccpipece(0),
      .sleep(0),
      .deepsleep(0),
      .shutdown(0),
      .s_aclk(0),
      .s_aresetn(0),
      .s_axi_awid(),
      .s_axi_awaddr(),
      .s_axi_awlen(),
      .s_axi_awsize(),
      .s_axi_awburst(),
      .s_axi_awvalid(0),
      .s_axi_wdata(),
      .s_axi_wstrb(),
      .s_axi_wlast(0),
      .s_axi_wvalid(0),
      .s_axi_bready(0),
      .s_axi_arid(),
      .s_axi_araddr(),
      .s_axi_arlen(),
      .s_axi_arsize(),
      .s_axi_arburst(),
      .s_axi_arvalid(0),
      .s_axi_rready(0),
      .s_axi_injectsbiterr(0),
      .s_axi_injectdbiterr(0)
  );

endmodule
