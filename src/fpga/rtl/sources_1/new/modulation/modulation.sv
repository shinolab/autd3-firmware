`timescale 1ns / 1ps
module modulation #(
    parameter int DEPTH = 249
) (
    input var CLK,
    input var [63:0] SYS_TIME,
    input var UPDATE_SETTINGS,
    input settings::mod_settings_t MOD_SETTINGS,
    input var DIN_VALID,
    input var [7:0] INTENSITY_IN,
    output var [15:0] INTENSITY_OUT,
    input var [7:0] PHASE_IN,
    output var [7:0] PHASE_OUT,
    output var DOUT_VALID,
    modulation_bus_if.out_port MOD_BUS,
    output var [14:0] DEBUG_IDX,
    output var DEBUG_SEGMENT,
    output var DEBUG_STOP
);

  mod_cnt_if mod_cnt ();

  modulation_timer modulation_timer (
      .CLK(CLK),
      .SYS_TIME(SYS_TIME),
      .CYCLE_0(MOD_SETTINGS.CYCLE_0),
      .FREQ_DIV_0(MOD_SETTINGS.FREQ_DIV_0),
      .CYCLE_1(MOD_SETTINGS.CYCLE_1),
      .FREQ_DIV_1(MOD_SETTINGS.FREQ_DIV_1),
      .MOD_CNT(mod_cnt.timer_port)
  );

  modulation_swapchain modulation_swapchain (
      .CLK(CLK),
      .UPDATE_SETTINGS(UPDATE_SETTINGS),
      .REQ_RD_SEGMENT(MOD_SETTINGS.REQ_RD_SEGMENT),
      .REP(MOD_SETTINGS.REP),
      .MOD_CNT(mod_cnt.swapchain_port)
  );

  modulation_multipiler #(
      .DEPTH(DEPTH)
  ) modulation_multipiler (
      .CLK(CLK),
      .DIN_VALID(DIN_VALID),
      .INTENSITY_IN(INTENSITY_IN),
      .INTENSITY_OUT(INTENSITY_OUT),
      .PHASE_IN(PHASE_IN),
      .PHASE_OUT(PHASE_OUT),
      .DOUT_VALID(DOUT_VALID),
      .MOD_BUS(MOD_BUS),
      .MOD_CNT(mod_cnt.multiplier_port),
      .DEBUG_IDX(DEBUG_IDX),
      .DEBUG_SEGMENT(DEBUG_SEGMENT),
      .DEBUG_STOP(DEBUG_STOP)
  );

endmodule
