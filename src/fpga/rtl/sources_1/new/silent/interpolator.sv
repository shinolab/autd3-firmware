`timescale 1ns / 1ps
module interpolator #(
    parameter int DEPTH = 249
) (
    input var CLK,
    input var DIN_VALID,
    input var [15:0] UPDATE_RATE_INTENSITY,
    input var [15:0] UPDATE_RATE_PHASE,
    input var [15:0] INTENSITY_IN,
    input var [7:0] PHASE_IN,
    output var [15:0] INTENSITY_OUT,
    output var [7:0] PHASE_OUT,
    output var DOUT_VALID
);

  logic [15:0] intensity_out;
  logic dout_valid_intensity, dout_valid_phase;

  assign DOUT_VALID = dout_valid_phase;

  interpolator_intensity #(
      .DEPTH(DEPTH)
  ) interpolator_intensity (
      .CLK(CLK),
      .DIN_VALID(DIN_VALID),
      .UPDATE_RATE(UPDATE_RATE_INTENSITY),
      .INTENSITY_IN(INTENSITY_IN),
      .INTENSITY_OUT(intensity_out),
      .DOUT_VALID(dout_valid_intensity)
  );

  delay_fifo #(
      .WIDTH(16),
      .DEPTH(3)
  ) fifo_intensity (
      .CLK (CLK),
      .DIN (intensity_out),
      .DOUT(INTENSITY_OUT)
  );

  interpolator_phase #(
      .DEPTH(DEPTH)
  ) interpolator_phase (
      .CLK(CLK),
      .DIN_VALID(DIN_VALID),
      .UPDATE_RATE(UPDATE_RATE_PHASE),
      .PHASE_IN(PHASE_IN),
      .PHASE_OUT(PHASE_OUT),
      .DOUT_VALID(dout_valid_phase)
  );

endmodule
