`timescale 1ns / 1ps
module pwm_buffer (
    input var CLK,
    input var UPDATE,
    input var [7:0] RISE_IN,
    input var [7:0] FALL_IN,
    output var [7:0] RISE_OUT,
    output var [7:0] FALL_OUT
);

  logic [7:0] R;
  logic [7:0] F;

  assign RISE_OUT = R;
  assign FALL_OUT = F;

  always_ff @(posedge CLK) begin
    if (UPDATE) begin
      R <= RISE_IN;
      F <= FALL_IN;
    end
  end

endmodule
