`timescale 1ns / 1ps
module modulation_timer (
    input var CLK,
    input var [63:0] SYS_TIME,
    input var [14:0] CYCLE_0,
    input var [31:0] FREQ_DIV_0,
    input var [14:0] CYCLE_1,
    input var [31:0] FREQ_DIV_1,
    mod_cnt_if.sampler_port MOD_CNT
);

  logic [63:0] divined;
  logic [31:0] freq_div_0, freq_div_1;
  logic [63:0] quo_0, quo_1;
  logic [31:0] _unused_rem_0, _unused_rem_1;
  logic [63:0] _unused_quo_0, _unused_quo_1;
  logic [31:0] cycle_0, cycle_1;
  logic [31:0] rem_0, rem_1;

  assign MOD_CNT.IDX_0 = rem_0;
  assign MOD_CNT.IDX_1 = rem_1;

  div_64_32 div_64_32_quo_0 (
      .s_axis_dividend_tdata(divined),
      .s_axis_dividend_tvalid(1'b1),
      .s_axis_divisor_tdata(freq_div_0),
      .s_axis_divisor_tvalid(1'b1),
      .aclk(CLK),
      .m_axis_dout_tdata({quo_0, _unused_rem_0}),
      .m_axis_dout_tvalid()
  );

  div_64_32 div_64_32_rem_0 (
      .s_axis_dividend_tdata(quo_0),
      .s_axis_dividend_tvalid(1'b1),
      .s_axis_divisor_tdata(cycle_0),
      .s_axis_divisor_tvalid(1'b1),
      .aclk(CLK),
      .m_axis_dout_tdata({_unused_quo_0, rem_0}),
      .m_axis_dout_tvalid()
  );

  div_64_32 div_64_32_quo_1 (
      .s_axis_dividend_tdata(divined),
      .s_axis_dividend_tvalid(1'b1),
      .s_axis_divisor_tdata(freq_div_1),
      .s_axis_divisor_tvalid(1'b1),
      .aclk(CLK),
      .m_axis_dout_tdata({quo_1, _unused_rem_1}),
      .m_axis_dout_tvalid()
  );

  div_64_32 div_64_32_rem_1 (
      .s_axis_dividend_tdata(quo_1),
      .s_axis_dividend_tvalid(1'b1),
      .s_axis_divisor_tdata(cycle_1),
      .s_axis_divisor_tvalid(1'b1),
      .aclk(CLK),
      .m_axis_dout_tdata({_unused_quo_1, rem_1}),
      .m_axis_dout_tvalid()
  );

  always_ff @(posedge CLK) begin
    divined <= SYS_TIME;
    freq_div_0 <= FREQ_DIV_0;
    cycle_0 <= CYCLE_0 + 1;
    freq_div_1 <= FREQ_DIV_1;
    cycle_1 <= CYCLE_1 + 1;
  end

endmodule
