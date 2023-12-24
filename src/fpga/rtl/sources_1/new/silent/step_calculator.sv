/*
 * File: step_calculator.sv
 * Project: silent
 * Created Date: 21/12/2023
 * Author: Shun Suzuki
 * -----
 * Last Modified: 24/12/2023
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
  logic [$clog2(DEPTH+AddSubLatency)-1:0] remainds_set_cnt;

  logic [15:0] completion_steps_intensity;
  logic [15:0] completion_steps_phase;
  logic [15:0] current_target_intensity[DEPTH] = '{DEPTH{0}};
  logic [7:0] current_target_phase[DEPTH] = '{DEPTH{0}};
  logic [15:0] diff_intensity_a, diff_intensity_b, diff_intensity_tmp;
  logic [15:0] diff_intensity_buf[3];
  logic [7:0] diff_phase_a, diff_phase_b, diff_phase_tmp;
  logic [15:0] diff_intensity[DEPTH];
  logic [7:0] diff_phase[DEPTH];
  logic [15:0] intensity_step_quo, intensity_step_rem;
  logic [15:0] phase_step_quo, phase_step_rem;
  logic [15:0] phase_step_remainds[DEPTH];
  logic [15:0] intensity_step_remainds[DEPTH];
  logic [8:0] phase_fold_a, phase_fold_b, phase_fold_s;
  logic is_phase_reset[DivLatency+3];
  logic is_intensity_reset[DivLatency+3];

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
      .S  (diff_intensity_tmp)
  );

  addsub #(
      .WIDTH(8)
  ) addsub_diff_phase (
      .CLK(CLK),
      .A  (diff_phase_a),
      .B  (diff_phase_b),
      .ADD(1'b0),
      .S  (diff_phase_tmp)
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
      .m_axis_dout_tdata({intensity_step_quo, intensity_step_rem}),
      .m_axis_dout_tvalid()
  );

  div_16_16 div_16_16_phase (
      .s_axis_dividend_tdata({phase_fold_s[7:0], 8'h00}),
      .s_axis_dividend_tvalid(1'b1),
      .s_axis_divisor_tdata(completion_steps_phase),
      .s_axis_divisor_tvalid(1'b1),
      .aclk(CLK),
      .m_axis_dout_tdata({phase_step_quo, phase_step_rem}),
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
          remainds_set_cnt <= 0;

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

        load_cnt <= load_cnt + 1;
        if (load_cnt > AddSubLatency) begin
          if (diff_intensity_tmp != 0) begin
            is_intensity_reset[0] <= 1'b1;
            diff_intensity[target_set_cnt] <= diff_intensity_tmp;
            diff_intensity_buf[0] <= diff_intensity_tmp;
            current_target_intensity[target_set_cnt] <= intensity_buf[AddSubLatency+1+AddSubLatency];
          end else begin
            is_intensity_reset[0] <= 1'b0;
            diff_intensity_buf[0] <= diff_intensity[target_set_cnt];
          end
          target_set_cnt <= target_set_cnt + 1;
        end

        // wait phase fold
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
        if (load_cnt > AddSubLatency) begin
          if (diff_phase_tmp != 0) begin
            is_phase_reset[0] <= 1'b1;
            diff_phase[target_set_cnt] <= diff_phase_tmp;
            if (diff_phase_tmp >= 8'd128) begin
              phase_fold_a <= 9'd256;
              phase_fold_b <= {1'b0, diff_phase_tmp};
            end else begin
              phase_fold_a <= {1'b0, diff_phase_tmp};
              phase_fold_b <= 9'd0;
            end
            current_target_phase[target_set_cnt] <= phase_buf[AddSubLatency+1+AddSubLatency];
          end else begin
            is_phase_reset[0] <= 1'b0;
            if (diff_phase[target_set_cnt] >= 8'd128) begin
              phase_fold_a <= 9'd256;
              phase_fold_b <= {1'b0, diff_phase[target_set_cnt]};
            end else begin
              phase_fold_a <= {1'b0, diff_phase[target_set_cnt]};
              phase_fold_b <= 9'd0;
            end
          end
        end

        // wait phase fold
        is_phase_reset[1] <= is_phase_reset[0];
        is_phase_reset[2] <= is_phase_reset[1];

        if (load_cnt > AddSubLatency + AddSubLatency + 1 + DivLatency) begin
          intensity <= intensity_buf[AddSubLatency+1+AddSubLatency+1+DivLatency];
          phase <= {phase_buf[AddSubLatency+1+AddSubLatency+1+DivLatency], 8'h00};

          if (is_intensity_reset[DivLatency+2]) begin
            if (intensity_step_rem == 0) begin
              intensity_step_remainds[remainds_set_cnt] <= 0;
              update_rate_intensity <= intensity_step_quo;
            end else begin
              update_rate_intensity <= intensity_step_quo + 1;
              intensity_step_remainds[remainds_set_cnt] <= intensity_step_rem - 1;
            end
          end else begin
            if (intensity_step_remainds[remainds_set_cnt] == 0) begin
              update_rate_intensity <= intensity_step_quo;
            end else begin
              update_rate_intensity <= intensity_step_quo + 1;
              intensity_step_remainds[remainds_set_cnt] <= intensity_step_remainds[remainds_set_cnt] - 1;
            end
          end
          if (is_phase_reset[DivLatency+2]) begin
            if (phase_step_rem == 0) begin
              phase_step_remainds[remainds_set_cnt] <= 0;
              update_rate_phase <= phase_step_quo;
            end else begin
              update_rate_phase <= phase_step_quo + 1;
              phase_step_remainds[remainds_set_cnt] <= phase_step_rem - 1;
            end
          end else begin
            if (phase_step_remainds[remainds_set_cnt] == 0) begin
              update_rate_phase <= phase_step_quo;
            end else begin
              update_rate_phase <= phase_step_quo + 1;
              phase_step_remainds[remainds_set_cnt] <= phase_step_remainds[remainds_set_cnt] - 1;
            end
          end
          remainds_set_cnt <= remainds_set_cnt + 1;

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

  for (genvar i = 1; i < DivLatency + 2; i++) begin : g_reset_buf
    always_ff @(posedge CLK) begin
      is_intensity_reset[i] <= is_intensity_reset[i-1];
      is_phase_reset[i] <= is_phase_reset[i-1];
    end
  end

endmodule
