`timescale 1ns / 1ps
module pwm_preconditioner #(
    parameter int DEPTH = 249
) (
    input wire CLK,
    input wire DIN_VALID,
    input wire [7:0] PULSE_WIDTH,
    input wire [7:0] PHASE,
    output var [7:0] RISE[DEPTH],
    output var [7:0] FALL[DEPTH],
    output var DOUT_VALID
);

  logic [7:0] rise[DEPTH], fall[DEPTH];

  `RAM
  logic [7:0] rise_buf[DEPTH];
  `RAM
  logic [7:0] fall_buf[DEPTH];

  logic [7:0] s_rise, s_fall;

  logic [$clog2(DEPTH+1)-1:0] cnt;

  logic dout_valid;

  assign DOUT_VALID = dout_valid;
  assign RISE = rise;
  assign FALL = fall;

  typedef enum logic [1:0] {
    IDLE,
    RUN,
    DONE
  } state_t;

  always_ff @(posedge CLK) begin
    s_rise <= {1'b1, PHASE} - {2'b00, PULSE_WIDTH[7:1]};
    s_fall <= {1'b0, PHASE} + {2'b00, PULSE_WIDTH[7:1]} + PULSE_WIDTH[0];
  end

  state_t state = IDLE;

  always_ff @(posedge CLK) begin
    case (state)
      IDLE: begin
        dout_valid <= 1'b0;
        cnt <= '0;
        state <= DIN_VALID ? RUN : state;
      end
      RUN: begin
        cnt <= cnt + 1;
        rise_buf[cnt] <= s_rise;
        fall_buf[cnt] <= s_fall;
        state <= (cnt == DEPTH - 1) ? DONE : state;
      end
      DONE: begin
        dout_valid <= 1'b1;
        state <= IDLE;
      end
      default: state <= IDLE;
    endcase
  end

  always_ff @(posedge CLK) begin
    if (state == DONE) begin
      rise <= rise_buf;
      fall <= fall_buf;
    end
  end

endmodule
