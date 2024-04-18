`timescale 1ns / 1ps
module ultrasound_cnt_clk_gen (
    input  wire clk_in1,
    input  wire reset,
    output wire clk_out,
    output wire locked
);

  logic CLKOUT;
  logic CLKFB, CLKFB_BUF;
  BUFG clkf_buf (
      .O(CLKFB_BUF),
      .I(CLKFB)
  );
  BUFG clkout_buf (
      .O(clk_out),
      .I(CLKOUT)
  );

  MMCME2_ADV #(
      .BANDWIDTH           ("OPTIMIZED"),
      .CLKOUT4_CASCADE     ("FALSE"),
      .COMPENSATION        ("ZHOLD"),
      .STARTUP_WAIT        ("FALSE"),
      .DIVCLK_DIVIDE       (1),
      .CLKFBOUT_MULT_F     (23.500),
      .CLKFBOUT_PHASE      (0.000),
      .CLKFBOUT_USE_FINE_PS("FALSE"),
      .CLKOUT0_DIVIDE_F    (29.375),
      .CLKOUT0_PHASE       (0.000),
      .CLKOUT0_DUTY_CYCLE  (0.500),
      .CLKOUT0_USE_FINE_PS ("FALSE"),
      .CLKIN1_PERIOD       (39.062)
  ) MMCME2_ADV_inst (
      .CLKOUT0(CLKOUT),
      .CLKOUT0B(),
      .CLKOUT1(),
      .CLKOUT1B(),
      .CLKFBOUT(CLKFB),
      .CLKFBOUTB(),
      .CLKFBSTOPPED(),
      .CLKINSTOPPED(),
      .LOCKED(locked),
      .CLKIN1(clk_in1),
      .CLKINSEL(1'b1),
      .PWRDWN(1'b0),
      .RST(reset),
      .CLKFBIN(CLKFB_BUF),
      .CLKOUT2(),
      .CLKOUT2B(),
      .CLKOUT3(),
      .CLKOUT3B(),
      .CLKOUT4(),
      .CLKOUT5(),
      .CLKOUT6(),
      .DO(),
      .DRDY(),
      .PSDONE(),
      .CLKIN2(),
      .DADDR(),
      .DCLK(),
      .DEN(),
      .DI(),
      .DWE(),
      .PSCLK(),
      .PSEN(),
      .PSINCDEC()
  );

endmodule
