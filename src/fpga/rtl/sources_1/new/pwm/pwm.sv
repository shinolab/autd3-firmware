`timescale 1ns / 1ps
module pwm #(
    parameter int DEPTH = 249
) (
    input wire CLK,
    input wire [7:0] TIME_CNT,
    input wire UPDATE,
    input wire DIN_VALID,
    input wire [7:0] PULSE_WIDTH,
    input wire [7:0] PHASE,
    output wire PWM_OUT[DEPTH],
    output wire DOUT_VALID
);

  logic [7:0] R[DEPTH];
  logic [7:0] F[DEPTH];

  pwm_preconditioner #(
      .DEPTH(DEPTH)
  ) pwm_preconditioner (
      .CLK(CLK),
      .DIN_VALID(DIN_VALID),
      .PULSE_WIDTH(PULSE_WIDTH),
      .PHASE(PHASE),
      .RISE(R),
      .FALL(F),
      .DOUT_VALID(DOUT_VALID)
  );

  for (genvar i = 0; i < DEPTH; i++) begin : gen_pwm
    logic [7:0] R_buf, F_buf;
    pwm_buffer pwm_buffer (
        .CLK(CLK),
        .UPDATE(UPDATE),
        .RISE_IN(R[i]),
        .FALL_IN(F[i]),
        .RISE_OUT(R_buf),
        .FALL_OUT(F_buf)
    );
    pwm_generator pwm_generator (
        .CLK(CLK),
        .TIME_CNT(TIME_CNT),
        .RISE(R_buf),
        .FALL(F_buf),
        .PWM_OUT(PWM_OUT[i])
    );
  end

endmodule
