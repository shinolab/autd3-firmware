`timescale 1ns / 1ps
module pwm_generator (
    input wire CLK,
    input wire [7:0] TIME_CNT,
    input wire [7:0] RISE,
    input wire [7:0] FALL,
    output var PWM_OUT
);

  logic [7:0] t;
  logic [7:0] R;
  logic [7:0] F;
  logic v;

  assign t = TIME_CNT;
  assign R = RISE;
  assign F = FALL;
  assign PWM_OUT = v;

  always_ff @(posedge CLK) begin
    if (R <= F) begin
      v <= (R <= t) & (t < F);
    end else begin
      v <= (t < F) | (R <= t);
    end
  end

endmodule
