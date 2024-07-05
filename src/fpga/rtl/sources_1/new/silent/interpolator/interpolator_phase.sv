`timescale 1ns / 1ps
module interpolator_phase #(
    parameter int DEPTH = 249
) (
    input var CLK,
    input var DIN_VALID,
    input var [7:0] UPDATE_RATE,
    input var [7:0] PHASE_IN,
    output var [7:0] PHASE_OUT,
    output var DOUT_VALID
);

  `RAM
  logic [7:0] current_mem[256] = '{256{8'h0000}};

  logic [7:0] current, current_0, current_1;
  logic [7:0] update_rate;
  logic signed [8:0] update_rate_p, update_rate_n;
  logic signed [8:0] step, step_wrapped;

  logic [7:0] cnt;
  logic dout_valid = 0;
  logic [7:0] phase_out;

  assign current = current_mem[cnt];
  assign PHASE_OUT = phase_out;
  assign DOUT_VALID = dout_valid;

  typedef enum logic [1:0] {
    IDLE,
    WAIT,
    RUN
  } state_t;

  state_t state = IDLE;

  always_ff @(posedge CLK) begin
    step <= $signed({1'b0, PHASE_IN}) - $signed({1'b0, current});
    current_0 <= current;
    update_rate <= UPDATE_RATE;

    // If abs(step) is greater than π, phase goes in the opposite direction.
    if (step < 9'sd0) begin
      if (-9'sd128 <= step) begin
        step_wrapped <= step;
      end else begin
        step_wrapped <= {1'b1, step} + 10'sd256;
      end
    end else begin
      if (step <= 17'sd128) begin
        step_wrapped <= step;
      end else begin
        step_wrapped <= {1'b0, step} - 10'sd256;
      end
    end
    current_1 <= current_0;
    update_rate_p <= $signed({1'b0, update_rate});
    update_rate_n <= -$signed({1'b0, update_rate});

    if (step_wrapped < 17'sd0) begin
      phase_out <= $signed({1'b0, current_1}) +
          ((update_rate_n < step_wrapped) ? step_wrapped : update_rate_n);
    end else begin
      phase_out <= $signed({1'b0, current_1}) +
          ((step_wrapped < update_rate_p) ? step_wrapped : update_rate_p);
    end
  end

  always_ff @(posedge CLK) begin
    case (state)
      IDLE: begin
        dout_valid <= 1'b0;
        if (DIN_VALID) begin
          state <= WAIT;
          cnt   <= cnt + 1;
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
      current_mem[cnt-3] <= phase_out;
    end
  end

endmodule
