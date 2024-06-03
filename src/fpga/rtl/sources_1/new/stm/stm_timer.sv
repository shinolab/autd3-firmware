`timescale 1ns / 1ps
module stm_timer (
    input wire CLK,
    input wire UPDATE_SETTINGS_IN,
    input wire [63:0] SYS_TIME,
    input wire [12:0] CYCLE[params::NumSegment],
    input wire [31:0] FREQ_DIV[params::NumSegment],
    output wire [12:0] IDX[params::NumSegment],
    output wire UPDATE_SETTINGS_OUT
);

  localparam int DivLatency = 66;

  logic update_settings = 1'b0;
  logic [$clog2(DivLatency*2)-1:0] cnt = '0;

  logic [31:0] freq_div[params::NumSegment];
  logic [13:0] cycle[params::NumSegment];

  assign UPDATE_SETTINGS_OUT = update_settings;

  for (genvar i = 0; i < params::NumSegment; i++) begin : gen_stm_timer_idx
    logic [63:0] quo;
    logic [31:0] _unused_rem;
    logic [63:0] _unused_quo;
    logic [31:0] rem;
    assign IDX[i] = rem[12:0];
    div_64_32 div_64_32_quo (
        .s_axis_dividend_tdata(SYS_TIME),
        .s_axis_dividend_tvalid(1'b1),
        .s_axis_divisor_tdata(freq_div[i]),
        .s_axis_divisor_tvalid(1'b1),
        .aclk(CLK),
        .m_axis_dout_tdata({quo, _unused_rem}),
        .m_axis_dout_tvalid()
    );
    div_64_32 div_64_32_rem (
        .s_axis_dividend_tdata(quo),
        .s_axis_dividend_tvalid(1'b1),
        .s_axis_divisor_tdata({18'd0, cycle[i]}),
        .s_axis_divisor_tvalid(1'b1),
        .aclk(CLK),
        .m_axis_dout_tdata({_unused_quo, rem}),
        .m_axis_dout_tvalid()
    );
  end

  typedef enum logic {
    WAIT,
    LOAD
  } state_t;

  state_t state = WAIT;

  for (genvar i = 0; i < params::NumSegment; i++) begin : gen_stm_timer
    always_ff @(posedge CLK)
      if ((state == WAIT) & UPDATE_SETTINGS_IN) begin
        freq_div[i] <= FREQ_DIV[i];
        cycle[i] <= CYCLE[i] + 1;
      end
  end

  always_ff @(posedge CLK) begin
    case (state)
      WAIT: begin
        update_settings <= 1'b0;
        if (UPDATE_SETTINGS_IN) begin
          cnt   <= 0;
          state <= LOAD;
        end
      end
      LOAD: begin
        cnt <= cnt + 1;
        if (cnt == DivLatency * 2 - 1) begin
          update_settings <= 1'b1;
          state <= WAIT;
        end
      end
      default: state <= WAIT;
    endcase
  end

endmodule
