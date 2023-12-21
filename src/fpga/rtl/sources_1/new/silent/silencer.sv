/*
 * File: silencer.sv
 * Project: silent
 * Created Date: 21/12/2023
 * Author: Shun Suzuki
 * -----
 * Last Modified: 21/12/2023
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2023 Shun Suzuki. All rights reserved.
 *
 */

module silencer #(
    parameter int DEPTH = 249
) (
    input var CLK,
    input var DIN_VALID,
    input var [15:0] UPDATE_RATE_INTENSITY,
    input var [15:0] UPDATE_RATE_PHASE,
    input var [15:0] COMPLETION_STEPS_INTENSITY_S,
    input var [15:0] COMPLETION_STEPS_PHASE_S,
    input var FIXED_COMPLETION_STEPS_S,
    input var [15:0] INTENSITY_IN,
    input var [7:0] PHASE_IN,
    output var [15:0] INTENSITY_OUT,
    output var [7:0] PHASE_OUT,
    output var DOUT_VALID
);

  logic [15:0] update_rate_intensity;
  logic [15:0] update_rate_phase;

  logic [15:0] intensity;
  logic [15:0] phase;
  logic dout_valid;

  step_calculator #(
      .DEPTH(DEPTH)
  ) step_calculator (
      .CLK(CLK),
      .DIN_VALID(DIN_VALID),
      .UPDATE_RATE_INTENSITY_FIXED(UPDATE_RATE_INTENSITY),
      .UPDATE_RATE_PHASE_FIXED(UPDATE_RATE_PHASE),
      .COMPLETION_STEPS_INTENSITY_S(COMPLETION_STEPS_INTENSITY_S),
      .COMPLETION_STEPS_PHASE_S(COMPLETION_STEPS_PHASE_S),
      .FIXED_COMPLETION_STEPS_S(FIXED_COMPLETION_STEPS_S),
      .INTENSITY_IN(INTENSITY_IN),
      .PHASE_IN(PHASE_IN),
      .INTENSITY_OUT(intensity),
      .PHASE_OUT(phase),
      .UPDATE_RATE_INTENSITY(update_rate_intensity),
      .UPDATE_RATE_PHASE(update_rate_phase),
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
