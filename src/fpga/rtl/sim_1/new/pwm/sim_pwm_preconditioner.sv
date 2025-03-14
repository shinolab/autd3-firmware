`timescale 1ns / 1ps
module sim_pwm_preconditioner ();

  `include "define.vh"

  logic CLK;
  logic locked;
  sim_helper_clk sim_helper_clk (
      .MRCC_25P6M(),
      .CLK(CLK),
      .LOCKED(locked),
      .SYS_TIME()
  );

  sim_helper_random sim_helper_random ();

  localparam int DEPTH = 249;
  localparam int T = 512;

  logic [8:0] pulse_width;
  logic [7:0] phase;

  logic [8:0] rise[DEPTH];
  logic [8:0] fall[DEPTH];
  logic din_valid, dout_valid;

  logic [8:0] pulse_width_buf[DEPTH];
  logic [7:0] phase_buf[DEPTH];

  pwm_preconditioner #(
      .DEPTH(DEPTH)
  ) pwm_preconditioner (
      .CLK(CLK),
      .DIN_VALID(din_valid),
      .PULSE_WIDTH(pulse_width),
      .PHASE(phase),
      .RISE(rise),
      .FALL(fall),
      .DOUT_VALID(dout_valid)
  );

  task automatic set(int idx, logic [8:0] d, logic [8:0] p);
    for (int i = 0; i < DEPTH; i++) begin
      if (i === idx) begin
        pulse_width_buf[i] = d;
        phase_buf[i] = p / 2;
      end else begin
        pulse_width_buf[i] = 0;
        phase_buf[i] = 0;
      end
    end
    for (int i = 0; i < DEPTH; i++) begin
      @(posedge CLK);
      din_valid <= 1'b1;
      pulse_width <= pulse_width_buf[i];
      phase <= phase_buf[i];
    end
    @(posedge CLK);
    din_valid <= 1'b0;
  endtask

  task automatic check_manual(int idx, logic [8:0] rise_e, logic [8:0] fall_e);
    while (1) begin
      @(posedge CLK);
      if (dout_valid) begin
        break;
      end
    end

    for (int i = 0; i < DEPTH; i++) begin
      if (i === idx) begin
        `ASSERT_EQ(rise_e, rise[i]);
        `ASSERT_EQ(fall_e, fall[i]);
      end else begin
        `ASSERT_EQ(0, rise[i]);
        `ASSERT_EQ(0, fall[i]);
      end
    end
  endtask

  task automatic set_random();
    for (int i = 0; i < DEPTH; i++) begin
      pulse_width_buf[i] = sim_helper_random.range(T - 1, 0);
      phase_buf[i] = sim_helper_random.range(T / 2 - 1, 0);
    end
    for (int i = 0; i < DEPTH; i++) begin
      @(posedge CLK);
      din_valid <= 1'b1;
      pulse_width <= pulse_width_buf[i];
      phase <= phase_buf[i];
    end
    @(posedge CLK);
    din_valid <= 1'b0;
  endtask

  task automatic check();
    while (1) begin
      @(posedge CLK);
      if (dout_valid) begin
        break;
      end
    end

    for (int i = 0; i < DEPTH; i++) begin
      `ASSERT_EQ(((T + phase_buf[i] * 2 - pulse_width_buf[i] / 2) % T), rise[i]);
      `ASSERT_EQ(((phase_buf[i] * 2 + (pulse_width_buf[i] + 1) / 2) % T), fall[i]);
    end
  endtask

  initial begin
    din_valid = 1'b0;
    @(posedge locked);

    fork
      set(0, T / 2, T / 2);  // normal, D=T/2
      check_manual(0, T / 2 - T / 4, T / 2 + T / 4);
    join

    fork
      set(0, T / 2 - 1, T / 2);  // normal, D=T/2-1
      check_manual(0, T / 2 - T / 4 + 1, T / 2 + T / 4);
    join

    fork
      set(0, 1, T / 2);  // normal, D=1
      check_manual(0, T / 2, T / 2 + 1);
    join

    fork
      set(0, 0, T / 2);  // normal, D=0
      check_manual(0, T / 2, T / 2);
    join

    fork
      set(0, T / 2, T / 4);  // normal, D=T/2, left edge
      check_manual(0, 0, T / 2);
    join

    fork
      set(0, T / 2, T / 2 + T / 4);  // normal, D=T/2, right edge
      check_manual(0, T / 2, 0);
    join

    fork
      set(0, T / 2, 2);  // left over, D=T/2
      check_manual(0, T / 2 + T / 4 + 2, T / 4 + 2);
    join

    fork
      set(0, T / 2, T - 2);  // right over, D=T/2
      check_manual(0, T / 2 + T / 4 - 2, T / 4 - 2);
    join

    // at random
    sim_helper_random.init();
    for (int i = 0; i < 5000; i++) begin
      $display("Check start @%d", i);
      fork
        set_random();
        check();
      join
    end

    $display("OK! sim_pwm_preconditioner");
    $finish();
  end

endmodule
