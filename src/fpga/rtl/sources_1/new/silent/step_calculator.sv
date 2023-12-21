/*
 * File: step_calculator.sv
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

module step_calculator #(
    parameter int DEPTH = 249
) (
    input var CLK,
    input var DIN_VALID,
    input var [15:0] UPDATE_RATE_INTENSITY_FIXED,
    input var [15:0] UPDATE_RATE_PHASE_FIXED,
    input var [15:0] COMPLETION_STEPS_INTENSITY_S,
    input var [15:0] COMPLETION_STEPS_PHASE_S,
    input var FIXED_COMPLETION_STEPS_S,
    input var [15:0] INTENSITY_IN,
    input var [7:0] PHASE_IN,
    output var [15:0] INTENSITY_OUT,
    output var [15:0] PHASE_OUT,
    output var [15:0] UPDATE_RATE_INTENSITY,
    output var [15:0] UPDATE_RATE_PHASE,
    output var DOUT_VALID
);

  logic dout_valid;
  logic [15:0] intensity;
  logic [15:0] phase;
  logic [15:0] intensity_buf;
  logic [15:0] phase_buf;

  logic [15:0] update_rate_intensity;
  logic [15:0] update_rate_phase;

  logic [$clog2(DEPTH)-1:0] set_cnt;

  assign INTENSITY_OUT = intensity;
  assign PHASE_OUT = phase;
  assign UPDATE_RATE_INTENSITY = update_rate_intensity;
  assign UPDATE_RATE_PHASE = update_rate_phase;
  assign DOUT_VALID = dout_valid;

  typedef enum logic [1:0] {
    WAITING,
    RUN_FIXED,
    RUN_VARIABLE
  } state_t;

  state_t state = WAITING;

  always_ff @(posedge CLK) begin
    case (state)
      WAITING: begin
        dout_valid <= 1'b0;
        if (DIN_VALID) begin
          set_cnt <= 0;

          state   <= FIXED_COMPLETION_STEPS_S ? RUN_VARIABLE : RUN_FIXED;
        end
      end
      RUN_FIXED: begin
        dout_valid <= 1'b1;
        intensity <= intensity_buf;
        phase <= {phase_buf, 8'h00};
        update_rate_intensity <= UPDATE_RATE_INTENSITY_FIXED;
        update_rate_phase <= UPDATE_RATE_PHASE_FIXED;
        set_cnt <= set_cnt + 1;
        if (set_cnt == DEPTH - 1) begin
          state <= WAITING;
        end
      end
      RUN_VARIABLE: begin
      end
      default: begin
        state <= WAITING;
      end
    endcase
  end

  always_ff @(posedge CLK) begin
    intensity_buf <= INTENSITY_IN;
    phase_buf <= PHASE_IN;
  end

endmodule
