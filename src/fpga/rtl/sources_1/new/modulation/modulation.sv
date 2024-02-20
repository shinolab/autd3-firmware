`timescale 1ns / 1ps
module modulation #(
    parameter int DEPTH = 249
) (
    input wire CLK,
    input wire [63:0] SYS_TIME,
    input wire settings::mod_settings_t MOD_SETTINGS,
    input wire DIN_VALID,
    input wire [7:0] INTENSITY_IN,
    output wire [15:0] INTENSITY_OUT,
    input wire [7:0] PHASE_IN,
    output wire [7:0] PHASE_OUT,
    output wire DOUT_VALID,
    modulation_bus_if.out_port MOD_BUS,
    filter_bus_if.out_port FILTER_BUS,
    output wire [14:0] DEBUG_IDX,
    output wire DEBUG_SEGMENT,
    output wire DEBUG_STOP
);

  logic [14:0] idx_0_timer, idx_1_timer;
  modulation_timer modulation_timer (
      .CLK(CLK),
      .UPDATE_SETTINGS_IN(MOD_SETTINGS.UPDATE),
      .SYS_TIME(SYS_TIME),
      .CYCLE_0(MOD_SETTINGS.CYCLE_0),
      .FREQ_DIV_0(MOD_SETTINGS.FREQ_DIV_0),
      .CYCLE_1(MOD_SETTINGS.CYCLE_1),
      .FREQ_DIV_1(MOD_SETTINGS.FREQ_DIV_1),
      .IDX_0(idx_0_timer),
      .IDX_1(idx_1_timer),
      .UPDATE_SETTINGS_OUT(update_settings)
  );

  logic [14:0] idx_0, idx_1;
  modulation_swapchain modulation_swapchain (
      .CLK(CLK),
      .UPDATE_SETTINGS(update_settings),
      .REQ_RD_SEGMENT(MOD_SETTINGS.REQ_RD_SEGMENT),
      .REP_0(MOD_SETTINGS.REP_0),
      .REP_1(MOD_SETTINGS.REP_1),
      .IDX_0_IN(idx_0_timer),
      .IDX_1_IN(idx_1_timer),
      .SEGMENT(segment),
      .STOP(stop),
      .IDX_0_OUT(idx_0),
      .IDX_1_OUT(idx_1)
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
      .IDX_0(idx_0),
      .IDX_1(idx_1),
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
      .PHASE_OUT(PHASE_OUT)
  );

endmodule
