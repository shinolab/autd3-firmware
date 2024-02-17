`timescale 1ns / 1ps
module main #(
    parameter int DEPTH = 249
) (
    input wire CLK,
    input wire CAT_SYNC0,
    memory_bus_if.bram_port MEM_BUS,
    input wire THERMO,
    output wire FORCE_FAN,
    output wire PWM_OUT[DEPTH],
    output wire GPIO_OUT[2]
);

  cnt_bus_if cnt_bus ();
  modulation_bus_if mod_bus ();
  stm_bus_if stm_bus ();
  duty_table_bus_if duty_table_bus ();

  settings::mod_settings_t mod_settings;
  settings::stm_settings_t stm_settings;
  settings::silencer_settings_t silencer_settings;
  settings::sync_settings_t sync_settings;
  settings::pulse_width_encoder_settings_t pulse_width_encoder_settings;
  settings::debug_settings_t debug_settings;

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

  logic stm_segment;
  logic mod_segment;
  logic [15:0] stm_cycle;

  memory memory (
      .CLK(CLK),
      .MEM_BUS(MEM_BUS),
      .CNT_BUS_IF(cnt_bus.in_port),
      .MOD_BUS(mod_bus.in_port),
      .STM_BUS(stm_bus.in_port),
      .DUTY_TABLE_BUS(duty_table_bus.in_port)
  );

  controller controller (
      .CLK(CLK),
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
      .CLK(CLK),
      .SYNC_SETTINGS(sync_settings),
      .ECAT_SYNC(CAT_SYNC0),
      .SYS_TIME(sys_time),
      .SYNC(),
      .SKIP_ONE_ASSERT(skip_one_assert)
  );

  time_cnt_generator #(
      .DEPTH(DEPTH)
  ) time_cnt_generator (
      .CLK(CLK),
      .SYS_TIME(sys_time),
      .SKIP_ONE_ASSERT(skip_one_assert),
      .TIME_CNT(time_cnt),
      .UPDATE(update)
  );

  stm #(
      .DEPTH(DEPTH)
  ) stm (
      .CLK(CLK),
      .SYS_TIME(sys_time),
      .UPDATE(update),
      .STM_SETTINGS(stm_settings),
      .STM_BUS(stm_bus.stm_port),
      .STM_BUS_FOCUS(stm_bus.out_focus_port),
      .STM_BUS_GAIN(stm_bus.out_gain_port),
      .INTENSITY(intensity),
      .PHASE(phase),
      .DOUT_VALID(dout_valid),
      .DEBUG_IDX(),
      .DEBUG_SEGMENT(stm_segment),
      .DEBUG_CYCLE(stm_cycle)
  );

  modulation #(
      .DEPTH(DEPTH)
  ) modulation (
      .CLK(CLK),
      .SYS_TIME(sys_time),
      .MOD_SETTINGS(mod_settings),
      .DIN_VALID(dout_valid),
      .INTENSITY_IN(intensity),
      .INTENSITY_OUT(intensity_m),
      .PHASE_IN(phase),
      .PHASE_OUT(phase_m),
      .DOUT_VALID(dout_valid_m),
      .MOD_BUS(mod_bus.out_port),
      .DEBUG_IDX(),
      .DEBUG_SEGMENT(mod_segment),
      .DEBUG_STOP()
  );

  silencer #(
      .DEPTH(DEPTH)
  ) silencer (
      .CLK(CLK),
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
      .CLK(CLK),
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
      .CLK(CLK),
      .TIME_CNT(time_cnt),
      .UPDATE(update),
      .DIN_VALID(dout_valid_e),
      .PULSE_WIDTH(pulse_width_e),
      .PHASE(phase_e),
      .PWM_OUT(PWM_OUT),
      .DOUT_VALID()
  );


  // DEBUG 
  logic gpio_out_0;
  logic gpio_out_1;

  assign GPIO_OUT[0] = gpio_out_0;
  assign GPIO_OUT[1] = gpio_out_1;

  always_ff @(posedge CLK) begin
    gpio_out_0 <= time_cnt < 9'd256;
    gpio_out_1 <= debug_settings.OUTPUT_IDX == 8'hFF ? 1'b0 : PWM_OUT[debug_settings.OUTPUT_IDX];
  end

endmodule
