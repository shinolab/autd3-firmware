`timescale 1ns / 1ps
module sim_silencer_pwe_selector ();

  `include "define.vh"

  localparam int DEPTH = 249;
  localparam int TABLE_SIZE = 256;

  sim_helper_bram sim_helper_bram ();
  sim_helper_random sim_helper_random ();

  cnt_bus_if cnt_bus ();
  phase_corr_bus_if phase_corr_bus ();
  modulation_bus_if mod_bus ();
  stm_bus_if stm_bus ();
  pwe_table_bus_if pwe_table_bus ();

  logic CLK;
  logic locked;
  sim_helper_clk sim_helper_clk (
      .MRCC_25P6M(MRCC_25P6M),
      .CLK(CLK),
      .LOCKED(locked),
      .SYS_TIME()
  );

  memory memory (
      .CLK(CLK),
      .MRCC_25P6M(MRCC_25P6M),
      .MEM_BUS(sim_helper_bram.memory_bus.bram_port),
      .CNT_BUS(cnt_bus.in_port),
      .PHASE_CORR_BUS(phase_corr_bus.in_port),
      .MOD_BUS(mod_bus.in_port),
      .STM_BUS(stm_bus.in_port),
      .PWE_TABLE_BUS(pwe_table_bus.in_port)
  );

  settings::silencer_settings_t silencer_settings;
  logic [7:0] intensity;
  logic [7:0] phase;
  logic [7:0] pulse_width_e;
  logic [7:0] phase_e;
  logic din_valid, dout_valid;

  silencer_pwe_selector #(
      .DEPTH(DEPTH)
  ) silencer_pwe_selector (
      .CLK(CLK),
      .PWE_TABLE_BUS(pwe_table_bus.out_port),
      .SILENCER_SETTINGS(silencer_settings),
      .DIN_VALID(din_valid),
      .INTENSITY_IN(intensity),
      .PHASE_IN(phase),
      .PULSE_WIDTH_OUT(pulse_width_e),
      .PHASE_OUT(phase_e),
      .DOUT_VALID(dout_valid)
  );

  logic [7:0] pwe_table[TABLE_SIZE];

  logic [7:0] intensity_buf[DEPTH];
  logic [7:0] phase_buf[DEPTH];
  logic [7:0] pulse_width_e_buf[DEPTH];
  logic [7:0] phase_e_buf[DEPTH];

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
      pulse_width_e_buf[i] = pulse_width_e;
      phase_e_buf[i] = phase_e;
      @(posedge CLK);
    end
  endtask

  task automatic check_manual(logic [7:0] expect_pulse_width, logic [7:0] expect_phase);
    fork
      set();
      wait_calc();
    join
    `ASSERT_EQ(expect_phase, phase_e_buf[0]);
    `ASSERT_EQ(expect_pulse_width, pulse_width_e_buf[0]);
  endtask

  task automatic reset(logic [7:0] expect_pulse_width, logic [7:0] expect_phase);
    silencer_settings.UPDATE_RATE_INTENSITY = 8'hFF;
    silencer_settings.UPDATE_RATE_PHASE = 8'hFF;
    phase_buf[0] = expect_phase;
    intensity_buf[0] = expect_pulse_width;
    check_manual(2 * expect_pulse_width, expect_phase);
  endtask

  task automatic check_intensity_mode();
    silencer_settings.FLAG = (0 << params::SILENCER_FLAG_BIT_PULSE_WIDTH) | (1 << params::SILENCER_FLAG_BIT_FIXED_UPDATE_RATE_MODE);

    //////////////// Manual check 1 ////////////////
    reset(0, 0);

    silencer_settings.UPDATE_RATE_INTENSITY = 1;
    silencer_settings.UPDATE_RATE_PHASE     = 1;
    phase_buf[0]                            = 10;
    intensity_buf[0]                        = 10;

    check_manual(2 * 1, 1);
    check_manual(2 * 2, 2);
    check_manual(2 * 3, 3);
    check_manual(2 * 4, 4);
    check_manual(2 * 5, 5);
    check_manual(2 * 6, 6);
    check_manual(2 * 7, 7);
    check_manual(2 * 8, 8);
    check_manual(2 * 9, 9);
    for (int i = 0; i < 5; i++) begin
      check_manual(2 * 10, 10);
    end
    $display("manual check intensity 1 done");
    //////////////// Manual check 1 ////////////////

    //////////////// Manual check 2 ////////////////
    reset(0, 0);

    silencer_settings.UPDATE_RATE_INTENSITY = 10;
    silencer_settings.UPDATE_RATE_PHASE     = 10;
    phase_buf[0]                            = 100;
    intensity_buf[0]                        = 100;

    check_manual(2 * 10, 10);  //1
    check_manual(2 * 20, 20);  //2
    check_manual(2 * 30, 30);  //3
    check_manual(2 * 40, 40);  //4
    check_manual(2 * 50, 50);  //5
    check_manual(2 * 60, 60);  //6
    check_manual(2 * 70, 70);  //7
    check_manual(2 * 80, 80);  //8
    check_manual(2 * 90, 90);  //9
    for (int i = 0; i < 5; i++) begin
      check_manual(2 * 100, 100);
    end
    $display("manual check intensity 2 done");
    //////////////// Manual check 2 ////////////////
  endtask

  task automatic check_pulse_width_mode();
    silencer_settings.FLAG = (1 << params::SILENCER_FLAG_BIT_PULSE_WIDTH) | (1 << params::SILENCER_FLAG_BIT_FIXED_UPDATE_RATE_MODE);

    //////////////// Manual check 1 ////////////////
    reset(0, 0);

    silencer_settings.UPDATE_RATE_INTENSITY = 1;
    silencer_settings.UPDATE_RATE_PHASE     = 1;
    phase_buf[0]                            = 10;
    intensity_buf[0]                        = 5;

    check_manual(1, 1);
    check_manual(2, 2);
    check_manual(3, 3);
    check_manual(4, 4);
    check_manual(5, 5);
    check_manual(6, 6);
    check_manual(7, 7);
    check_manual(8, 8);
    check_manual(9, 9);
    for (int i = 0; i < 5; i++) begin
      check_manual(10, 10);
    end
    $display("manual check pulse_width 1 done");
    //////////////// Manual check 1 ////////////////

    //////////////// Manual check 2 ////////////////
    reset(0, 0);

    silencer_settings.UPDATE_RATE_INTENSITY = 10;
    silencer_settings.UPDATE_RATE_PHASE     = 10;
    phase_buf[0]                            = 100;
    intensity_buf[0]                        = 50;

    check_manual(10, 10);  //1
    check_manual(20, 20);  //2
    check_manual(30, 30);  //3
    check_manual(40, 40);  //4
    check_manual(50, 50);  //5
    check_manual(60, 60);  //6
    check_manual(70, 70);  //7
    check_manual(80, 80);  //8
    check_manual(90, 90);  //9
    for (int i = 0; i < 5; i++) begin
      check_manual(100, 100);
    end
    $display("manual check pulse_width 2 done");
    //////////////// Manual check 2 ////////////////
  endtask

  initial begin
    din_valid = 0;
    phase = 0;
    intensity = 0;
    for (int i = 0; i < DEPTH; i++) begin
      phase_buf[i] = 0;
      intensity_buf[i] = 0;
    end
    sim_helper_random.init();

    @(posedge locked);

    // To make debugging easier
    for (int i = 0; i < TABLE_SIZE; i++) begin
      pwe_table[i] = 2 * i;
    end
    sim_helper_bram.write_pwe_table(pwe_table);

    check_intensity_mode();
    check_pulse_width_mode();

    $display("Ok! sim_silencer_pwe_selector");
    $finish;
  end

endmodule
