`timescale 1ns / 1ps
module silencer_pwe_selector #(
    parameter int DEPTH = 249
) (
    input wire CLK,
    input settings::silencer_settings_t SILENCER_SETTINGS,
    input wire DIN_VALID,
    input wire [7:0] INTENSITY_IN,
    input wire [7:0] PHASE_IN,
    output var [7:0] PULSE_WIDTH_OUT,
    output var [7:0] PHASE_OUT,
    output var DOUT_VALID
);

  logic silent_pulse_width;
  logic silencer_din_valid, silencer_dout_valid;
  logic [7:0] silencer_i_in, silencer_p_in;
  logic [7:0] silencer_i_out, silencer_p_out;

  logic pwe_din_valid, pwe_dout_valid;
  logic [7:0] pwe_i_in, pwe_p_in;
  logic [7:0] pwe_i_out, pwe_p_out;

  assign silent_pulse_width = SILENCER_SETTINGS.FLAG[params::SILENCER_FLAG_BIT_PULSE_WIDTH];
  assign silencer_i_in = silent_pulse_width ? pwe_i_out : INTENSITY_IN;
  assign silencer_p_in = silent_pulse_width ? pwe_p_out : PHASE_IN;
  assign silencer_din_valid = silent_pulse_width ? pwe_dout_valid : DIN_VALID;
  assign pwe_i_in = silent_pulse_width ? INTENSITY_IN : silencer_i_out;
  assign pwe_p_in = silent_pulse_width ? PHASE_IN : silencer_p_out;
  assign pwe_din_valid = silent_pulse_width ? DIN_VALID : silencer_dout_valid;
  assign PULSE_WIDTH_OUT = silent_pulse_width ? silencer_i_out : pwe_i_out;
  assign PHASE_OUT = silent_pulse_width ? silencer_p_out : pwe_p_out;
  assign DOUT_VALID = silent_pulse_width ? silencer_dout_valid : pwe_dout_valid;

  silencer #(
      .DEPTH(DEPTH)
  ) silencer (
      .CLK(CLK),
      .DIN_VALID(silencer_din_valid),
      .SILENCER_SETTINGS(SILENCER_SETTINGS),
      .INTENSITY_IN(silencer_i_in),
      .PHASE_IN(silencer_p_in),
      .INTENSITY_OUT(silencer_i_out),
      .PHASE_OUT(silencer_p_out),
      .DOUT_VALID(silencer_dout_valid)
  );

  pulse_width_encoder #(
      .DEPTH(DEPTH)
  ) pulse_width_encoder (
      .CLK(CLK),
      .PWE_TABLE_BUS(pwe_table_bus.out_port),
      .DIN_VALID(pwe_din_valid),
      .INTENSITY_IN(pwe_i_in),
      .PHASE_IN(pwe_p_in),
      .PULSE_WIDTH_OUT(pwe_i_out),
      .PHASE_OUT(pwe_p_out),
      .DOUT_VALID(pwe_dout_valid)
  );

endmodule
