`timescale 1ns / 1ps
module clock (
    input wire MRCC_25P6M,
`ifdef DYNAMIC_FREQ
    clock_bus_if.out_port CLOCK_BUS,
`else
    input wire RESET,
`endif
    output wire CLK,
    output wire LOCKED
);

  wire reset_high;
  wire clk_out1_clk_wiz;
  wire clk_in1_clk_wiz;


`ifdef DYNAMIC_FREQ
  logic [ 6:0] daddr;
  logic        drdy;
  logic        dwe;
  logic [15:0] din;
  logic [15:0] dout;
  logic        den;
  logic        dclk;
  logic        reset;

  logic [38:0] rom   [32];

  clock_rom clock_rom (
      .CLK(MRCC_25P6M),
      .CLOCK_BUS(CLOCK_BUS),
      .ROM(rom),
      .UPDATE(update)
  );

  clock_drp clock_drp (
      .CLK(MRCC_25P6M),
      .LOCKED(LOCKED),
      .ROM(rom),
      .UPDATE(update),
      .DADDR(daddr),
      .DRDY(drdy),
      .DWE(dwe),
      .DIN(din),
      .DOUT(dout),
      .DEN(den),
      .DCLK(dclk),
      .RESET(reset)
  );

  assign clk_in1_clk_wiz = MRCC_25P6M;
  assign reset_high = reset;
`else
  wire drdy_unused;
  wire [15:0] do_unused;
  IBUF clkin1_ibufg (
      .O(clk_in1_clk_wiz),
      .I(MRCC_25P6M)
  );
  assign reset_high = RESET;
`endif

  wire psdone_unused;
  wire clkfbout_clk_wiz;
  wire clkfboutb_unused;
  wire clkout0b_unused;
  wire clkout1_unused;
  wire clkout1b_unused;
  wire clkout2_unused;
  wire clkout2b_unused;
  wire clkout3_unused;
  wire clkout3b_unused;
  wire clkout4_unused;
  wire clkout5_unused;
  wire clkout6_unused;
  wire clkfbstopped_unused;
  wire clkinstopped_unused;

  MMCME2_ADV #(
      .BANDWIDTH           ("OPTIMIZED"),
      .CLKOUT4_CASCADE     ("FALSE"),
      .COMPENSATION        ("ZHOLD"),
      .STARTUP_WAIT        ("FALSE"),
      .DIVCLK_DIVIDE       (1),
      .CLKFBOUT_MULT_F     (23.500),
      .CLKFBOUT_PHASE      (0.000),
      .CLKFBOUT_USE_FINE_PS("FALSE"),
      .CLKOUT0_DIVIDE_F    (58.750),
      .CLKOUT0_PHASE       (0.000),
      .CLKOUT0_DUTY_CYCLE  (0.5),
      .CLKOUT0_USE_FINE_PS ("FALSE"),
      .CLKIN1_PERIOD       (39.063)
  ) mmcm_adv_inst (
      .CLKFBOUT    (clkfbout_clk_wiz),
      .CLKFBOUTB   (clkfboutb_unused),
      .CLKOUT0     (clk_out1_clk_wiz),
      .CLKOUT0B    (clkout0b_unused),
      .CLKOUT1     (clkout1_unused),
      .CLKOUT1B    (clkout1b_unused),
      .CLKOUT2     (clkout2_unused),
      .CLKOUT2B    (clkout2b_unused),
      .CLKOUT3     (clkout3_unused),
      .CLKOUT3B    (clkout3b_unused),
      .CLKOUT4     (clkout4_unused),
      .CLKOUT5     (clkout5_unused),
      .CLKOUT6     (clkout6_unused),
      .CLKFBIN     (clkfbout_clk_wiz),
      .CLKIN1      (clk_in1_clk_wiz),
      .CLKIN2      (1'b0),
      .CLKINSEL    (1'b1),
`ifdef DYNAMIC_FREQ
      .DADDR       (daddr),
      .DCLK        (dclk),
      .DEN         (den),
      .DI          (din),
      .DO          (dout),
      .DRDY        (drdy),
      .DWE         (dwe),
`else
      .DADDR       (7'h0),
      .DCLK        (1'b0),
      .DEN         (1'b0),
      .DI          (16'h0),
      .DO          (do_unused),
      .DRDY        (drdy_unused),
      .DWE         (1'b0),
`endif
      .PSCLK       (1'b0),
      .PSEN        (1'b0),
      .PSINCDEC    (1'b0),
      .PSDONE      (psdone_unused),
      .LOCKED      (LOCKED),
      .CLKINSTOPPED(clkinstopped_unused),
      .CLKFBSTOPPED(clkfbstopped_unused),
      .PWRDWN      (1'b0),
      .RST         (reset_high)
  );

  BUFG clkout1_buf (
      .O(CLK),
      .I(clk_out1_clk_wiz)
  );

endmodule
