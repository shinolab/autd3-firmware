`timescale 1ns / 1ps
module silencer #(
    parameter int DEPTH = 249
) (
    input var CLK,
    input var DIN_VALID,
    input settings::silencer_settings_t SILENCER_SETTINGS,
    input var [7:0] INTENSITY_IN,
    input var [7:0] PHASE_IN,
    output var [7:0] INTENSITY_OUT,
    output var [7:0] PHASE_OUT,
    output var DOUT_VALID
);

  localparam int StepCalcLatency = 18 + 3;

  logic is_fixed_update_rate;

  logic [15:0] update_rate_intensity, update_rate_phase;
  logic [15:0] var_update_rate_intensity, var_update_rate_phase;
  logic dout_valid;

  logic [7:0] intensity;
  logic [7:0] phase;

  assign is_fixed_update_rate = SILENCER_SETTINGS.FLAG[params::SILENCER_FLAG_BIT_FIXED_UPDATE_RATE_MODE];

  assign update_rate_intensity = is_fixed_update_rate ?  SILENCER_SETTINGS.UPDATE_RATE_INTENSITY : var_update_rate_intensity;
  assign update_rate_phase = is_fixed_update_rate ?  SILENCER_SETTINGS.UPDATE_RATE_PHASE : var_update_rate_phase;

  step_calculator #(
      .DEPTH(DEPTH)
  ) step_calculator (
      .CLK(CLK),
      .DIN_VALID(DIN_VALID),
      .COMPLETION_STEPS_INTENSITY(SILENCER_SETTINGS.COMPLETION_STEPS_INTENSITY),
      .COMPLETION_STEPS_PHASE(SILENCER_SETTINGS.COMPLETION_STEPS_PHASE),
      .INTENSITY(INTENSITY_IN),
      .PHASE(PHASE_IN),
      .UPDATE_RATE_INTENSITY(var_update_rate_intensity),
      .UPDATE_RATE_PHASE(var_update_rate_phase),
      .DOUT_VALID(dout_valid)
  );

  delay_fifo #(
      .WIDTH(8),
      .DEPTH(StepCalcLatency)
  ) fifo_intensity (
      .CLK (CLK),
      .DIN (INTENSITY_IN),
      .DOUT(intensity)
  );

  delay_fifo #(
      .WIDTH(8),
      .DEPTH(StepCalcLatency)
  ) fifo_phase (
      .CLK (CLK),
      .DIN (PHASE_IN),
      .DOUT(phase)
  );

  interpolator #(
      .DEPTH(DEPTH)
  ) interpolator (
      .CLK(CLK),
      .DIN_VALID(dout_valid),
      .UPDATE_RATE_INTENSITY(update_rate_intensity),
      .UPDATE_RATE_PHASE(update_rate_phase),
      .INTENSITY_IN(intensity),
      .PHASE_IN(phase),
      .INTENSITY_OUT(INTENSITY_OUT),
      .PHASE_OUT(PHASE_OUT),
      .DOUT_VALID(DOUT_VALID)
  );

endmodule
