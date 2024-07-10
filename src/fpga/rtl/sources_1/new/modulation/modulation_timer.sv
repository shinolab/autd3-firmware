`timescale 1ns / 1ps
module modulation_timer (
    input wire CLK,
    input wire UPDATE_SETTINGS_IN,
    input wire [63:0] SYS_TIME,
    input wire [14:0] CYCLE[params::NumSegment],
    input wire [15:0] FREQ_DIV[params::NumSegment],
    output wire [14:0] IDX[params::NumSegment],
    output wire UPDATE_SETTINGS_OUT
);

  localparam int DivLatency = 58;

  logic update_settings;
  logic [$clog2(DivLatency*2)-1:0] cnt;

  logic [15:0] freq_div[params::NumSegment];
  logic [15:0] cycle[params::NumSegment];

  assign UPDATE_SETTINGS_OUT = update_settings;
  for (genvar i = 0; i < params::NumSegment; i++) begin : gen_mod_timer_idx
    logic [55:0] quo;
    logic [15:0] _unused_rem;
    logic [55:0] _unused_quo;
    logic [15:0] rem;
    assign IDX[i] = rem[14:0];
    div_56_16 div_cnt (
        .s_axis_dividend_tdata(SYS_TIME[63:8]),
        .s_axis_dividend_tvalid(1'b1),
        .s_axis_divisor_tdata(freq_div[i]),
        .s_axis_divisor_tvalid(1'b1),
        .aclk(CLK),
        .m_axis_dout_tdata({quo, _unused_rem}),
        .m_axis_dout_tvalid()
    );
    div_56_16 div_idx (
        .s_axis_dividend_tdata(quo),
        .s_axis_dividend_tvalid(1'b1),
        .s_axis_divisor_tdata(cycle[i]),
        .s_axis_divisor_tvalid(1'b1),
        .aclk(CLK),
        .m_axis_dout_tdata({_unused_quo, rem}),
        .m_axis_dout_tvalid()
    );
  end

  typedef enum logic {
    IDLE,
    LOAD
  } state_t;

  state_t state = IDLE;

  for (genvar i = 0; i < params::NumSegment; i++) begin : gen_mod_timer
    always_ff @(posedge CLK)
      if ((state == IDLE) & UPDATE_SETTINGS_IN) begin
        freq_div[i] <= FREQ_DIV[i];
        cycle[i] <= CYCLE[i] + 1;
      end
  end

  always_ff @(posedge CLK) begin
    case (state)
      IDLE: begin
        update_settings <= 1'b0;
        cnt <= '0;
        state <= UPDATE_SETTINGS_IN ? LOAD : state;
      end
      LOAD: begin
        cnt <= cnt + 1;
        if (cnt == 2 * DivLatency - 1) begin
          update_settings <= 1'b1;
          state <= IDLE;
        end
      end
      default: state <= IDLE;
    endcase
  end

endmodule
