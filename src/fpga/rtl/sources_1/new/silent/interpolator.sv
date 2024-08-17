`timescale 1ns / 1ps
module interpolator #(
    parameter int DEPTH = 249
) (
    input var CLK,
    input var DIN_VALID,
    input var [15:0] UPDATE_RATE_INTENSITY,
    input var [15:0] UPDATE_RATE_PHASE,
    input var [7:0] INTENSITY_IN,
    input var [7:0] PHASE_IN,
    output var [7:0] INTENSITY_OUT,
    output var [7:0] PHASE_OUT,
    output var DOUT_VALID
);

  `include "define.vh"

`RAM
  logic [31:0] current_mem[256] = '{256{32'h0000}};

  logic [31:0] current_0, current_1;
  logic [15:0] update_rate_i, update_rate_p;
  logic signed [16:0] update_rate_i_p, update_rate_i_n, update_rate_p_p, update_rate_p_n;
  logic signed [8:0] step_i, step_i_buf, step_p, step_p_wrapped;

  logic [7:0] cnt;
  logic dout_valid = 0;
  logic [15:0] intensity_out;
  logic [15:0] phase_out;

  assign INTENSITY_OUT = intensity_out[15:8];
  assign PHASE_OUT = phase_out[15:8];
  assign DOUT_VALID = dout_valid;

  typedef enum logic [1:0] {
    IDLE,
    WAIT,
    RUN
  } state_t;

  state_t state = IDLE;

  always_ff @(posedge CLK) begin
    step_i <= $signed({1'b0, INTENSITY_IN, 8'h00}) - $signed({1'b0, current_mem[cnt][31:16]});
    step_p <= $signed({1'b0, PHASE_IN, 8'h00}) - $signed({1'b0, current_mem[cnt][15:0]});
    current_0 <= current_mem[cnt];
    update_rate_i <= UPDATE_RATE_INTENSITY;
    update_rate_p <= UPDATE_RATE_PHASE;

    step_i_buf <= step_i;
    // If abs(step) is greater than π, phase goes in the opposite direction.
    if (step_p < 17'sd0) begin
      if (-17'sd32768 <= step_p) begin
        step_p_wrapped <= step_p;
      end else begin
        step_p_wrapped <= {1'b1, step_p} + 18'sd65536;
      end
    end else begin
      if (step_p <= 17'sd32768) begin
        step_p_wrapped <= step_p;
      end else begin
        step_p_wrapped <= {1'b0, step_p} - 18'sd65536;
      end
    end
    current_1 <= current_0;
    update_rate_i_p <= $signed({1'b0, update_rate_i});
    update_rate_i_n <= -$signed({1'b0, update_rate_i});
    update_rate_p_p <= $signed({1'b0, update_rate_p});
    update_rate_p_n <= -$signed({1'b0, update_rate_p});

    if (step_i_buf < 17'sd0) begin
      intensity_out <= $signed({1'b0, current_1[31:16]}) +
          ((update_rate_i_n < step_i_buf) ? step_i_buf : update_rate_i_n);
    end else begin
      intensity_out <= $signed({1'b0, current_1[31:16]}) +
          ((step_i_buf < update_rate_i_p) ? step_i_buf : update_rate_i_p);
    end
    if (step_p_wrapped < 17'sd0) begin
      phase_out <= $signed({1'b0, current_1[15:0]}) +
          ((update_rate_p_n < step_p_wrapped) ? step_p_wrapped : update_rate_p_n);
    end else begin
      phase_out <= $signed({1'b0, current_1[15:0]}) +
          ((step_p_wrapped < update_rate_p_p) ? step_p_wrapped : update_rate_p_p);
    end
  end

  always_ff @(posedge CLK) begin
    case (state)
      IDLE: begin
        dout_valid <= 1'b0;
        if (DIN_VALID) begin
          state <= WAIT;
          cnt   <= 1;
        end else begin
          cnt <= '0;
        end
      end
      WAIT: begin
        cnt   <= cnt + 1;
        state <= RUN;
      end
      RUN: begin
        cnt <= cnt + 1;
        dout_valid <= 1'b1;
        state <= (cnt == DEPTH + 1) ? IDLE : state;
      end
      default: state <= IDLE;
    endcase
  end

  always_ff @(posedge CLK) begin
    if (dout_valid) begin
      current_mem[cnt-3] <= {intensity_out, phase_out};
    end
  end

endmodule
