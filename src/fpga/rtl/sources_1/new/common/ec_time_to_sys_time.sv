`timescale 1ns / 1ps
module ec_time_to_sys_time (
    input wire CLK,
    input wire [63:0] EC_TIME,
    output wire [63:0] SYS_TIME
);

  localparam logic [15:0] ECATSyncBase = 16'd50000;

  logic [63:0] ec_time;
  logic [63:0] sys_time;

  logic [63:0] lap;
  logic [15:0] lap_rem_unused;

  div_64_16 div_lap (
      .s_axis_dividend_tdata(ec_time),
      .s_axis_dividend_tvalid(1'b1),
      .s_axis_divisor_tdata(ECATSyncBase),
      .s_axis_divisor_tvalid(1'b1),
      .aclk(CLK),
      .m_axis_dout_tdata({lap, lap_rem_unused}),
      .m_axis_dout_tvalid()
  );

  assign SYS_TIME = sys_time;

  always_ff @(posedge CLK) begin
    ec_time  <= EC_TIME;
    sys_time <= {lap[54:0], 9'h00};
  end

endmodule
