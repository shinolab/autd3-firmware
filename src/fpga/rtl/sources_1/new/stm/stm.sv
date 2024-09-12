`timescale 1ns / 1ps
module stm #(
    parameter int DEPTH = 249,
    parameter string MODE = "NearestEven"
) (
    input wire CLK,
    input wire [55:0] SYS_TIME,
    input wire UPDATE,
    input settings::stm_settings_t STM_SETTINGS,
    stm_bus_if.stm_port STM_BUS,
    stm_bus_if.out_focus_port STM_BUS_FOCUS,
    stm_bus_if.out_gain_port STM_BUS_GAIN,
    output wire [7:0] INTENSITY,
    output wire [7:0] PHASE,
    output wire DOUT_VALID,
    input wire GPIO_IN[4],
    output wire [12:0] DEBUG_IDX,
    output wire DEBUG_SEGMENT,
    output wire [12:0] DEBUG_CYCLE
);

  logic mode = params::STM_MODE_GAIN;
  logic start = 1'b0;
  logic segment = '0;
  logic [12:0] idx = '0;
  logic [12:0] cycle = '0;
  logic [15:0] sound_speed = '0;
  logic [7:0] num_foci = 8'd1;

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

  logic [12:0] timer_idx[params::NumSegment];
  stm_timer stm_timer (
      .CLK(CLK),
      .UPDATE_SETTINGS_IN(STM_SETTINGS.UPDATE),
      .SYS_TIME(SYS_TIME),
      .CYCLE(STM_SETTINGS.CYCLE),
      .FREQ_DIV(STM_SETTINGS.FREQ_DIV),
      .IDX(timer_idx),
      .UPDATE_SETTINGS_OUT(update_settings)
  );

  logic [12:0] swapchain_idx[params::NumSegment];
  logic swapchain_segment;
  logic swapchain_stop;
  stm_swapchain stm_swapchain (
      .CLK(CLK),
      .SYS_TIME(SYS_TIME),
      .UPDATE_SETTINGS(update_settings),
      .REQ_RD_SEGMENT(STM_SETTINGS.REQ_RD_SEGMENT),
      .TRANSITION_MODE(STM_SETTINGS.TRANSITION[63:56]),
      .TRANSITION_VALUE(STM_SETTINGS.TRANSITION[55:0]),
      .CYCLE(STM_SETTINGS.CYCLE),
      .REP(STM_SETTINGS.REP),
      .SYNC_IDX(timer_idx),
      .GPIO_IN(GPIO_IN),
      .STOP(swapchain_stop),
      .SEGMENT(swapchain_segment),
      .IDX(swapchain_idx)
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
      .DEPTH(DEPTH),
      .MODE (MODE)
  ) stm_focus (
      .CLK(CLK),
      .START(start),
      .IDX(idx),
      .STM_BUS(STM_BUS_FOCUS),
      .SOUND_SPEED(sound_speed),
      .NUM_FOCI(num_foci),
      .INTENSITY(intensity_focus),
      .PHASE(phase_focus),
      .DOUT_VALID(dout_valid_focus)
  );

  always_ff @(posedge CLK) begin
    if (UPDATE) begin
      if (swapchain_stop == 1'b0) begin
        segment <= swapchain_segment;
        idx <= swapchain_idx[swapchain_segment];
        mode <= STM_SETTINGS.MODE[swapchain_segment];
        sound_speed <= STM_SETTINGS.SOUND_SPEED[swapchain_segment];
        cycle <= STM_SETTINGS.CYCLE[swapchain_segment];
        num_foci <= STM_SETTINGS.NUM_FOCI[swapchain_segment];
      end
      start <= 1'b1;
    end else begin
      start <= 1'b0;
    end
  end

endmodule
