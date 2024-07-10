`timescale 1ns / 1ps
module sim_pwm_preconditioner ();

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

  logic [7:0] pulse_width;
  logic [7:0] phase;

  logic [7:0] rise[DEPTH];
  logic [7:0] fall[DEPTH];
  logic din_valid, dout_valid;

  logic [7:0] pulse_width_buf[DEPTH];
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

  task automatic set(int idx, logic [7:0] d, logic [7:0] p);
    for (int i = 0; i < DEPTH; i++) begin
      if (i === idx) begin
        pulse_width_buf[i] = d;
        phase_buf[i] = p;
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

  task automatic check_manual(int idx, logic [7:0] rise_e, logic [7:0] fall_e);
    while (1) begin
      @(posedge CLK);
      if (dout_valid) begin
        break;
      end
    end

    for (int i = 0; i < DEPTH; i++) begin
      if (i === idx) begin
        if ((rise[i] !== rise_e) | (fall[i] !== fall_e)) begin
          $error("At idx=%d, R(%d) != %d, F(%d) != %d", i, rise[i], rise_e, fall[i], fall_e);
          $finish();
        end
      end else begin
        if ((rise[i] !== 0) | (fall[i] !== 0)) begin
          $error("At idx=%d, R=%d, F=%d", i, rise[i], fall[i]);
          $finish();
        end
      end
    end
  endtask

  task automatic set_random();
    for (int i = 0; i < DEPTH; i++) begin
      pulse_width_buf[i] = sim_helper_random.range(255, 0);
      phase_buf[i] = sim_helper_random.range(255, 0);
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
      if ((rise[i] !== ((256+phase_buf[i]-pulse_width_buf[i]/2)%256))
        | (fall[i] !== ((phase_buf[i]+(pulse_width_buf[i]+1)/2)%256))) begin
        $error("At idx=%d, d=%d, p=%d, R=%d, F=%d", i, pulse_width_buf[i], phase_buf[i], rise[i],
               fall[i]);
        $finish();
      end
    end
  endtask

  initial begin
    @(posedge locked);

    fork
      set(0, 128, 128);  // normal, D=T/2
      check_manual(0, 64, 192);
    join

    fork
      set(0, 127, 128);  // normal, D=T/2-1
      check_manual(0, 65, 192);
    join

    fork
      set(0, 1, 128);  // normal, D=1
      check_manual(0, 128, 129);
    join

    fork
      set(0, 0, 128);  // normal, D=0
      check_manual(0, 128, 128);
    join

    fork
      set(0, 128, 64);  // normal, D=T/2, left edge
      check_manual(0, 0, 128);
    join

    fork
      set(0, 128, 192);  // normal, D=T/2, right edge
      check_manual(0, 128, 0);
    join

    fork
      set(0, 128, 1);  // left over, D=T/2
      check_manual(0, 193, 65);
    join

    fork
      set(0, 128, 255);  // right over, D=T/2
      check_manual(0, 191, 63);
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
