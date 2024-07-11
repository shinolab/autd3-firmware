`timescale 1ns / 1ps
module stm_timer (
    input wire CLK,
    input wire UPDATE_SETTINGS_IN,
    input wire [63:0] SYS_TIME,
    input wire [12:0] CYCLE[params::NumSegment],
    input wire [15:0] FREQ_DIV[params::NumSegment],
    output wire [12:0] IDX[params::NumSegment],
    output wire UPDATE_SETTINGS_OUT
);

  localparam int DivLatency = 50;

  logic update_settings;
  logic [$clog2(DivLatency*2+2)-1:0] cnt;

  typedef enum logic {
    IDLE,
    LOAD
  } state_t;

  state_t state = IDLE;

  assign UPDATE_SETTINGS_OUT = update_settings;

  for (genvar i = 0; i < params::NumSegment; i++) begin : gen_stm_timer_idx
    logic [15:0] freq_div;
    logic [13:0] cycle;
    logic [47:0] quo, quo_buf;
    logic [15:0] _unused_rem;
    logic [47:0] _unused_quo;
    logic [15:0] rem;
    logic [12:0] idx;

    assign IDX[i] = idx;

    always_ff @(posedge CLK) begin
      quo_buf <= quo;
      idx <= rem[12:0];
      if ((state == IDLE) & UPDATE_SETTINGS_IN) begin
        freq_div <= FREQ_DIV[i];
        cycle <= CYCLE[i] + 1;
      end
    end

    div_48_16 div_cnt (
        .s_axis_dividend_tdata(SYS_TIME[55:8]),
        .s_axis_dividend_tvalid(1'b1),
        .s_axis_divisor_tdata(freq_div),
        .s_axis_divisor_tvalid(1'b1),
        .aclk(CLK),
        .m_axis_dout_tdata({quo, _unused_rem}),
        .m_axis_dout_tvalid()
    );
    div_48_16 div_idx (
        .s_axis_dividend_tdata(quo_buf),
        .s_axis_dividend_tvalid(1'b1),
        .s_axis_divisor_tdata({2'b00, cycle}),
        .s_axis_divisor_tvalid(1'b1),
        .aclk(CLK),
        .m_axis_dout_tdata({_unused_quo, rem}),
        .m_axis_dout_tvalid()
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
        if (cnt == 2 * DivLatency + 1) begin
          update_settings <= 1'b1;
          state <= IDLE;
        end
      end
      default: state <= IDLE;
    endcase
  end

endmodule
