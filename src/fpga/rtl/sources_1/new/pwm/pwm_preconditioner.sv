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

  logic [8:0] pulse_width_buf[4], phase_buf;
  logic [8:0] rise_buf[DEPTH], fall_buf[DEPTH];

  logic signed [10:0] a_phase, b_phase, s_phase;
  logic signed [10:0] a_pulse_width_r, b_pulse_width_r, s_pulse_width_r;
  logic signed [10:0] a_rise, b_rise, s_rise;
  logic signed [10:0] a_fall, b_fall, s_fall;

  logic [$clog2(DEPTH+1+AddSubLatency*2)-1:0] cnt, lr_cnt, set_cnt;

  logic dout_valid;

  assign DOUT_VALID = dout_valid;

  for (genvar i = 0; i < DEPTH; i++) begin : gen_rise_fall
    assign RISE[i] = rise[i];
    assign FALL[i] = fall[i];
  end

  addsub #(
      .WIDTH(11)
  ) sub_phase (
      .CLK(CLK),
      .A  (a_phase),
      .B  (b_phase),
      .ADD(1'b0),
      .S  (s_phase)
  );
  addsub #(
      .WIDTH(11)
  ) add_pulse_width_r (
      .CLK(CLK),
      .A  (a_pulse_width_r),
      .B  (b_pulse_width_r),
      .ADD(1'b1),
      .S  (s_pulse_width_r)
  );

  addsub #(
      .WIDTH(11)
  ) sub_rise (
      .CLK(CLK),
      .A  (a_rise),
      .B  (b_rise),
      .ADD(1'b0),
      .S  (s_rise)
  );
  addsub #(
      .WIDTH(11)
  ) add_fall (
      .CLK(CLK),
      .A  (a_fall),
      .B  (b_fall),
      .ADD(1'b1),
      .S  (s_fall)
  );

  typedef enum logic [2:0] {
    WAITING,
    RUN,
    DONE
  } state_t;

  state_t state = WAITING;

  always_ff @(posedge CLK) begin
    case (state)
      WAITING: begin
        dout_valid <= 1'b0;
        if (DIN_VALID) begin
          cnt <= '0;
          lr_cnt <= '0;
          set_cnt <= '0;

          state <= RUN;
        end
      end
      RUN: begin
        // step 1
        a_phase <= 11'd512;
        b_phase <= {2'b00, phase_buf};
        a_pulse_width_r <= {3'b000, pulse_width_buf[0][8:1]};
        b_pulse_width_r <= pulse_width_buf[0][0];
        cnt <= cnt + 1;

        // step 2
        a_rise <= s_phase;
        b_rise <= {3'b000, pulse_width_buf[1+AddSubLatency][8:1]};
        a_fall <= s_phase;
        b_fall <= s_pulse_width_r;
        if (cnt > AddSubLatency) begin
          lr_cnt <= lr_cnt + 1;
        end

        if (lr_cnt > AddSubLatency) begin
          rise_buf[set_cnt] <= s_rise[8:0];
          fall_buf[set_cnt] <= s_fall[8:0];

          set_cnt <= set_cnt + 1;
        end

        if (set_cnt == DEPTH - 1) begin
          state <= DONE;
        end
      end
      DONE: begin
        dout_valid <= 1'b1;

        state <= WAITING;
      end
      default: begin
      end
    endcase
  end

  always_ff @(posedge CLK) begin
    pulse_width_buf[0] <= PULSE_WIDTH;
    pulse_width_buf[1] <= pulse_width_buf[0];
    pulse_width_buf[2] <= pulse_width_buf[1];
    pulse_width_buf[3] <= pulse_width_buf[2];

    phase_buf <= {PHASE, 1'b0};
  end

  for (genvar i = 0; i < DEPTH; i++) begin : gen_copy_buf
    always_ff @(posedge CLK) begin
      if (state == DONE) begin
        rise[i] <= rise_buf[i];
        fall[i] <= fall_buf[i];
      end
    end
  end

endmodule
