`timescale 1ns / 1ps
module stm_timer (
    input wire CLK,
    input wire UPDATE_SETTINGS_IN,
    input wire [63:0] SYS_TIME,
    input wire [15:0] CYCLE_0,
    input wire [31:0] FREQ_DIV_0,
    input wire [15:0] CYCLE_1,
    input wire [31:0] FREQ_DIV_1,
    output wire [15:0] IDX_0,
    output wire [15:0] IDX_1,
    output wire UPDATE_SETTINGS_OUT
);

  localparam int DIV_LATENCY = 66;

  logic update_settings = 1'b0;
  logic [$clog2(DIV_LATENCY*2)-1:0] cnt = '0;

  logic [31:0] freq_div_0, freq_div_1;
  logic [63:0] quo_0, quo_1;
  logic [31:0] _unused_rem_0, _unused_rem_1;
  logic [63:0] _unused_quo_0, _unused_quo_1;
  logic [31:0] cycle_0, cycle_1;
  logic [31:0] rem_0, rem_1;

  assign IDX_0 = rem_0[15:0];
  assign IDX_1 = rem_1[15:0];
  assign UPDATE_SETTINGS_OUT = update_settings;

  div_64_32 div_64_32_quo_0 (
      .s_axis_dividend_tdata(SYS_TIME),
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
      .s_axis_dividend_tdata(SYS_TIME),
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

  typedef enum logic [1:0] {
    WAIT,
    LOAD
  } state_t;

  state_t state = WAIT;

  always_ff @(posedge CLK) begin
    case (state)
      WAIT: begin
        update_settings <= 1'b0;
        if (UPDATE_SETTINGS_IN) begin
          freq_div_0 <= FREQ_DIV_0;
          cycle_0 <= CYCLE_0 + 1;
          freq_div_1 <= FREQ_DIV_1;
          cycle_1 <= CYCLE_1 + 1;
          cnt <= 0;
          state <= LOAD;
        end
      end
      LOAD: begin
        cnt <= cnt + 1;
        if (cnt == DIV_LATENCY * 2 - 1) begin
          update_settings <= 1'b1;
          state <= WAIT;
        end
      end
    endcase
  end

endmodule
