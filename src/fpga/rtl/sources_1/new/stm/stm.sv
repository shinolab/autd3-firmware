`timescale 1ns / 1ps
module stm #(
    parameter int DEPTH = 249
) (
    input wire CLK,
    input wire [63:0] SYS_TIME,
    input wire UPDATE,
    input settings::stm_settings_t STM_SETTINGS,
    stm_bus_if.stm_port STM_BUS,
    stm_bus_if.out_focus_port STM_BUS_FOCUS,
    stm_bus_if.out_gain_port STM_BUS_GAIN,
    output wire [7:0] INTENSITY,
    output wire [7:0] PHASE,
    output wire DOUT_VALID,
    output wire [15:0] DEBUG_IDX,
    output wire DEBUG_SEGMENT,
    output wire [15:0] DEBUG_CYCLE
);

  logic mode = params::STM_MODE_GAIN;
  logic start = 1'b0;
  logic segment = '0;
  logic [15:0] idx = '0;
  logic [15:0] cycle = '0;
  logic [31:0] sound_speed = '0;

  assign STM_BUS.MODE = mode;
  assign STM_BUS.SEGMENT = segment;

  logic update_settings;
  logic [7:0] intensity_gain;
  logic [7:0] phase_gain;
  logic [7:0] intensity_focus;
  logic [7:0] phase_focus;
  logic dout_valid_gain, dout_valid_focus;

  assign INTENSITY = mode == params::STM_MODE_GAIN ? intensity_gain : intensity_focus;
  assign PHASE = mode == params::STM_MODE_GAIN ? phase_gain : phase_focus;
  assign DOUT_VALID = mode == params::STM_MODE_GAIN ? dout_valid_gain : dout_valid_focus;

  assign DEBUG_IDX = idx;
  assign DEBUG_SEGMENT = segment;
  assign DEBUG_CYCLE = cycle;

  logic [15:0] timer_idx_0, timer_idx_1;
  stm_timer stm_timer (
      .CLK(CLK),
      .UPDATE_SETTINGS_IN(STM_SETTINGS.UPDATE),
      .SYS_TIME(SYS_TIME),
      .CYCLE_0(STM_SETTINGS.CYCLE_0),
      .FREQ_DIV_0(STM_SETTINGS.FREQ_DIV_0),
      .CYCLE_1(STM_SETTINGS.CYCLE_1),
      .FREQ_DIV_1(STM_SETTINGS.FREQ_DIV_1),
      .IDX_0(timer_idx_0),
      .IDX_1(timer_idx_1),
      .UPDATE_SETTINGS_OUT(update_settings)
  );

  logic [15:0] swapchain_idx_0, swapchain_idx_1;
  logic swapchain_segment;
  logic swapchain_stop;
  stm_swapchain stm_swapchain (
      .CLK(CLK),
      .UPDATE_SETTINGS(update_settings),
      .REQ_RD_SEGMENT(STM_SETTINGS.REQ_RD_SEGMENT),
      .REP_0(STM_SETTINGS.REP_0),
      .REP_1(STM_SETTINGS.REP_1),
      .IDX_0_IN(timer_idx_0),
      .IDX_1_IN(timer_idx_1),
      .STOP(swapchain_stop),
      .SEGMENT(swapchain_segment),
      .IDX_0_OUT(swapchain_idx_0),
      .IDX_1_OUT(swapchain_idx_1)
  );

  stm_gain #(
      .DEPTH(DEPTH)
  ) stm_gain (
      .CLK(CLK),
      .START(start),
      .IDX(idx),
      .STM_BUS(STM_BUS_GAIN),
      .INTENSITY(intensity_gain),
      .PHASE(phase_gain),
      .DOUT_VALID(dout_valid_gain)
  );

  stm_focus #(
      .DEPTH(DEPTH)
  ) stm_focus (
      .CLK(CLK),
      .START(start),
      .IDX(idx),
      .STM_BUS(STM_BUS_FOCUS),
      .SOUND_SPEED(sound_speed),
      .INTENSITY(intensity_focus),
      .PHASE(phase_focus),
      .DOUT_VALID(dout_valid_focus)
  );

  always_ff @(posedge CLK) begin
    if (UPDATE) begin
      if (swapchain_stop == 1'b0) begin
        segment <= swapchain_segment;
        mode <= swapchain_segment == 1'b0 ? STM_SETTINGS.MODE_0 : STM_SETTINGS.MODE_1;
        idx <= swapchain_segment == 1'b0 ? swapchain_idx_0 : swapchain_idx_1;
        sound_speed <= swapchain_segment == 1'b0 ? STM_SETTINGS.SOUND_SPEED_0 : STM_SETTINGS.SOUND_SPEED_1;
        cycle <= swapchain_segment == 1'b0 ? STM_SETTINGS.CYCLE_0 : STM_SETTINGS.CYCLE_1;
      end
      start <= 1'b1;
    end else begin
      start <= 1'b0;
    end
  end

endmodule
