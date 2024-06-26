`timescale 1ns / 1ps
module sim_pwm_generator ();

  logic CLK;
  logic locked;
  logic [63:0] SYS_TIME;
  clock_bus_if clock_bus ();
  sim_helper_clk sim_helper_clk (
      .MRCC_25P6M(),
      .CLK(CLK),
      .CLOCK_BUS(clock_bus.out_port),
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
    while (time_cnt !== 512 - 1) @(posedge CLK);
    rise = r;
    fall = f;
    @(posedge CLK);
    $display("Check start\t@t=%d", SYS_TIME);
    while (1) begin
      automatic int t = time_cnt;
      @(posedge CLK);
      if (pwm_out !== (((r <= f) & ((r <= t) & (t < f))) | ((f < r) & ((r <= t) | (t < f))))) begin
        $error("At v=%u, t=%d, R=%d, F=%d", pwm_out, time_cnt, rise, fall);
        $finish();
      end
      if (time_cnt === 512 - 1) begin
        break;
      end
    end
    $display("Check done\t@t=%d", SYS_TIME);
  endtask

  initial begin
    rise = 0;
    fall = 0;
    @(posedge locked);

    set(512 / 2 - 512 / 4, 512 / 2 + 512 / 4);  // normal, D=512/2
    set(0, 512);  // normal, D=512
    set(512 / 2, 512 / 2);  // normal, D=0
    set(0, 512 / 2);  // normal, D=512/2, left edge
    set(512 - 512 / 2, 512);  // normal, D=512/2, right edge

    set(512 - 512 / 4, 512 / 4);  // over, D=512/2
    set(512, 0);  // over, D=0
    set(512, 512 / 2);  // over, D=512/2, right edge
    set(512 - 512 / 2, 0);  // over, D=512/2, left edge

    set(0, 0);

    $display("OK!");
    $finish();
  end

endmodule
