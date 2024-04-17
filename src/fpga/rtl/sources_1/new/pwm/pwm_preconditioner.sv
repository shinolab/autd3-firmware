`timescale 1ns / 1ps
module pwm_preconditioner #(
    parameter int DEPTH = 249
) (
    input wire CLK,
    input wire DIN_VALID,
    input wire [8:0] PULSE_WIDTH,
    input wire [7:0] PHASE,
    output var [8:0] RISE[DEPTH],
    output var [8:0] FALL[DEPTH],
    output var DOUT_VALID
);

  localparam int AddSubLatency = 2;

  logic [8:0] rise[DEPTH], fall[DEPTH];
  logic [8:0] rise_buf[DEPTH], fall_buf[DEPTH];

  logic [8:0] pulse_width_buf;

  logic [8:0] s_phase;
  logic [7:0] s_pulse_width_r;
  logic [9:0] s_rise, s_fall;

  logic [$clog2(DEPTH+1+AddSubLatency*2)-1:0] cnt;

  logic dout_valid;

  assign DOUT_VALID = dout_valid;
  assign RISE = rise;
  assign FALL = fall;

  delay_fifo #(
      .WIDTH(9),
      .DEPTH(4)
  ) pw_buf (
      .CLK (CLK),
      .DIN (PULSE_WIDTH),
      .DOUT(pulse_width_buf)
  );

  addsub #(
      .WIDTH(9)
  ) sub_phase (
      .CLK(CLK),
      .A  (9'd256),
      .B  ({1'b0, PHASE}),
      .ADD(1'b0),
      .S  (s_phase)
  );
  addsub #(
      .WIDTH(8)
  ) add_pulse_width_r (
      .CLK(CLK),
      .A  ({PULSE_WIDTH[8:1]}),
      .B  ({7'h00, PULSE_WIDTH[0]}),
      .ADD(1'b1),
      .S  (s_pulse_width_r)
  );

  addsub #(
      .WIDTH(10)
  ) sub_rise (
      .CLK(CLK),
      .A  ({s_phase, 1'b0}),
      .B  ({2'b00, pulse_width_buf[8:1]}),
      .ADD(1'b0),
      .S  (s_rise)
  );
  addsub #(
      .WIDTH(10)
  ) add_fall (
      .CLK(CLK),
      .A  ({s_phase, 1'b0}),
      .B  ({2'b00, s_pulse_width_r}),
      .ADD(1'b1),
      .S  (s_fall)
  );

  typedef enum logic [2:0] {
    IDLE,
    WAIT0,
    WAIT1,
    RUN,
    DONE
  } state_t;

  state_t state = IDLE;

  always_ff @(posedge CLK) begin
    case (state)
      IDLE: begin
        dout_valid <= 1'b0;
        if (DIN_VALID) begin
          cnt   <= '0;
          state <= WAIT0;
        end
      end
      WAIT0: begin
        state <= WAIT1;
      end
      WAIT1: begin
        state <= RUN;
      end
      RUN: begin
        cnt <= cnt + 1;
        rise_buf[cnt] <= s_rise[8:0];
        fall_buf[cnt] <= s_fall[8:0];
        state <= (cnt == AddSubLatency + AddSubLatency + DEPTH - 1) ? DONE : state;
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
