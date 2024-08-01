`timescale 1ns / 1ps
module ec_time_to_sys_time (
    input wire CLK,
    input wire [63:0] EC_TIME,
    input wire DIN_VALID,
    output wire [63:0] SYS_TIME,
    output wire DOUT_VALID
);

  localparam logic [15:0] ECATSyncBase = 16'd50000;

  logic [63:0] lap;
  logic [15:0] lap_rem_unused;

  logic [63:0] ec_time;
  logic din_valid;
  logic din_ready;

  div_64_16 div_lap (
      .s_axis_dividend_tdata(ec_time),
      .s_axis_dividend_tvalid(din_valid),
      .s_axis_dividend_tready(din_ready),
      .s_axis_divisor_tdata(ECATSyncBase),
      .s_axis_divisor_tvalid(1'b1),
      .s_axis_divisor_tready(),
      .aclk(CLK),
      .m_axis_dout_tdata({lap, lap_rem_unused}),
      .m_axis_dout_tvalid(DOUT_VALID)
  );

  assign SYS_TIME = {lap[54:0], 9'h00};

  always_ff @(posedge CLK) begin
    if (din_valid && din_ready) begin
      din_valid <= 1'b0;
    end else if (DIN_VALID) begin
      ec_time   <= EC_TIME;
      din_valid <= 1'b1;
    end
  end

endmodule
