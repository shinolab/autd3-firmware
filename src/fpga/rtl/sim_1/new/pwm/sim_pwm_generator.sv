`timescale 1ns / 1ps
module sim_pwm_generator ();

  `include "define.vh"

  localparam int T = 512;

  logic CLK;
  logic locked;
  logic [56:0] SYS_TIME;
  sim_helper_clk sim_helper_clk (
      .MRCC_25P6M(),
      .CLK(CLK),
      .LOCKED(locked),
      .SYS_TIME(SYS_TIME)
  );

  logic [8:0] time_cnt;
  assign time_cnt = SYS_TIME[8:0];

  logic [8:0] rise, fall;

  logic pwm_out;

  pwm_generator pwm_generator (
      .CLK(CLK),
      .TIME_CNT(time_cnt),
      .RISE(rise),
      .FALL(fall),
      .PWM_OUT(pwm_out)
  );

  task automatic set(logic [8:0] r, logic [8:0] f);
    while (time_cnt !== T - 1) @(posedge CLK);
    rise = r;
    fall = f;
    @(posedge CLK);
    $display("Check start\t@t=%d", SYS_TIME);
    while (1) begin
      automatic int t = time_cnt;
      @(posedge CLK);
      `ASSERT_EQ((((r <= f) & ((r <= t) & (t < f))) | ((f < r) & ((r <= t) | (t < f)))), pwm_out);
      if (time_cnt === T - 1) begin
        break;
      end
    end
    $display("Check done\t@t=%d", SYS_TIME);
  endtask

  initial begin
    rise = 0;
    fall = 0;
    @(posedge locked);

    set(T / 2 - T / 4, T / 2 + T / 4);  // normal, D=T/2
    set(0, T);  // normal, D=T
    set(T / 2, T / 2);  // normal, D=0
    set(0, T / 2);  // normal, D=T/2, left edge
    set(T - T / 2, T);  // normal, D=T/2, right edge

    set(T - T / 4, T / 4);  // over, D=T/2
    set(T, 0);  // over, D=0
    set(T, T / 2);  // over, D=T/2, right edge
    set(T - T / 2, 0);  // over, D=T/2, left edge

    set(0, 0);

    $display("OK!");
    $finish();
  end

endmodule
