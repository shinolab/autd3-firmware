`timescale 1ns / 1ps
module sim_silencer_fixed_completion_steps ();

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

  task automatic set();
    for (int i = 0; i < DEPTH; i++) begin
      @(posedge CLK);
      din_valid <= 1'b1;
      intensity <= intensity_buf[i];
      phase <= phase_buf[i];
    end
    @(posedge CLK);
    din_valid <= 1'b0;
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
    fork
      set();
      wait_calc();
    join
    `ASSERT_EQ(expect_phase, phase_s_buf[0]);
    `ASSERT_EQ(expect_intensity, intensity_s_buf[0]);
  endtask

  task automatic check_manual_seq(logic [7:0] expect_intensity[], logic [7:0] expect_phase[],
                                  int n);
    for (int i = 0; i < n; i++) begin
      check_manual(expect_intensity[i], expect_phase[i]);
    end
  endtask

  task automatic reset(logic [7:0] expect_intensity, logic [7:0] expect_phase);
    silencer_settings.COMPLETION_STEPS_INTENSITY = 1;
    silencer_settings.COMPLETION_STEPS_PHASE = 1;
    phase_buf[0] = expect_phase;
    intensity_buf[0] = expect_intensity;
    check_manual(expect_intensity, expect_phase);
  endtask

  int n_repeat;
  initial begin
    silencer_settings.FLAG = 0 << params::SILENCER_FLAG_BIT_FIXED_UPDATE_RATE_MODE;

    din_valid = 0;
    phase = 0;
    intensity = 0;
    for (int i = 0; i < DEPTH; i++) begin
      phase_buf[i] = 0;
      intensity_buf[i] = 0;
    end
    sim_helper_random.init();

    @(posedge locked);

    //////////////// Manual check 1 ////////////////
    reset(10, 10);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE     = 10;
    phase_buf[0]                                 = 128;
    intensity_buf[0]                             = 128;
    check_manual_seq({21, 33, 45, 57, 69, 80, 92, 104, 116, 128, 128}, {
                     21, 33, 45, 57, 69, 80, 92, 104, 116, 128, 128}, 11);
    $display("manual check 1 done");
    //////////////// Manual check 1 ////////////////

    //////////////// Manual check 2 ////////////////
    reset(0, 0);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 128;
    intensity_buf[0] = 255;
    check_manual_seq({25, 51, 76, 102, 127, 153, 178, 204, 229, 255, 255}, {
                     12, 25, 38, 51, 64, 76, 89, 102, 115, 128, 128}, 11);
    $display("manual check 2 done");
    //////////////// Manual check 2 ////////////////

    //////////////// Manual check 3 ////////////////
    reset(0, 10);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 139;
    intensity_buf[0] = 255;
    check_manual_seq({25, 51, 76, 102, 127, 153, 178, 204, 229, 255, 255}, {
                     253, 240, 227, 215, 202, 189, 177, 164, 151, 139, 139}, 11);
    $display("manual check 3 done");
    //////////////// Manual check 3 ////////////////

    //////////////// Manual check 4 ////////////////
    reset(0, 0);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE     = 10;
    phase_buf[0]                                 = 129;
    intensity_buf[0]                             = 255;
    check_manual_seq({25, 51, 76, 102, 127, 153, 178, 204, 229, 255, 255}, {
                     243, 230, 217, 205, 192, 179, 167, 154, 141, 129, 129}, 11);
    $display("manual check 4 done");
    //////////////// Manual check 4 ////////////////

    //////////////// Manual check 5 ////////////////
    reset(0, 0);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 180;
    intensity_buf[0] = 255;
    check_manual_seq({25, 51, 76, 102, 127, 153, 178, 204, 229, 255, 255}, {
                     248, 240, 233, 225, 217, 210, 202, 195, 187, 180, 180}, 11);
    $display("manual check 5 done");
    //////////////// Manual check 5 ////////////////

    //////////////// Manual check 6 ////////////////
    reset(255, 180);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 128;
    intensity_buf[0] = 245;
    check_manual_seq({254, 253, 252, 251, 250, 249, 248, 247, 246, 245, 245}, {
                     174, 169, 164, 159, 153, 148, 143, 138, 133, 128, 128}, 11);
    $display("manual check 6 done");
    //////////////// Manual check 6 ////////////////

    //////////////// Manual check 7 ////////////////
    reset(255, 255);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 180;
    intensity_buf[0] = 245;
    check_manual_seq({254, 253, 252, 251, 250, 249, 248, 247, 246, 245, 245}, {
                     247, 240, 232, 225, 217, 210, 202, 195, 187, 180, 180}, 11);
    $display("manual check 7 done");
    //////////////// Manual check 7 ////////////////

    //////////////// Manual check 8 ////////////////
    reset(255, 255);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 126;
    intensity_buf[0] = 245;
    check_manual_seq({254, 253, 252, 251, 250, 249, 248, 247, 246, 245, 245}, {
                     11, 24, 37, 49, 62, 75, 87, 100, 113, 126, 126}, 11);
    $display("manual check 8 done");
    //////////////// Manual check 8 ////////////////

    //////////////// Manual check 9 ////////////////
    reset(255, 255);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 127;
    intensity_buf[0] = 245;
    check_manual_seq({254, 253, 252, 251, 250, 249, 248, 247, 246, 245, 245}, {
                     242, 229, 216, 203, 191, 178, 165, 152, 139, 127, 127}, 11);
    $display("manual check 9 done");
    //////////////// Manual check 9 ////////////////

    //////////////// Manual check 10 ////////////////
    reset(255, 255);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 10;
    intensity_buf[0] = 245;
    check_manual_seq({254, 253, 252, 251, 250, 249, 248, 247, 246, 245, 245}, {
                     0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 10}, 11);
    $display("manual check 10 done");
    //////////////// Manual check 10 ////////////////

    //////////////// Manual check 11 ////////////////
    reset(255, 180);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 0;
    intensity_buf[0] = 245;
    check_manual_seq({254, 253, 252, 251, 250, 249, 248, 247, 246, 245, 245}, {
                     187, 195, 202, 210, 218, 225, 233, 240, 248, 0, 0}, 11);
    $display("manual check 11 done");
    //////////////// Manual check 11 ////////////////

    //////////////// Manual check 12 ////////////////
    reset(0, 0);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 5;
    intensity_buf[0] = 5;
    check_manual_seq({0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5}, {0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5}, 11);
    $display("manual check 12 done");
    //////////////// Manual check 12 ////////////////

    // from random to random with random step
    for (int i = 0; i < 30; i++) begin
      $display("Random test %d/30", i + 1);
      n_repeat = sim_helper_random.range(8'hFF, 1);
      silencer_settings.COMPLETION_STEPS_INTENSITY = n_repeat;
      silencer_settings.COMPLETION_STEPS_PHASE = n_repeat;
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
      for (int i = 0; i < DEPTH; i++) begin
        `ASSERT_EQ(phase_buf[i], phase_s_buf[i]);
        `ASSERT_EQ(intensity_buf[i], intensity_s_buf[i]);
      end
    end

    $display("Ok! sim_silencer_fixed_completion_steps");
    $finish;
  end

endmodule
