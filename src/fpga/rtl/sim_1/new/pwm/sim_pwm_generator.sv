`timescale 1ns / 1ps
module sim_pwm_generator ();

  `include "define.vh"

  logic CLK;
  logic locked;
  logic [60:0] SYS_TIME;
  sim_helper_clk sim_helper_clk (
      .MRCC_25P6M(),
      .CLK(CLK),
      .LOCKED(locked),
      .SYS_TIME(SYS_TIME)
  );

  logic [7:0] time_cnt;
  assign time_cnt = SYS_TIME[7:0];

  logic [7:0] rise, fall;

  logic pwm_out;

  pwm_generator pwm_generator (
      .CLK(CLK),
      .TIME_CNT(time_cnt),
      .RISE(rise),
      .FALL(fall),
      .PWM_OUT(pwm_out)
  );

  task automatic set(logic [7:0] r, logic [7:0] f);
    while (time_cnt !== 256 - 1) @(posedge CLK);
    rise = r;
    fall = f;
    @(posedge CLK);
    $display("Check start\t@t=%d", SYS_TIME);
    while (1) begin
      automatic int t = time_cnt;
      @(posedge CLK);
      `ASSERT_EQ((((r <= f) & ((r <= t) & (t < f))) | ((f < r) & ((r <= t) | (t < f)))), pwm_out);
      if (time_cnt === 256 - 1) begin
        break;
      end
    end
    $display("Check done\t@t=%d", SYS_TIME);
  endtask

  initial begin
    rise = 0;
    fall = 0;
    @(posedge locked);

    set(256 / 2 - 256 / 4, 256 / 2 + 256 / 4);  // normal, D=T/2
    set(0, 256);  // normal, D=T
    set(256 / 2, 256 / 2);  // normal, D=0
    set(0, 256 / 2);  // normal, D=T/2, left edge
    set(256 - 256 / 2, 256);  // normal, D=T/2, right edge

    set(256 - 256 / 4, 256 / 4);  // over, D=T/2
    set(256, 0);  // over, D=0
    set(256, 256 / 2);  // over, D=T/2, right edge
    set(256 - 256 / 2, 0);  // over, D=T/2, left edge

    set(0, 0);

    $display("OK!");
    $finish();
  end

endmodule
