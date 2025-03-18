`timescale 1ns / 1ps
module sim_silencer_fixed_update_rate ();

  `include "define.vh"

  parameter int DEPTH = 249;

  logic CLK;
  logic locked;
  sim_helper_clk sim_helper_clk (
      .MRCC_25P6M(),
      .CLK(CLK),
      .LOCKED(locked),
      .SYS_TIME()
  );

  sim_helper_random sim_helper_random ();

  settings::silencer_settings_t silencer_settings;
  logic [7:0] intensity;
  logic [7:0] phase;
  logic [7:0] intensity_s;
  logic [7:0] phase_s;
  logic din_valid, dout_valid;

  logic [7:0] intensity_buf[DEPTH];
  logic [7:0] phase_buf[DEPTH];
  logic [7:0] intensity_s_buf[DEPTH];
  logic [7:0] phase_s_buf[DEPTH];

  silencer #(
      .DEPTH(DEPTH)
  ) silencer (
      .CLK(CLK),
      .DIN_VALID(din_valid),
      .SILENCER_SETTINGS(silencer_settings),
      .INTENSITY_IN(intensity),
      .PHASE_IN(phase),
      .INTENSITY_OUT(intensity_s),
      .PHASE_OUT(phase_s),
      .DOUT_VALID(dout_valid)
  );

  int n_repeat;

  task automatic set();
    for (int i = 0; i < DEPTH; i++) begin
      @(posedge CLK);
      din_valid <= 1'b1;
      intensity <= intensity_buf[i];
      phase <= phase_buf[i];
    end
    @(posedge CLK);
    din_valid = 1'b0;
  endtask

  task automatic wait_calc();
    while (1) begin
      @(posedge CLK);
      if (dout_valid) begin
        break;
      end
    end

    for (int i = 0; i < DEPTH; i++) begin
      intensity_s_buf[i] = intensity_s;
      phase_s_buf[i] = phase_s;
      @(posedge CLK);
    end
  endtask

  task automatic check_manual(logic [7:0] expect_intensity, logic [7:0] expect_phase);
    for (int i = 0; i < DEPTH; i++) begin
      `ASSERT_EQ(expect_phase, phase_s_buf[i]);
      `ASSERT_EQ(expect_intensity, intensity_s_buf[i]);
    end
  endtask

  task automatic check();
    for (int i = 0; i < DEPTH; i++) begin
      `ASSERT_EQ(phase_buf[i], phase_s_buf[i]);
      `ASSERT_EQ(intensity_buf[i], intensity_s_buf[i]);
    end
  endtask

  initial begin
    silencer_settings.FLAG = 1 << params::SILENCER_FLAG_BIT_FIXED_UPDATE_RATE_MODE;

    din_valid = 0;
    silencer_settings.UPDATE_RATE_INTENSITY = 0;
    silencer_settings.UPDATE_RATE_PHASE = 0;
    phase = 0;
    intensity = 0;
    sim_helper_random.init();

    @(posedge locked);

    //////////////// Manual check ////////////////
    silencer_settings.UPDATE_RATE_INTENSITY = 1;
    silencer_settings.UPDATE_RATE_PHASE = 1;
    for (int i = 0; i < DEPTH; i++) begin
      phase_buf[i] = 1;
      intensity_buf[i] = 1;
    end
    for (int i = 0; i < 255; i++) begin
      fork
        set();
        wait_calc();
      join
      check_manual(0, 0);
    end
    fork
      set();
      wait_calc();
    join
    check_manual(1, 1);

    silencer_settings.UPDATE_RATE_INTENSITY = 256;
    silencer_settings.UPDATE_RATE_PHASE = 256;

    for (int i = 0; i < DEPTH; i++) begin
      phase_buf[i] = 0;
      intensity_buf[i] = 0;
    end
    fork
      set();
      wait_calc();
    join
    check_manual(0, 0);

    for (int i = 0; i < DEPTH; i++) begin
      phase_buf[i] = 255;
      intensity_buf[i] = 255;
    end
    fork
      set();
      wait_calc();
    join
    check_manual(1, 255);

    silencer_settings.UPDATE_RATE_INTENSITY = 16'hFF00;
    silencer_settings.UPDATE_RATE_PHASE = 16'hFF00;
    for (int i = 0; i < DEPTH; i++) begin
      phase_buf[i] = 0;
      intensity_buf[i] = 0;
    end
    fork
      set();
      wait_calc();
    join
    check_manual(0, 0);

    // Full jump
    for (int i = 0; i < DEPTH; i++) begin
      phase_buf[i] = 128;
      intensity_buf[i] = 255;
    end
    fork
      set();
      wait_calc();
    join
    check_manual(255, 128);

    for (int i = 0; i < DEPTH; i++) begin
      phase_buf[i] = 0;
      intensity_buf[i] = 0;
    end
    fork
      set();
      wait_calc();
    join
    check_manual(0, 0);
    //////////////// Manual check ////////////////

    // from random to random with random step
    for (int i = 0; i < 30; i++) begin
      $display("Random test %d/30", i);
      silencer_settings.UPDATE_RATE_INTENSITY = sim_helper_random.range(16'hFFFF, 1);
      silencer_settings.UPDATE_RATE_PHASE = sim_helper_random.range(16'hFFFF, 1);
      n_repeat = silencer_settings.UPDATE_RATE_INTENSITY < silencer_settings.UPDATE_RATE_PHASE ?
                      int'(16'hFFFF / silencer_settings.UPDATE_RATE_INTENSITY) + 1 :
                      int'(16'hFFFF / silencer_settings.UPDATE_RATE_PHASE) + 1;
      for (int i = 0; i < DEPTH; i++) begin
        intensity_buf[i] = sim_helper_random.range(8'hFF, 0);
        phase_buf[i] = sim_helper_random.range(8'hFF, 0);
      end
      repeat (n_repeat) begin
        fork
          set();
          wait_calc();
        join
      end
      fork
        set();
        wait_calc();
        check();
      join
    end

    // disable
    silencer_settings.UPDATE_RATE_INTENSITY = 16'hFFFF;
    silencer_settings.UPDATE_RATE_PHASE = 16'hFFFF;
    n_repeat = 1;

    for (int i = 0; i < DEPTH; i++) begin
      intensity_buf[i] = sim_helper_random.range(8'hFF, 0);
      phase_buf[i] = sim_helper_random.range(8'hFF, 0);
    end
    repeat (n_repeat) begin
      fork
        set();
        wait_calc();
      join
    end
    fork
      set();
      wait_calc();
      check();
    join

    $display("Ok! sim_silencer_fixed_update_rate");
    $finish;
  end

endmodule
