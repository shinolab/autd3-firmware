`timescale 1ns / 1ps
module sim_helper_clk #(
    parameter real SPEED_UP = 1.0
) (
    output wire CLK_20P48M,
    output wire LOCKED,
    output wire [63:0] SYS_TIME
);

  logic MRCC_25P6M;

  logic clk_20P48M;
  logic locked;
  logic reset;
  logic [63:0] sys_time;

  ultrasound_cnt_clk_gen ultrasound_cnt_clk_gen (
      .clk_in1(MRCC_25P6M),
      .reset  (reset),
      .locked (locked),
      .clk_out(clk_20P48M)
  );

  assign CLK_20P48M = clk_20P48M;
  assign LOCKED = locked;
  assign SYS_TIME = sys_time;

  initial begin
    MRCC_25P6M = 0;
    reset = 1;
    #1000;
    reset = 0;
    sys_time = 1;
  end

  // main clock 25.6MHz
  always begin
    #(19.531 / SPEED_UP) MRCC_25P6M = !MRCC_25P6M;
    #(19.531 / SPEED_UP) MRCC_25P6M = !MRCC_25P6M;
    #(19.531 / SPEED_UP) MRCC_25P6M = !MRCC_25P6M;
    #(19.532 / SPEED_UP) MRCC_25P6M = !MRCC_25P6M;
  end

  always @(posedge clk_20P48M) begin
    sys_time = sys_time + 1;
  end

endmodule
