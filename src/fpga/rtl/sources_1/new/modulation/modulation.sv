`timescale 1ns / 1ps
module modulation #(
    parameter int DEPTH = 249
) (
    input wire CLK,
    input wire [63:0] SYS_TIME,
    input wire settings::mod_settings_t MOD_SETTINGS,
    input wire settings::sync_settings_t SYNC_SETTINGS,
    input wire DIN_VALID,
    input wire [7:0] INTENSITY_IN,
    output wire [15:0] INTENSITY_OUT,
    input wire [7:0] PHASE_IN,
    output wire [7:0] PHASE_OUT,
    output wire DOUT_VALID,
    modulation_bus_if.out_port MOD_BUS,
    filter_bus_if.out_port FILTER_BUS,
    input wire GPIO_IN[4],
    output wire [14:0] DEBUG_IDX,
    output wire DEBUG_SEGMENT,
    output wire DEBUG_STOP
);

  logic [14:0] sync_idx[params::NumSegment];
  modulation_timer modulation_timer (
      .CLK(CLK),
      .UPDATE_SETTINGS_IN(MOD_SETTINGS.UPDATE),
      .SYS_TIME(SYS_TIME),
      .CYCLE(MOD_SETTINGS.CYCLE),
      .FREQ_DIV(MOD_SETTINGS.FREQ_DIV),
      .IDX(sync_idx),
      .UPDATE_SETTINGS_OUT(update_settings)
  );

  logic [14:0] idx[params::NumSegment];
  modulation_swapchain modulation_swapchain (
      .CLK(CLK),
      .SYS_TIME(SYS_TIME),
      .UPDATE_SETTINGS(update_settings),
      .REQ_RD_SEGMENT(MOD_SETTINGS.REQ_RD_SEGMENT),
      .TRANSITION_MODE(MOD_SETTINGS.TRANSITION_MODE),
      .TRANSITION_VALUE(MOD_SETTINGS.TRANSITION_VALUE),
      .ECAT_SYNC_BASE_CNT(SYNC_SETTINGS.ECAT_SYNC_BASE_CNT[17:0]),
      .CYCLE(MOD_SETTINGS.CYCLE),
      .REP(MOD_SETTINGS.REP),
      .SYNC_IDX(sync_idx),
      .GPIO_IN(GPIO_IN),
      .STOP(stop),
      .SEGMENT(segment),
      .IDX(idx)
  );

  modulation_multiplier #(
      .DEPTH(DEPTH)
  ) modulation_multiplier (
      .CLK(CLK),
      .DIN_VALID(DIN_VALID),
      .INTENSITY_IN(INTENSITY_IN),
      .INTENSITY_OUT(INTENSITY_OUT),
      .DOUT_VALID(DOUT_VALID),
      .MOD_BUS(MOD_BUS),
      .IDX(idx),
      .SEGMENT(segment),
      .STOP(stop),
      .DEBUG_IDX(DEBUG_IDX),
      .DEBUG_SEGMENT(DEBUG_SEGMENT),
      .DEBUG_STOP(DEBUG_STOP)
  );

  phase_filter #(
      .DEPTH(DEPTH)
  ) phase_filter (
      .CLK(CLK),
      .FILTER_BUS(FILTER_BUS),
      .DIN_VALID(DIN_VALID),
      .PHASE_IN(PHASE_IN),
      .PHASE_OUT(PHASE_OUT),
      .DOUT_VALID()
  );

endmodule
