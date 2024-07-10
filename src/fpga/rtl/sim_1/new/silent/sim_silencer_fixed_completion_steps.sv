`timescale 1ns / 1ps
module sim_silencer_fixed_completion_steps ();

  `define ASSERT_EQ(expected, actual) \
  if (expected !== actual) begin \
    $error("%s:%d: expected is %s, but actual is %s", `__FILE__, `__LINE__, $sformatf("%0d", expected), $sformatf("%0d", actual));\
    $finish();\
  end

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

  task automatic reset(logic [7:0] expect_intensity, logic [7:0] expect_phase);
    silencer_settings.COMPLETION_STEPS_INTENSITY = 1;
    silencer_settings.COMPLETION_STEPS_PHASE = 1;
    phase_buf[0] = expect_phase;
    intensity_buf[0] = expect_intensity;
    check_manual(expect_intensity, expect_phase);
  endtask

  int n_repeat;
  initial begin
    silencer_settings.MODE = params::SILENCER_MODE_FIXED_COMPLETION_STEPS;

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

    check_manual(21, 21);  //1
    check_manual(33, 33);  //2
    check_manual(45, 45);  //3
    check_manual(57, 57);  //4
    check_manual(69, 69);  //5
    check_manual(81, 81);  //6
    check_manual(93, 93);  //7
    check_manual(105, 105);  //8
    check_manual(117, 117);  //9
    for (int i = 0; i < 5; i++) begin
      check_manual(128, 128);
    end
    $display("manual check 1 done");
    //////////////// Manual check 1 ////////////////

    //////////////// Manual check 2 ////////////////
    reset(0, 0);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 128;
    intensity_buf[0] = 255;

    check_manual(25, 12);  //1
    check_manual(51, 25);  //2
    check_manual(77, 38);  //3
    check_manual(103, 51);  //4
    check_manual(129, 64);  //5
    check_manual(155, 77);  //6
    check_manual(180, 90);  //7
    check_manual(205, 103);  //8
    check_manual(230, 116);  //9
    for (int i = 0; i < 5; i++) begin
      check_manual(255, 128);
    end
    $display("manual check 2 done");
    //////////////// Manual check 2 ////////////////

    //////////////// Manual check 3 ////////////////
    reset(0, 10);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 139;
    intensity_buf[0] = 255;

    check_manual(25, 254);  //1
    check_manual(51, 241);  //2
    check_manual(77, 228);  //3
    check_manual(103, 215);  //4
    check_manual(129, 202);  //5
    check_manual(155, 189);  //6
    check_manual(180, 176);  //7
    check_manual(205, 163);  //8
    check_manual(230, 151);  //9
    for (int i = 0; i < 5; i++) begin
      check_manual(255, 139);
    end
    $display("manual check 3 done");
    //////////////// Manual check 3 ////////////////

    //////////////// Manual check 4 ////////////////
    reset(0, 0);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE     = 10;
    phase_buf[0]                                 = 129;
    intensity_buf[0]                             = 255;

    check_manual(25, 244);  //1
    check_manual(51, 231);  //2
    check_manual(77, 218);  //3
    check_manual(103, 205);  //4
    check_manual(129, 192);  //5
    check_manual(155, 179);  //6
    check_manual(180, 166);  //7
    check_manual(205, 153);  //8
    check_manual(230, 141);  //9
    for (int i = 0; i < 5; i++) begin
      check_manual(255, 129);
    end
    $display("manual check 4 done");
    //////////////// Manual check 4 ////////////////

    //////////////// Manual check 5 ////////////////
    reset(0, 0);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 180;
    intensity_buf[0] = 255;

    check_manual(25, 249);  //1
    check_manual(51, 241);  //2
    check_manual(77, 233);  //3
    check_manual(103, 225);  //4
    check_manual(129, 217);  //5
    check_manual(155, 209);  //6
    check_manual(180, 201);  //7
    check_manual(205, 194);  //8
    check_manual(230, 187);  //9
    for (int i = 0; i < 5; i++) begin
      check_manual(255, 180);
    end
    $display("manual check 5 done");
    //////////////// Manual check 5 ////////////////

    //////////////// Manual check 6 ////////////////
    reset(255, 180);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 128;
    intensity_buf[0] = 245;

    check_manual(254, 175);  //1
    check_manual(253, 169);  //2
    check_manual(252, 163);  //3
    check_manual(251, 158);  //4
    check_manual(250, 153);  //5
    check_manual(249, 148);  //6
    check_manual(248, 143);  //7
    check_manual(247, 138);  //8
    check_manual(246, 133);  //9
    for (int i = 0; i < 5; i++) begin
      check_manual(245, 128);
    end
    $display("manual check 6 done");
    //////////////// Manual check 6 ////////////////

    //////////////// Manual check 7 ////////////////
    reset(255, 255);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 180;
    intensity_buf[0] = 245;

    check_manual(254, 248);  //1
    check_manual(253, 240);  //2
    check_manual(252, 232);  //3
    check_manual(251, 224);  //4
    check_manual(250, 216);  //5
    check_manual(249, 208);  //6
    check_manual(248, 201);  //7
    check_manual(247, 194);  //8
    check_manual(246, 187);  //9
    for (int i = 0; i < 5; i++) begin
      check_manual(245, 180);
    end
    $display("manual check 7 done");
    //////////////// Manual check 7 ////////////////

    //////////////// Manual check 8 ////////////////
    reset(255, 255);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 126;
    intensity_buf[0] = 245;

    check_manual(254, 11);  //1
    check_manual(253, 24);  //2
    check_manual(252, 37);  //3
    check_manual(251, 50);  //4
    check_manual(250, 63);  //5
    check_manual(249, 76);  //6
    check_manual(248, 89);  //7
    check_manual(247, 102);  //8
    check_manual(246, 114);  //9
    for (int i = 0; i < 5; i++) begin
      check_manual(245, 126);
    end
    $display("manual check 8 done");
    //////////////// Manual check 8 ////////////////

    //////////////// Manual check 9 ////////////////
    reset(255, 255);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 127;
    intensity_buf[0] = 245;

    check_manual(254, 243);  //1
    check_manual(253, 230);  //2
    check_manual(252, 217);  //3
    check_manual(251, 204);  //4
    check_manual(250, 191);  //5
    check_manual(249, 178);  //6
    check_manual(248, 165);  //7
    check_manual(247, 152);  //8
    check_manual(246, 139);  //9
    for (int i = 0; i < 5; i++) begin
      check_manual(245, 127);
    end
    $display("manual check 9 done");
    //////////////// Manual check 9 ////////////////

    //////////////// Manual check 10 ////////////////
    reset(255, 255);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 10;
    intensity_buf[0] = 245;

    check_manual(254, 0);  //1
    check_manual(253, 2);  //2
    check_manual(252, 3);  //3
    check_manual(251, 4);  //4
    check_manual(250, 5);  //5
    check_manual(249, 6);  //6
    check_manual(248, 7);  //7
    check_manual(247, 8);  //8
    check_manual(246, 9);  //9
    for (int i = 0; i < 5; i++) begin
      check_manual(245, 10);
    end
    $display("manual check 10 done");
    //////////////// Manual check 10 ////////////////

    //////////////// Manual check 11 ////////////////
    reset(255, 180);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 0;
    intensity_buf[0] = 245;

    check_manual(254, 187);  //1
    check_manual(253, 195);  //2
    check_manual(252, 203);  //3
    check_manual(251, 211);  //4
    check_manual(250, 219);  //5
    check_manual(249, 227);  //6
    check_manual(248, 235);  //7
    check_manual(247, 242);  //8
    check_manual(246, 249);  //9
    for (int i = 0; i < 5; i++) begin
      check_manual(245, 0);
    end
    $display("manual check 11 done");
    //////////////// Manual check 11 ////////////////

    //////////////// Manual check 12 ////////////////
    reset(0, 0);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 5;
    intensity_buf[0] = 5;

    check_manual(0, 0);  //1
    check_manual(1, 1);  //2
    check_manual(2, 2);  //3
    check_manual(3, 3);  //4
    check_manual(4, 4);  //5
    check_manual(5, 5);  //6
    check_manual(5, 5);  //7
    check_manual(5, 5);  //8
    check_manual(5, 5);  //9
    for (int i = 0; i < 5; i++) begin
      check_manual(5, 5);
    end
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
