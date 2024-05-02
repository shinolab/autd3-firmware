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
  clock_bus_if clock_bus ();
  sim_helper_clk sim_helper_clk (
      .MRCC_25P6M(),
      .CLK(CLK),
      .CLOCK_BUS(clock_bus.out_port),
      .LOCKED(locked),
      .SYS_TIME()
  );

  sim_helper_random sim_helper_random ();

  settings::silencer_settings_t silencer_settings;
  logic [15:0] intensity;
  logic [7:0] phase;
  logic [15:0] intensity_s;
  logic [7:0] phase_s;
  logic din_valid, dout_valid;

  logic [15:0] intensity_buf[DEPTH];
  logic [7:0] phase_buf[DEPTH];
  logic [15:0] intensity_s_buf[DEPTH];
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

  task automatic check_manual(logic [15:0] expect_intensity, logic [7:0] expect_phase);
    fork
      set();
      wait_calc();
    join
    `ASSERT_EQ(expect_phase, phase_s_buf[0]);
    `ASSERT_EQ(expect_intensity, intensity_s_buf[0]);
  endtask

  task automatic reset(logic [15:0] expect_intensity, logic [7:0] expect_phase);
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
    check_manual(81, 80);  //6
    check_manual(93, 92);  //7
    check_manual(105, 104);  //8
    check_manual(117, 116);  //9
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
    intensity_buf[0] = 1024;

    check_manual(102, 12);  //1
    check_manual(205, 25);  //2
    check_manual(308, 38);  //3
    check_manual(411, 51);  //4
    check_manual(514, 64);  //5
    check_manual(616, 76);  //6
    check_manual(718, 89);  //7
    check_manual(820, 102);  //8
    check_manual(922, 115);  //9
    for (int i = 0; i < 5; i++) begin
      check_manual(1024, 128);
    end
    $display("manual check 2 done");
    //////////////// Manual check 2 ////////////////

    //////////////// Manual check 3 ////////////////
    reset(0, 10);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 139;
    intensity_buf[0] = 1024;

    check_manual(102, 253);  //1
    check_manual(205, 240);  //2
    check_manual(308, 227);  //3
    check_manual(411, 215);  //4
    check_manual(514, 202);  //5
    check_manual(616, 189);  //6
    check_manual(718, 177);  //7
    check_manual(820, 164);  //8
    check_manual(922, 151);  //9
    for (int i = 0; i < 5; i++) begin
      check_manual(1024, 139);
    end
    $display("manual check 3 done");
    //////////////// Manual check 3 ////////////////

    //////////////// Manual check 4 ////////////////
    reset(0, 0);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE     = 10;
    phase_buf[0]                                 = 129;
    intensity_buf[0]                             = 1024;

    check_manual(102, 243);  //1
    check_manual(205, 230);  //2
    check_manual(308, 217);  //3
    check_manual(411, 205);  //4
    check_manual(514, 192);  //5
    check_manual(616, 179);  //6
    check_manual(718, 167);  //7
    check_manual(820, 154);  //8
    check_manual(922, 141);  //9
    for (int i = 0; i < 5; i++) begin
      check_manual(1024, 129);
    end
    $display("manual check 4 done");
    //////////////// Manual check 4 ////////////////

    //////////////// Manual check 5 ////////////////
    reset(0, 0);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 180;
    intensity_buf[0] = 1024;

    check_manual(102, 248);  //1
    check_manual(205, 240);  //2
    check_manual(308, 233);  //3
    check_manual(411, 225);  //4
    check_manual(514, 217);  //5
    check_manual(616, 210);  //6
    check_manual(718, 202);  //7
    check_manual(820, 195);  //8
    check_manual(922, 187);  //9
    for (int i = 0; i < 5; i++) begin
      check_manual(1024, 180);
    end
    $display("manual check 5 done");
    //////////////// Manual check 5 ////////////////

    //////////////// Manual check 6 ////////////////
    reset(1440, 180);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 128;
    intensity_buf[0] = 1024;

    check_manual(1399, 174);  //1
    check_manual(1357, 169);  //2
    check_manual(1315, 164);  //3
    check_manual(1273, 159);  //4
    check_manual(1231, 153);  //5
    check_manual(1189, 148);  //6
    check_manual(1147, 143);  //7
    check_manual(1106, 138);  //8
    check_manual(1065, 133);  //9
    for (int i = 0; i < 5; i++) begin
      check_manual(1024, 128);
    end
    $display("manual check 6 done");
    //////////////// Manual check 6 ////////////////

    //////////////// Manual check 7 ////////////////
    reset(1440, 255);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 180;
    intensity_buf[0] = 1024;

    check_manual(1399, 247);  //1
    check_manual(1357, 240);  //2
    check_manual(1315, 232);  //3
    check_manual(1273, 225);  //4
    check_manual(1231, 217);  //5
    check_manual(1189, 210);  //6
    check_manual(1147, 202);  //7
    check_manual(1106, 195);  //8
    check_manual(1065, 187);  //9
    for (int i = 0; i < 5; i++) begin
      check_manual(1024, 180);
    end
    $display("manual check 7 done");
    //////////////// Manual check 7 ////////////////

    //////////////// Manual check 8 ////////////////
    reset(1440, 255);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 126;
    intensity_buf[0] = 1024;

    check_manual(1399, 11);  //1
    check_manual(1357, 24);  //2
    check_manual(1315, 37);  //3
    check_manual(1273, 49);  //4
    check_manual(1231, 62);  //5
    check_manual(1189, 75);  //6
    check_manual(1147, 87);  //7
    check_manual(1106, 100);  //8
    check_manual(1065, 113);  //9
    for (int i = 0; i < 5; i++) begin
      check_manual(1024, 126);
    end
    $display("manual check 8 done");
    //////////////// Manual check 8 ////////////////

    //////////////// Manual check 9 ////////////////
    reset(1440, 255);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 127;
    intensity_buf[0] = 1024;

    check_manual(1399, 242);  //1
    check_manual(1357, 229);  //2
    check_manual(1315, 216);  //3
    check_manual(1273, 203);  //4
    check_manual(1231, 191);  //5
    check_manual(1189, 178);  //6
    check_manual(1147, 165);  //7
    check_manual(1106, 152);  //8
    check_manual(1065, 139);  //9
    for (int i = 0; i < 5; i++) begin
      check_manual(1024, 127);
    end
    $display("manual check 9 done");
    //////////////// Manual check 9 ////////////////

    //////////////// Manual check 10 ////////////////
    reset(1440, 255);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 10;
    intensity_buf[0] = 1024;

    check_manual(1399, 0);  //1
    check_manual(1357, 1);  //2
    check_manual(1315, 2);  //3
    check_manual(1273, 3);  //4
    check_manual(1231, 4);  //5
    check_manual(1189, 5);  //6
    check_manual(1147, 6);  //7
    check_manual(1106, 7);  //8
    check_manual(1065, 8);  //9
    for (int i = 0; i < 5; i++) begin
      check_manual(1024, 10);
    end
    $display("manual check 10 done");
    //////////////// Manual check 10 ////////////////

    //////////////// Manual check 11 ////////////////
    reset(1440, 180);

    silencer_settings.COMPLETION_STEPS_INTENSITY = 10;
    silencer_settings.COMPLETION_STEPS_PHASE = 10;
    phase_buf[0] = 0;
    intensity_buf[0] = 1024;

    check_manual(1399, 187);  //1
    check_manual(1357, 195);  //2
    check_manual(1315, 202);  //3
    check_manual(1273, 210);  //4
    check_manual(1231, 218);  //5
    check_manual(1189, 225);  //6
    check_manual(1147, 233);  //7
    check_manual(1106, 240);  //8
    check_manual(1065, 248);  //9
    for (int i = 0; i < 5; i++) begin
      check_manual(1024, 0);
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
    check_manual(2, 1);  //3
    check_manual(3, 2);  //4
    check_manual(4, 2);  //5
    check_manual(5, 3);  //6
    check_manual(5, 3);  //7
    check_manual(5, 4);  //8
    check_manual(5, 4);  //9
    for (int i = 0; i < 5; i++) begin
      check_manual(5, 5);
    end
    $display("manual check 12 done");
    //////////////// Manual check 12 ////////////////

    // from random to random with random step (small steps)
    for (int i = 0; i < 10; i++) begin
      $display("Random test %d/10", i + 1);
      n_repeat = sim_helper_random.range(255, 1);
      silencer_settings.COMPLETION_STEPS_INTENSITY = n_repeat;
      silencer_settings.COMPLETION_STEPS_PHASE = n_repeat;
      for (int i = 0; i < DEPTH; i++) begin
        intensity_buf[i] = sim_helper_random.range(255 * 255, 0);
        phase_buf[i] = sim_helper_random.range(255, 0);
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

    // from random to random with random step (large steps)
    for (int i = 0; i < 3; i++) begin
      $display("Random test %d/3", i + 1);
      n_repeat = sim_helper_random.range(255 * 255, 256);
      silencer_settings.COMPLETION_STEPS_INTENSITY = n_repeat;
      silencer_settings.COMPLETION_STEPS_PHASE = n_repeat;
      for (int i = 0; i < DEPTH; i++) begin
        intensity_buf[i] = sim_helper_random.range(255 * 255, 0);
        phase_buf[i] = sim_helper_random.range(255, 0);
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
