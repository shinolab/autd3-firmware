module silencer #(
    parameter int DEPTH = 249
) (
    input var CLK,
    input var DIN_VALID,
    input settings::silencer_settings_t SILENCER_SETTINGS,
    input var [15:0] INTENSITY_IN,
    input var [7:0] PHASE_IN,
    output var [15:0] INTENSITY_OUT,
    output var [7:0] PHASE_OUT,
    output var DOUT_VALID
);

  logic [15:0] update_rate_intensity;
  logic [15:0] update_rate_phase;

  logic [15:0] var_update_rate_intensity;
  logic [15:0] var_update_rate_phase;
  logic [15:0] intensity;
  logic [15:0] phase;
  logic dout_valid;

  assign update_rate_intensity = SILENCER_SETTINGS.MODE == params::SILENCER_MODE_FIXED_UPDATE_RATE ?  SILENCER_SETTINGS.UPDATE_RATE_INTENSITY : var_update_rate_intensity;
  assign update_rate_phase = SILENCER_SETTINGS.MODE == params::SILENCER_MODE_FIXED_UPDATE_RATE ?  SILENCER_SETTINGS.UPDATE_RATE_PHASE : var_update_rate_phase;

  step_calculator #(
      .DEPTH(DEPTH)
  ) step_calculator (
      .CLK(CLK),
      .DIN_VALID(DIN_VALID),
      .COMPLETION_STEPS_INTENSITY(SILENCER_SETTINGS.COMPLETION_STEPS_INTENSITY),
      .COMPLETION_STEPS_PHASE(SILENCER_SETTINGS.COMPLETION_STEPS_PHASE),
      .INTENSITY_IN(INTENSITY_IN),
      .PHASE_IN(PHASE_IN),
      .INTENSITY_OUT(intensity),
      .PHASE_OUT(phase),
      .UPDATE_RATE_INTENSITY(var_update_rate_intensity),
      .UPDATE_RATE_PHASE(var_update_rate_phase),
      .DOUT_VALID(dout_valid)
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
