`timescale 1ns / 1ps
module sim_controller ();

  `include "define.vh"

  localparam int DEPTH = 249;

  logic CLK;
  logic locked;

  sim_helper_random sim_helper_random ();
  sim_helper_bram #(.DEPTH(DEPTH)) sim_helper_bram ();

  cnt_bus_if cnt_bus ();
  phase_corr_bus_if phase_corr_bus ();
  modulation_bus_if mod_bus ();
  stm_bus_if stm_bus ();
  pwe_table_bus_if pwe_table_bus ();

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

  sim_helper_clk sim_helper_clk (
      .MRCC_25P6M(MRCC_25P6M),
      .CLK(CLK),
      .LOCKED(locked),
      .SYS_TIME()
  );

  logic thermo;
  settings::mod_settings_t mod_settings;
  settings::stm_settings_t stm_settings;
  settings::silencer_settings_t silencer_settings;
  settings::sync_settings_t sync_settings;
  settings::debug_settings_t debug_settings;
  logic FORCE_FAN;

  controller controller (
      .CLK(CLK),
      .THERMO(thermo),
      .cnt_bus(cnt_bus.out_port),
      .MOD_SETTINGS(mod_settings),
      .STM_SETTINGS(stm_settings),
      .SILENCER_SETTINGS(silencer_settings),
      .SYNC_SETTINGS(sync_settings),
      .DEBUG_SETTINGS(debug_settings),
      .FORCE_FAN(FORCE_FAN)
  );

  settings::mod_settings_t mod_settings_in;
  settings::stm_settings_t stm_settings_in;
  settings::silencer_settings_t silencer_settings_in;
  settings::sync_settings_t sync_settings_in;
  settings::debug_settings_t debug_settings_in;

  initial begin
    sim_helper_random.init();

    mod_settings_in.UPDATE = 1'b1;
    mod_settings_in.REQ_RD_SEGMENT = sim_helper_random.range(1'b1, 0);
    mod_settings_in.TRANSITION_MODE = sim_helper_random.range(8'hFF, 0);
    mod_settings_in.TRANSITION_VALUE = sim_helper_random.range(64'hFFFFFFFFFFFFFFFF, 0);
    mod_settings_in.CYCLE[0] = sim_helper_random.range(16'hFFFF, 0);
    mod_settings_in.CYCLE[1] = sim_helper_random.range(16'hFFFF, 0);
    mod_settings_in.FREQ_DIV[0] = sim_helper_random.range(16'hFFFF, 0);
    mod_settings_in.FREQ_DIV[1] = sim_helper_random.range(16'hFFFF, 0);
    mod_settings_in.REP[0] = sim_helper_random.range(16'hFFFF, 0);
    mod_settings_in.REP[1] = sim_helper_random.range(16'hFFFF, 0);

    stm_settings_in.UPDATE = 1'b1;
    stm_settings_in.REQ_RD_SEGMENT = sim_helper_random.range(1'b1, 0);
    stm_settings_in.TRANSITION_MODE = sim_helper_random.range(8'hFF, 0);
    stm_settings_in.TRANSITION_VALUE = sim_helper_random.range(64'hFFFFFFFFFFFFFFFF, 0);
    stm_settings_in.MODE[0] = sim_helper_random.range(1'b1, 0);
    stm_settings_in.MODE[1] = sim_helper_random.range(1'b1, 0);
    stm_settings_in.CYCLE[0] = sim_helper_random.range(16'hFFFF, 0);
    stm_settings_in.CYCLE[1] = sim_helper_random.range(16'hFFFF, 0);
    stm_settings_in.FREQ_DIV[0] = sim_helper_random.range(16'hFFFF, 0);
    stm_settings_in.FREQ_DIV[1] = sim_helper_random.range(16'hFFFF, 0);
    stm_settings_in.REP[0] = sim_helper_random.range(16'hFFFF, 0);
    stm_settings_in.REP[1] = sim_helper_random.range(16'hFFFF, 0);
    stm_settings_in.SOUND_SPEED[0] = sim_helper_random.range(16'hFFFF, 0);
    stm_settings_in.SOUND_SPEED[1] = sim_helper_random.range(16'hFFFF, 0);
    stm_settings_in.NUM_FOCI[0] = sim_helper_random.range(8'd8, 0);
    stm_settings_in.NUM_FOCI[1] = sim_helper_random.range(8'd8, 0);

    silencer_settings_in.UPDATE = 1'b1;
    silencer_settings_in.FLAG = sim_helper_random.range(8'hFF, 0);
    silencer_settings_in.UPDATE_RATE_INTENSITY = sim_helper_random.range(8'hFF, 0);
    silencer_settings_in.UPDATE_RATE_PHASE = sim_helper_random.range(8'hFF, 0);
    silencer_settings_in.COMPLETION_STEPS_INTENSITY = sim_helper_random.range(8'hFF, 0);
    silencer_settings_in.COMPLETION_STEPS_PHASE = sim_helper_random.range(8'hFF, 0);

    sync_settings_in.UPDATE = 1'b1;
    sync_settings_in.ECAT_SYNC_TIME = sim_helper_random.range(64'hFFFFFFFFFFFFFFFF, 0);

    debug_settings_in.UPDATE = 1'b1;
    debug_settings_in.VALUE[0] = sim_helper_random.range(64'hFFFF, 0);
    debug_settings_in.VALUE[1] = sim_helper_random.range(64'hFFFF, 0);
    debug_settings_in.VALUE[2] = sim_helper_random.range(64'hFFFF, 0);
    debug_settings_in.VALUE[3] = sim_helper_random.range(64'hFFFF, 0);

    @(posedge locked);

    sim_helper_bram.write_mod_settings(mod_settings_in);
    sim_helper_bram.write_stm_settings(stm_settings_in);
    sim_helper_bram.write_silencer_settings(silencer_settings_in);
    sim_helper_bram.write_sync_settings(sync_settings_in);
    sim_helper_bram.write_debug_settings(debug_settings_in);
    $display("memory initialized");

    sim_helper_bram.bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_CTL_FLAG,
                               (16'd1 << params::CTL_FLAG_BIT_MOD_SET)
                               | (16'd1 << params::CTL_FLAG_BIT_STM_SET)
                               | (16'd1 << params::CTL_FLAG_BIT_SILENCER_SET)
                               | (16'd1 << params::CTL_FLAG_BIT_DEBUG_SET)
                               | (16'd1 << params::CTL_FLAG_BIT_SYNC_SET));
    @(posedge mod_settings.UPDATE);
    `ASSERT_EQ(mod_settings_in, mod_settings);

    @(posedge stm_settings.UPDATE);
    `ASSERT_EQ(stm_settings_in, stm_settings);

    @(posedge silencer_settings.UPDATE);
    `ASSERT_EQ(silencer_settings_in, silencer_settings);

    @(posedge debug_settings.UPDATE);
    `ASSERT_EQ(debug_settings_in, debug_settings);

    @(posedge sync_settings.UPDATE);
    `ASSERT_EQ(sync_settings_in, sync_settings);

    $display("OK! sim_controller");
    $finish();
  end

endmodule
