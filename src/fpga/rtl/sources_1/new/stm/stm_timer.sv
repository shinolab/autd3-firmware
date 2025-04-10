`timescale 1ns / 1ps
module stm_timer (
    input wire CLK,
    input wire UPDATE_SETTINGS_IN,
    input wire [56:0] SYS_TIME,
    input wire [15:0] CYCLE[params::NumSegment],
    input wire [15:0] FREQ_DIV[params::NumSegment],
    output wire [15:0] IDX[params::NumSegment],
    output wire UPDATE_SETTINGS_OUT
);

  localparam int DivLatency = 51;
  localparam int TotalLetency = 1 + 2 * DivLatency + 8 + 1;

  logic update_settings;
  logic [$clog2(TotalLetency)-1:0] cnt;

  typedef enum logic {
    IDLE,
    LOAD
  } state_t;

  state_t state = IDLE;

  assign UPDATE_SETTINGS_OUT = update_settings;

  for (genvar i = 0; i < params::NumSegment; i++) begin : gen_stm_timer_idx
    logic [15:0] freq_div;
    logic [16:0] cycle;
    logic [47:0] quo;
    logic [23:0] _unused_rem;
    logic [47:0] _unused_quo;
    logic idx_dout_valid;
    logic [23:0] rem;
    logic [15:0] idx;

    assign IDX[i] = idx;

    always_ff @(posedge CLK) begin
      idx <= (idx_dout_valid) ? rem[15:0] : idx;
      if ((state == IDLE) & UPDATE_SETTINGS_IN) begin
        freq_div <= FREQ_DIV[i];
        cycle <= CYCLE[i] + 1;
      end
    end

    div_48_24 div_cnt (
        .s_axis_dividend_tdata(SYS_TIME[56:9]),
        .s_axis_dividend_tvalid(1'b1),
        .s_axis_dividend_tready(),
        .s_axis_divisor_tdata({8'd0, freq_div}),
        .s_axis_divisor_tvalid(1'b1),
        .s_axis_divisor_tready(),
        .aclk(CLK),
        .m_axis_dout_tdata({quo, _unused_rem}),
        .m_axis_dout_tvalid()
    );
    div_48_24 div_idx (
        .s_axis_dividend_tdata(quo),
        .s_axis_dividend_tvalid(1'b1),
        .s_axis_dividend_tready(),
        .s_axis_divisor_tdata({7'd0, cycle}),
        .s_axis_divisor_tvalid(1'b1),
        .s_axis_divisor_tready(),
        .aclk(CLK),
        .m_axis_dout_tdata({_unused_quo, rem}),
        .m_axis_dout_tvalid(idx_dout_valid)
    );
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
        if (cnt == TotalLetency) begin
          update_settings <= 1'b1;
          state <= IDLE;
        end
      end
      default: state <= IDLE;
    endcase
  end

endmodule
