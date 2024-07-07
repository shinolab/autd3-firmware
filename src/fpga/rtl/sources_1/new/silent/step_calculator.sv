`timescale 1ns / 1ps
module step_calculator #(
    parameter int DEPTH = 249
) (
    input var CLK,
    input var DIN_VALID,
    input var [7:0] COMPLETION_STEPS_INTENSITY,
    input var [7:0] COMPLETION_STEPS_PHASE,
    input var [7:0] INTENSITY,
    input var [7:0] PHASE,
    output var [7:0] UPDATE_RATE_INTENSITY,
    output var [7:0] UPDATE_RATE_PHASE,
    output var DOUT_VALID
);

  logic dout_valid_intensity, dout_valid_phase;

  assign DOUT_VALID = dout_valid_intensity & dout_valid_phase;

  step_calculator_phase #(
      .DEPTH(DEPTH)
  ) step_calculator_phase (
      .CLK(CLK),
      .DIN_VALID(DIN_VALID),
      .COMPLETION_STEPS(COMPLETION_STEPS_PHASE),
      .PHASE(PHASE),
      .UPDATE_RATE(UPDATE_RATE_PHASE),
      .DOUT_VALID(dout_valid_phase)
  );

  step_calculator_intensity #(
      .DEPTH(DEPTH)
  ) step_calculator_intensity (
      .CLK(CLK),
      .DIN_VALID(DIN_VALID),
      .COMPLETION_STEPS(COMPLETION_STEPS_INTENSITY),
      .INTENSITY(INTENSITY),
      .UPDATE_RATE(UPDATE_RATE_INTENSITY),
      .DOUT_VALID(dout_valid_intensity)
  );

endmodule
