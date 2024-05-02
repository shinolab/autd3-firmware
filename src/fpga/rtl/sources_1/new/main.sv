`timescale 1ns / 1ps
module main #(
    parameter int DEPTH = 249
) (
    input wire MRCC_25P6M,
    input wire RESET,
    input wire CAT_SYNC0,
    memory_bus_if.bram_port MEM_BUS,
    input wire THERMO,
    output wire FORCE_FAN,
    output wire PWM_OUT[DEPTH],
    input wire GPIO_IN[4],
    output wire GPIO_OUT[4]
);

  clock_bus_if clock_bus ();
  cnt_bus_if cnt_bus ();
  modulation_bus_if mod_bus ();
  stm_bus_if stm_bus ();
  duty_table_bus_if duty_table_bus ();
  filter_bus_if filter_bus ();

  settings::mod_settings_t mod_settings;
  settings::stm_settings_t stm_settings;
  settings::silencer_settings_t silencer_settings;
  settings::sync_settings_t sync_settings;
  settings::pulse_width_encoder_settings_t pulse_width_encoder_settings;
  settings::debug_settings_t debug_settings;

  logic clk;

  logic [63:0] sys_time;
  logic skip_one_assert;

  logic [8:0] time_cnt;
  logic update;

  logic [7:0] intensity;
  logic [7:0] phase;
  logic dout_valid;

  logic [15:0] intensity_m;
  logic [7:0] phase_m;
  logic dout_valid_m;

  logic [15:0] intensity_s;
  logic [7:0] phase_s;
  logic dout_valid_s;

  logic [8:0] pulse_width_e;
  logic [7:0] phase_e;
  logic dout_valid_e;

  logic [15:0] stm_idx;
  logic stm_segment;
  logic [15:0] stm_cycle;
  logic mod_segment;
  logic [14:0] mod_idx;

  memory memory (
      .MRCC_25P6M(MRCC_25P6M),
      .CLK(clk),
      .MEM_BUS(MEM_BUS),
      .CLOCKING_BUS(clocking_bus.in_port),
      .CNT_BUS(cnt_bus.in_port),
      .MOD_BUS(mod_bus.in_port),
      .STM_BUS(stm_bus.in_port),
      .DUTY_TABLE_BUS(duty_table_bus.in_port),
      .FILTER_BUS(filter_bus.in_port)
  );

  clock clock (
      .MRCC_25P6M(MRCC_25P6M),
      .CLOCKING_BUS(clocking_bus.out_port),
      .CLK(clk),
      .LOCKED()
  );

  controller controller (
      .CLK(clk),
      .THERMO(THERMO),
      .STM_SEGMENT(stm_segment),
      .MOD_SEGMENT(mod_segment),
      .STM_CYCLE(stm_cycle),
      .cnt_bus(cnt_bus.out_port),
      .MOD_SETTINGS(mod_settings),
      .STM_SETTINGS(stm_settings),
      .SILENCER_SETTINGS(silencer_settings),
      .SYNC_SETTINGS(sync_settings),
      .PULSE_WIDTH_ENCODER_SETTINGS(pulse_width_encoder_settings),
      .DEBUG_SETTINGS(debug_settings),
      .FORCE_FAN(FORCE_FAN)
  );

  synchronizer synchronizer (
      .CLK(clk),
      .SYNC_SETTINGS(sync_settings),
      .ECAT_SYNC(CAT_SYNC0),
      .SYS_TIME(sys_time),
      .SYNC(sync),
      .SKIP_ONE_ASSERT(skip_one_assert)
  );

  time_cnt_generator #(
      .DEPTH(DEPTH)
  ) time_cnt_generator (
      .CLK(clk),
      .SYS_TIME(sys_time),
      .SKIP_ONE_ASSERT(skip_one_assert),
      .TIME_CNT(time_cnt),
      .UPDATE(update)
  );

  stm #(
      .DEPTH(DEPTH)
  ) stm (
      .CLK(clk),
      .SYS_TIME(sys_time),
      .UPDATE(update),
      .STM_SETTINGS(stm_settings),
      .STM_BUS(stm_bus.stm_port),
      .STM_BUS_FOCUS(stm_bus.out_focus_port),
      .STM_BUS_GAIN(stm_bus.out_gain_port),
      .INTENSITY(intensity),
      .PHASE(phase),
      .GPIO_IN(GPIO_IN),
      .DOUT_VALID(dout_valid),
      .DEBUG_IDX(stm_idx),
      .DEBUG_SEGMENT(stm_segment),
      .DEBUG_CYCLE(stm_cycle)
  );

  modulation #(
      .DEPTH(DEPTH)
  ) modulation (
      .CLK(clk),
      .SYS_TIME(sys_time),
      .MOD_SETTINGS(mod_settings),
      .DIN_VALID(dout_valid),
      .INTENSITY_IN(intensity),
      .INTENSITY_OUT(intensity_m),
      .PHASE_IN(phase),
      .PHASE_OUT(phase_m),
      .DOUT_VALID(dout_valid_m),
      .MOD_BUS(mod_bus.out_port),
      .FILTER_BUS(filter_bus.out_port),
      .GPIO_IN(GPIO_IN),
      .DEBUG_IDX(mod_idx),
      .DEBUG_SEGMENT(mod_segment),
      .DEBUG_STOP()
  );

  silencer #(
      .DEPTH(DEPTH)
  ) silencer (
      .CLK(clk),
      .DIN_VALID(dout_valid_m),
      .SILENCER_SETTINGS(silencer_settings),
      .INTENSITY_IN(intensity_m),
      .PHASE_IN(phase_m),
      .INTENSITY_OUT(intensity_s),
      .PHASE_OUT(phase_s),
      .DOUT_VALID(dout_valid_s)
  );

  pulse_width_encoder #(
      .DEPTH(DEPTH)
  ) pulse_width_encoder (
      .CLK(clk),
      .DUTY_TABLE_BUS(duty_table_bus.out_port),
      .PULSE_WIDTH_ENCODER_SETTINGS(pulse_width_encoder_settings),
      .DIN_VALID(dout_valid_s),
      .INTENSITY_IN(intensity_s),
      .PHASE_IN(phase_s),
      .PULSE_WIDTH_OUT(pulse_width_e),
      .PHASE_OUT(phase_e),
      .DOUT_VALID(dout_valid_e)
  );

  pwm #(
      .DEPTH(DEPTH)
  ) pwm (
      .CLK(clk),
      .TIME_CNT(time_cnt),
      .UPDATE(update),
      .DIN_VALID(dout_valid_e),
      .PULSE_WIDTH(pulse_width_e),
      .PHASE(phase_e),
      .PWM_OUT(PWM_OUT),
      .DOUT_VALID()
  );

  debug #(
      .DEPTH(DEPTH)
  ) debug (
      .CLK(clk),
      .DEBUG_SETTINGS(debug_settings),
      .TIME_CNT(time_cnt),
      .PWM_OUT(PWM_OUT),
      .THERMO(THERMO),
      .FORCE_FAN(FORCE_FAN),
      .SYNC(sync),
      .STM_SEGMENT(stm_segment),
      .MOD_SEGMENT(mod_segment),
      .STM_IDX(stm_idx),
      .MOD_IDX(mod_idx),
      .STM_CYCLE(stm_cycle),
      .GPIO_OUT(GPIO_OUT)
  );

endmodule
