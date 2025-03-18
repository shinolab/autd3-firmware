`timescale 1ns / 1ps
module step_calculator #(
    parameter int DEPTH = 249
) (
    input var CLK,
    input var DIN_VALID,
    input var [15:0] COMPLETION_STEPS_INTENSITY,
    input var [15:0] COMPLETION_STEPS_PHASE,
    input var [7:0] INTENSITY,
    input var [7:0] PHASE,
    output var [15:0] UPDATE_RATE_INTENSITY,
    output var [15:0] UPDATE_RATE_PHASE,
    output var DOUT_VALID
);

  `include "define.vh"

  localparam int DivLatency = 18;

  `RAM
  logic [15:0] current_target_mem[256] = '{256{16'h0000}};
  `RAM
  logic [7:0] diff_mem_i[256] = '{256{8'h00}};
  `RAM
  logic [7:0] diff_mem_p[256] = '{256{8'h00}};
  `RAM
  logic [15:0] step_rem_mem_i[256] = '{256{16'h00}};
  `RAM
  logic [15:0] step_rem_mem_p[256] = '{256{16'h00}};

  logic [7:0] current_i, current_p;

  logic [7:0] output_cnt, cnt;
  logic reset_in_i, reset_out_i;
  logic reset_in_p, reset_out_p;
  logic [7:0] diff_tmp_i, diff_i;
  logic [7:0] diff_tmp_p, diff_p;
  logic [15:0] step_quo_i, step_rem_i;
  logic [15:0] step_quo_p, step_rem_p;

  logic dout_valid = 0;
  logic [15:0] update_rate_i, update_rate_p;

  assign current_i = current_target_mem[cnt][15:8];
  assign current_p = current_target_mem[cnt][7:0];

  assign UPDATE_RATE_INTENSITY = update_rate_i;
  assign UPDATE_RATE_PHASE = update_rate_p;
  assign DOUT_VALID = dout_valid;

  div_16_16 div_i (
      .s_axis_dividend_tdata({diff_i, 8'h00}),
      .s_axis_dividend_tvalid(1'b1),
      .s_axis_divisor_tdata(COMPLETION_STEPS_INTENSITY),
      .s_axis_divisor_tvalid(1'b1),
      .aclk(CLK),
      .m_axis_dout_tdata({step_quo_i, step_rem_i}),
      .m_axis_dout_tvalid()
  );

  div_16_16 div_p (
      .s_axis_dividend_tdata({diff_p, 8'h00}),
      .s_axis_dividend_tvalid(1'b1),
      .s_axis_divisor_tdata(COMPLETION_STEPS_PHASE),
      .s_axis_divisor_tvalid(1'b1),
      .aclk(CLK),
      .m_axis_dout_tdata({step_quo_p, step_rem_p}),
      .m_axis_dout_tvalid()
  );

  delay_fifo #(
      .WIDTH(2),
      .DEPTH(DivLatency)
  ) fifo_reset (
      .CLK (CLK),
      .DIN ({reset_in_i, reset_in_p}),
      .DOUT({reset_out_i, reset_out_p})
  );

  typedef enum logic [1:0] {
    IDLE,
    WAIT_CALC,
    OUTPUT
  } state_t;

  state_t state = IDLE;

  always_ff @(posedge CLK) begin
    if (DIN_VALID) begin
      current_target_mem[cnt] <= {INTENSITY, PHASE};
    end
  end

  always_ff @(posedge CLK) begin
    diff_tmp_i <= (INTENSITY < current_i) ? current_i - INTENSITY : INTENSITY - current_i;
    diff_tmp_p <= (PHASE < current_p) ? current_p - PHASE : PHASE - current_p;

    // diff_mem's index is shifted by 1
    if ((cnt == 8'd0) || (cnt == DEPTH + 1) || (diff_tmp_i == 8'd0)) begin
      reset_in_i <= 1'b0;
      diff_i <= diff_mem_i[cnt];
    end else begin
      reset_in_i <= 1'b1;
      diff_i <= diff_tmp_i;
      diff_mem_i[cnt] <= diff_tmp_i;
    end
    if ((cnt == 8'd0) || (cnt == DEPTH + 1) || (diff_tmp_p == 8'd0)) begin
      reset_in_p <= 1'b0;
      diff_p <= diff_mem_p[cnt];
    end else begin
      reset_in_p <= 1'b1;
      diff_p <= (diff_tmp_p >= 8'd128) ? 9'd256 - diff_tmp_p : diff_tmp_p;
      diff_mem_p[cnt] <= (diff_tmp_p >= 8'd128) ? 9'd256 - diff_tmp_p : diff_tmp_p;
    end

    if (reset_out_i) begin
      update_rate_i <= step_quo_i;
      step_rem_mem_i[output_cnt] <= step_rem_i;
    end else begin
      if (step_rem_mem_i[output_cnt] == '0) begin
        update_rate_i <= step_quo_i;
      end else begin
        update_rate_i <= step_quo_i + 1;
        step_rem_mem_i[output_cnt] <= (state == OUTPUT) ? step_rem_mem_i[output_cnt] - 1 : step_rem_mem_i[output_cnt];
      end
    end
    if (reset_out_p) begin
      update_rate_p <= step_quo_p;
      step_rem_mem_p[output_cnt] <= step_rem_p;
    end else begin
      if (step_rem_mem_p[output_cnt] == '0) begin
        update_rate_p <= step_quo_p;
      end else begin
        update_rate_p <= step_quo_p + 1;
        step_rem_mem_p[output_cnt] <= (state == OUTPUT) ? step_rem_mem_p[output_cnt] - 1 : step_rem_mem_p[output_cnt];
      end
    end
  end

  always_ff @(posedge CLK) begin
    case (state)
      IDLE: begin
        dout_valid <= 1'b0;
        output_cnt <= '0;
        if (DIN_VALID) begin
          cnt   <= 1;
          state <= WAIT_CALC;
        end else begin
          cnt <= '0;
        end
      end
      WAIT_CALC: begin
        cnt <= cnt + 1;
        if (cnt == DivLatency + 1) begin
          state <= OUTPUT;
        end
      end
      OUTPUT: begin
        cnt <= (cnt == DEPTH + 1) ? cnt : cnt + 1;
        output_cnt <= output_cnt + 1;
        dout_valid <= 1'b1;
        if (output_cnt == DEPTH - 1) begin
          state <= IDLE;
        end
      end
      default: state <= IDLE;
    endcase
  end

endmodule
