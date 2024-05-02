`timescale 1ns / 1ps
module clock (
    input wire MRCC_25P6M,
    clock_bus_if.out_port CLOCK_BUS,
    output wire CLK,
    output wire LOCKED
);

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

  clk_wiz clk_wiz (
      .daddr(daddr),
      .drdy(drdy),
      .dwe(dwe),
      .din(din),
      .dout(dout),
      .den(den),
      .reset(reset),
      .clk_in1(MRCC_25P6M),
      .dclk(dclk),
      .clk_out1(CLK),
      .locked(LOCKED)
  );

endmodule
