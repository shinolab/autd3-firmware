`timescale 1ns / 1ps
module pwm_generator (
    input var CLK,
    input var [8:0] TIME_CNT,
    input var [8:0] RISE,
    input var [8:0] FALL,
    output var PWM_OUT
);

  logic [8:0] t;
  logic [8:0] R;
  logic [8:0] F;
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
