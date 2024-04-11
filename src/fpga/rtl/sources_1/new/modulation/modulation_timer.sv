`timescale 1ns / 1ps
module modulation_timer (
    input wire CLK,
    input wire UPDATE_SETTINGS_IN,
    input wire [63:0] SYS_TIME,
    input wire [14:0] CYCLE[2],
    input wire [31:0] FREQ_DIV[2],
    output wire [14:0] IDX[2],
    output wire UPDATE_SETTINGS_OUT
);

  localparam int DIV_LATENCY = 66;

  logic update_settings = 1'b0;
  logic [$clog2(DIV_LATENCY*2)-1:0] cnt = '0;

  logic [31:0] freq_div[2];
  logic [63:0] quo[2];
  logic [31:0] _unused_rem[2];
  logic [63:0] _unused_quo[2];
  logic [31:0] cycle[2];
  logic [31:0] rem[2];

  assign IDX[0] = rem[0][14:0];
  assign IDX[1] = rem[1][14:0];
  assign UPDATE_SETTINGS_OUT = update_settings;

  div_64_32 div_64_32_quo_0 (
      .s_axis_dividend_tdata(SYS_TIME),
      .s_axis_dividend_tvalid(1'b1),
      .s_axis_divisor_tdata(freq_div[0]),
      .s_axis_divisor_tvalid(1'b1),
      .aclk(CLK),
      .m_axis_dout_tdata({quo[0], _unused_rem[0]}),
      .m_axis_dout_tvalid()
  );

  div_64_32 div_64_32_rem_0 (
      .s_axis_dividend_tdata(quo[0]),
      .s_axis_dividend_tvalid(1'b1),
      .s_axis_divisor_tdata(cycle[0]),
      .s_axis_divisor_tvalid(1'b1),
      .aclk(CLK),
      .m_axis_dout_tdata({_unused_quo[0], rem[0]}),
      .m_axis_dout_tvalid()
  );

  div_64_32 div_64_32_quo_1 (
      .s_axis_dividend_tdata(SYS_TIME),
      .s_axis_dividend_tvalid(1'b1),
      .s_axis_divisor_tdata(freq_div[1]),
      .s_axis_divisor_tvalid(1'b1),
      .aclk(CLK),
      .m_axis_dout_tdata({quo[1], _unused_rem[1]}),
      .m_axis_dout_tvalid()
  );

  div_64_32 div_64_32_rem_1 (
      .s_axis_dividend_tdata(quo[1]),
      .s_axis_dividend_tvalid(1'b1),
      .s_axis_divisor_tdata(cycle[1]),
      .s_axis_divisor_tvalid(1'b1),
      .aclk(CLK),
      .m_axis_dout_tdata({_unused_quo[1], rem[1]}),
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
          freq_div <= FREQ_DIV;
          cycle[0] <= CYCLE[0] + 15'd1;
          cycle[1] <= CYCLE[1] + 15'd1;
          cnt <= '0;
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
