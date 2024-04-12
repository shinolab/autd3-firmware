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

  logic [14:0] idx_timer[2];
  modulation_timer modulation_timer (
      .CLK(CLK),
      .UPDATE_SETTINGS_IN(MOD_SETTINGS.UPDATE),
      .SYS_TIME(SYS_TIME),
      .CYCLE(MOD_SETTINGS.CYCLE),
      .FREQ_DIV(MOD_SETTINGS.FREQ_DIV),
      .IDX(idx_timer),
      .UPDATE_SETTINGS_OUT(update_settings)
  );

  logic [14:0] idx[2];
  modulation_swapchain modulation_swapchain (
      .CLK(CLK),
      .UPDATE_SETTINGS(update_settings),
      .REQ_RD_SEGMENT(MOD_SETTINGS.REQ_RD_SEGMENT),
      .REP(MOD_SETTINGS.REP),
      .IDX_IN(idx_timer),
      .SEGMENT(segment),
      .STOP(stop),
      .IDX_OUT(idx)
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
