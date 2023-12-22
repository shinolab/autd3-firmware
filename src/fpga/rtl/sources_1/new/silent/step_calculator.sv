/*
 * File: step_calculator.sv
 * Project: silent
 * Created Date: 21/12/2023
 * Author: Shun Suzuki
 * -----
 * Last Modified: 22/12/2023
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

  localparam int AddSubLatency = 2;
  localparam int DivLatency = 18;

  logic dout_valid;
  logic [15:0] intensity;
  logic [15:0] phase;
  logic [15:0] intensity_buf[AddSubLatency+1+AddSubLatency+1+DivLatency+1];
  logic [7:0] phase_buf[AddSubLatency+1+AddSubLatency+1+DivLatency+1];

  logic [15:0] update_rate_intensity;
  logic [15:0] update_rate_phase;

  logic [$clog2(DEPTH+AddSubLatency+1+AddSubLatency+DivLatency)-1:0] load_cnt;
  logic [$clog2(DEPTH+AddSubLatency+DivLatency)-1:0] target_set_cnt;

  logic [15:0] completion_steps_intensity;
  logic [15:0] completion_steps_phase;
  logic [15:0] current_target_intensity[DEPTH] = '{DEPTH{0}};
  logic [7:0] current_target_phase[DEPTH] = '{DEPTH{0}};
  logic [15:0] diff_intensity_a, diff_intensity_b, diff_intensity;
  logic [15:0] diff_intensity_buf[3];
  logic [7:0] diff_phase_a, diff_phase_b, diff_phase;
  logic [15:0] intensity_step_quo, intensity_step_rem_unused;
  logic [15:0] phase_step_quo, phase_step_rem_unused;
  logic [8:0] phase_fold_a, phase_fold_b, phase_fold_s;

  assign INTENSITY_OUT = intensity;
  assign PHASE_OUT = phase;
  assign UPDATE_RATE_INTENSITY = update_rate_intensity;
  assign UPDATE_RATE_PHASE = update_rate_phase;
  assign DOUT_VALID = dout_valid;

  addsub #(
      .WIDTH(16)
  ) addsub_diff_intensity (
      .CLK(CLK),
      .A  (diff_intensity_a),
      .B  (diff_intensity_b),
      .ADD(1'b0),
      .S  (diff_intensity)
  );

  addsub #(
      .WIDTH(8)
  ) addsub_diff_phase (
      .CLK(CLK),
      .A  (diff_phase_a),
      .B  (diff_phase_b),
      .ADD(1'b0),
      .S  (diff_phase)
  );

  addsub #(
      .WIDTH(9)
  ) addsub_phase_fold (
      .CLK(CLK),
      .A  (phase_fold_a),
      .B  (phase_fold_b),
      .ADD(1'b0),
      .S  (phase_fold_s)
  );

  div_16_16 div_16_16_intensity (
      .s_axis_dividend_tdata(diff_intensity_buf[2]),
      .s_axis_dividend_tvalid(1'b1),
      .s_axis_divisor_tdata(completion_steps_intensity),
      .s_axis_divisor_tvalid(1'b1),
      .aclk(CLK),
      .m_axis_dout_tdata({intensity_step_quo, intensity_step_rem_unused}),
      .m_axis_dout_tvalid()
  );

  div_16_16 div_16_16_phase (
      .s_axis_dividend_tdata({phase_fold_s[7:0], 8'h00}),
      .s_axis_dividend_tvalid(1'b1),
      .s_axis_divisor_tdata(completion_steps_phase),
      .s_axis_divisor_tvalid(1'b1),
      .aclk(CLK),
      .m_axis_dout_tdata({phase_step_quo, phase_step_rem_unused}),
      .m_axis_dout_tvalid()
  );

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
          load_cnt <= 0;
          target_set_cnt <= 0;

          completion_steps_intensity <= COMPLETION_STEPS_INTENSITY_S;
          completion_steps_phase <= COMPLETION_STEPS_PHASE_S;

          state <= FIXED_COMPLETION_STEPS_S ? RUN_VARIABLE : RUN_FIXED;
        end
      end
      RUN_FIXED: begin
        dout_valid <= 1'b1;
        intensity <= intensity_buf[0];
        phase <= {phase_buf[0], 8'h00};
        update_rate_intensity <= UPDATE_RATE_INTENSITY_FIXED;
        update_rate_phase <= UPDATE_RATE_PHASE_FIXED;
        load_cnt <= load_cnt + 1;
        if (load_cnt == DEPTH - 1) begin
          state <= WAITING;
        end
      end
      RUN_VARIABLE: begin
        // intensity
        if (intensity_buf[0] < current_target_intensity[load_cnt]) begin
          diff_intensity_a <= current_target_intensity[load_cnt];
          diff_intensity_b <= intensity_buf[0];
        end else begin
          diff_intensity_a <= intensity_buf[0];
          diff_intensity_b <= current_target_intensity[load_cnt];
        end

        // wait phase fold
        diff_intensity_buf[0] <= diff_intensity;
        diff_intensity_buf[1] <= diff_intensity_buf[0];
        diff_intensity_buf[2] <= diff_intensity_buf[1];

        // phase
        if (phase_buf[0] < current_target_phase[load_cnt]) begin
          diff_phase_a <= current_target_phase[load_cnt];
          diff_phase_b <= phase_buf[0];
        end else begin
          diff_phase_a <= phase_buf[0];
          diff_phase_b <= current_target_phase[load_cnt];
        end

        // phase fold
        if (diff_phase >= 8'd128) begin
          phase_fold_a <= 9'd256;
          phase_fold_b <= {1'b0, diff_phase};
        end else begin
          phase_fold_a <= {1'b0, diff_phase};
          phase_fold_b <= 9'd0;
        end

        load_cnt <= load_cnt + 1;
        if (load_cnt > AddSubLatency) begin
          if (diff_intensity != 0) begin
            current_target_intensity[target_set_cnt] <= intensity_buf[AddSubLatency+1+AddSubLatency];
          end
          if (diff_phase != 0) begin
            current_target_phase[target_set_cnt] <= phase_buf[AddSubLatency+1+AddSubLatency];
          end
          target_set_cnt <= target_set_cnt + 1;
        end

        if (load_cnt > AddSubLatency + AddSubLatency + 1 + DivLatency) begin
          intensity <= intensity_buf[AddSubLatency+1+AddSubLatency+1+DivLatency];
          phase <= {phase_buf[AddSubLatency+1+AddSubLatency+1+DivLatency], 8'h00};
          update_rate_intensity <= intensity_step_quo;
          update_rate_phase <= phase_step_quo;
          dout_valid <= 1'b1;
          if (load_cnt == DEPTH + AddSubLatency + AddSubLatency + 1 + DivLatency) begin
            state <= WAITING;
          end
        end
      end
      default: begin
        state <= WAITING;
      end
    endcase
  end

  always_ff @(posedge CLK) begin
    intensity_buf[0] <= INTENSITY_IN;
    phase_buf[0] <= PHASE_IN;
  end
  for (genvar i = 1; i < AddSubLatency + 1 + AddSubLatency + 1 + DivLatency + 1; i++) begin : g_buf
    always_ff @(posedge CLK) begin
      intensity_buf[i] <= intensity_buf[i-1];
      phase_buf[i] <= phase_buf[i-1];
    end
  end

endmodule
