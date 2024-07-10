`timescale 1ns / 1ps
module sim_helper_clk (
    output var MRCC_25P6M,
    output var CLK,
    clock_bus_if.out_port CLOCK_BUS,
    output var LOCKED,
    output var [63:0] SYS_TIME
);

  logic mrcc_25p6m;

  logic clk;
  logic locked;
  logic [63:0] sys_time;

  clock clock (
      .MRCC_25P6M(mrcc_25p6m),
      .CLOCK_BUS(CLOCK_BUS),
      .CLK(clk),
      .LOCKED(locked)
  );

  assign MRCC_25P6M = mrcc_25p6m;
  assign CLK = clk;
  assign LOCKED = locked;
  assign SYS_TIME = sys_time;

  initial begin
    mrcc_25p6m = '0;
    sys_time   = 1;  // start with 1 to to prevent `time_cnt_generator::UPDATE` from being asserted 
  end

  // main clock 25.6MHz
  always begin
    #19.531 mrcc_25p6m = !mrcc_25p6m;
    #19.531 mrcc_25p6m = !mrcc_25p6m;
    #19.531 mrcc_25p6m = !mrcc_25p6m;
    #19.532 mrcc_25p6m = !mrcc_25p6m;
  end

  always @(posedge clk) sys_time <= locked ? sys_time + 1 : sys_time;

endmodule
