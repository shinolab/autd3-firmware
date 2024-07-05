`timescale 1ns / 1ps
module interpolator_intensity #(
    parameter int DEPTH = 249
) (
    input var CLK,
    input var DIN_VALID,
    input var [15:0] UPDATE_RATE,
    input var [15:0] INTENSITY_IN,
    output var [15:0] INTENSITY_OUT,
    output var DOUT_VALID
);

  `RAM
  logic [15:0] current_mem[256] = '{256{16'h0000}};

  logic [15:0] current, current_0;
  logic signed [16:0] update_rate_p, update_rate_n;
  logic signed [16:0] step;

  logic [7:0] cnt;
  logic dout_valid = 0;
  logic [15:0] intensity_out;

  assign current = current_mem[cnt];
  assign INTENSITY_OUT = intensity_out;
  assign DOUT_VALID = dout_valid;

  typedef enum logic {
    IDLE,
    RUN
  } state_t;

  state_t state = IDLE;

  always_ff @(posedge CLK) begin
    step <= $signed({1'b0, INTENSITY_IN}) - $signed({1'b0, current});
    current_0 <= current;
    update_rate_p <= $signed({1'b0, UPDATE_RATE});
    update_rate_n <= -$signed({1'b0, UPDATE_RATE});
    if (step < 17'sd0) begin
      intensity_out <= $signed({1'b0, current_0}) + ((update_rate_n < step) ? step : update_rate_n);
    end else begin
      intensity_out <= $signed({1'b0, current_0}) + ((step < update_rate_p) ? step : update_rate_p);
    end
  end

  always_ff @(posedge CLK) begin
    case (state)
      IDLE: begin
        dout_valid <= 1'b0;
        if (DIN_VALID) begin
          state <= RUN;
          cnt   <= 8'h1;
        end else begin
          cnt <= '0;
        end
      end
      RUN: begin
        dout_valid <= 1'b1;
        cnt <= cnt + 1;
        state <= (cnt == DEPTH) ? IDLE : state;
      end
      default: state <= IDLE;
    endcase
  end

  always_ff @(posedge CLK) begin
    if (dout_valid) begin
      current_mem[cnt-2] <= intensity_out;
    end
  end

endmodule
