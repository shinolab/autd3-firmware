`timescale 1ns / 1ps
module stm_focus #(
    parameter int DEPTH = 249,
    parameter string MODE = "NearestEven"
) (
    input wire CLK,
    input wire START,
    input wire [12:0] IDX,
    stm_bus_if.out_focus_port STM_BUS,
    input wire [15:0] SOUND_SPEED,
    input wire [7:0] NUM_FOCI,
    output wire [7:0] INTENSITY,
    output wire [7:0] PHASE,
    output wire DOUT_VALID
);

  localparam int CalcLatency = 2 + 2 + 2 + 11 + 34 + 1;
  localparam int AccLatency = 8 + 4;

  logic [511:0] data_out;
  logic dout_valid;

  logic signed [15:0] trans_x, trans_y;

  logic start_output;
  logic [7:0] intensity;
  logic [7:0] offset[7];
  logic [$clog2(CalcLatency+AccLatency+1)-1:0] calc_wait_cnt;
  logic [$clog2(DEPTH)-1:0] cnt, output_cnt;

  typedef enum logic {
    IDLE,
    RUN
  } state_t;

  state_t input_state = IDLE;
  state_t output_state = IDLE;

  assign STM_BUS.FOCUS_IDX = IDX;
  assign data_out = STM_BUS.VALUE;

  dist_mem_tr dist_mem_tr (
      .a  (cnt[7:0]),
      .spo({trans_x, trans_y})
  );

  logic [7:0] cos[params::NumFociMax];
  logic [7:0] sin[params::NumFociMax];
  for (genvar i = 0; i < params::NumFociMax; i++) begin : gen_focus
    wire signed [17:0] focus_x = data_out[64*i+17:64*i+0];
    wire signed [17:0] focus_y = data_out[64*i+35:64*i+18];
    wire signed [17:0] focus_z = data_out[64*i+53:64*i+36];

    logic signed [17:0] dx, dy;
    logic [35:0] dx2, dy2, dz2, dxy2, d2;
    logic [23:0] sqrt_dout;

    logic [31:0] quo;
    logic [15:0] _unused_rem;

    addsub #(
        .WIDTH(18)
    ) addsub_x (
        .CLK(CLK),
        .A  (focus_x),
        .B  ({2'b00, trans_x}),
        .ADD(1'b0),
        .S  (dx)
    );

    addsub #(
        .WIDTH(18)
    ) addsub_y (
        .CLK(CLK),
        .A  (focus_y),
        .B  ({2'b00, trans_y}),
        .ADD(1'b0),
        .S  (dy)
    );

    mult #(
        .WIDTH_A(18),
        .WIDTH_B(18)
    ) mult_x (
        .CLK(CLK),
        .A  (dx),
        .B  (dx),
        .P  (dx2)
    );

    mult #(
        .WIDTH_A(18),
        .WIDTH_B(18)
    ) mult_y (
        .CLK(CLK),
        .A  (dy),
        .B  (dy),
        .P  (dy2)
    );

    mult #(
        .WIDTH_A(18),
        .WIDTH_B(18)
    ) mult_z (
        .CLK(CLK),
        .A  (focus_z),
        .B  (focus_z),
        .P  (dz2)
    );

    addsub #(
        .WIDTH(36)
    ) addsub_xy2 (
        .CLK(CLK),
        .A  (dx2),
        .B  (dy2),
        .ADD(1'b1),
        .S  (dxy2)
    );

    addsub #(
        .WIDTH(36)
    ) addsub_xyz2 (
        .CLK(CLK),
        .A  (dxy2),
        .B  (dz2),
        .ADD(1'b1),
        .S  (d2)
    );

    if (MODE == "NearestEven") begin
      sqrt_36 sqrt_36 (
          .aclk(CLK),
          .s_axis_cartesian_tvalid(1'b1),
          .s_axis_cartesian_tdata({4'd0, d2}),
          .m_axis_dout_tvalid(),
          .m_axis_dout_tdata(sqrt_dout)
      );
    end else if (MODE == "TRUNC") begin
      logic [23:0] sqrt_dout_buf;
      sqrt_36_trunc sqrt_36_trunc (
          .aclk(CLK),
          .s_axis_cartesian_tvalid(1'b1),
          .s_axis_cartesian_tdata({4'd0, d2}),
          .m_axis_dout_tvalid(),
          .m_axis_dout_tdata(sqrt_dout_buf)
      );
      always_ff @(posedge CLK) sqrt_dout <= sqrt_dout_buf;
    end

    div_32_16 div_32_16_quo (
        .s_axis_dividend_tdata({sqrt_dout[17:0], 14'd0}),
        .s_axis_dividend_tvalid(1'b1),
        .s_axis_divisor_tdata(SOUND_SPEED),
        .s_axis_divisor_tvalid(1'b1),
        .aclk(CLK),
        .m_axis_dout_tdata({quo, _unused_rem}),
        .m_axis_dout_tvalid()
    );

    wire [7:0] phase = i == 0 ? quo[7:0] : quo[7:0] + offset[i-1];
    logic [7:0] sin_out, cos_out;
    sin_table sin_table (
        .a(phase),
        .d('0),
        .dpra(phase + 8'd64),
        .clk(CLK),
        .we(1'b0),
        .spo(sin_out),
        .dpo(cos_out)
    );
    assign cos[i] = i < NUM_FOCI ? cos_out : 8'h0;
    assign sin[i] = i < NUM_FOCI ? sin_out : 8'h0;
  end

  logic [8:0] sin_01, sin_23, sin_45, sin_67;
  logic [8:0] cos_01, cos_23, cos_45, cos_67;
  logic [9:0] sin_0123, sin_4567;
  logic [9:0] cos_0123, cos_4567;
  logic [10:0] sin_acc, cos_acc;
  logic [7:0] sin_ave, cos_ave;
  assign sin_acc = sin_0123 + sin_4567;
  assign cos_acc = cos_0123 + cos_4567;

  logic [7:0] _sin_quo_unuse, _cos_quo_unuse;
  logic [7:0] _sin_rem_unuse, _cos_rem_unuse;
  div_16_8 div_16_8_sin (
      .s_axis_dividend_tdata({5'd0, sin_acc}),
      .s_axis_dividend_tvalid(1'b1),
      .s_axis_divisor_tdata(NUM_FOCI),
      .s_axis_divisor_tvalid(1'b1),
      .aclk(CLK),
      .m_axis_dout_tdata({_sin_quo_unuse, sin_ave, _sin_rem_unuse}),
      .m_axis_dout_tvalid()
  );
  div_16_8 div_16_8_cos (
      .s_axis_dividend_tdata({5'd0, cos_acc}),
      .s_axis_dividend_tvalid(1'b1),
      .s_axis_divisor_tdata(NUM_FOCI),
      .s_axis_divisor_tvalid(1'b1),
      .aclk(CLK),
      .m_axis_dout_tdata({_cos_quo_unuse, cos_ave, _cos_rem_unuse}),
      .m_axis_dout_tvalid()
  );

  BRAM_ATAN bram_atan (
      .clka (CLK),
      .addra({sin_ave[7:1], cos_ave[7:1]}),
      .douta(PHASE)
  );

  assign INTENSITY  = intensity;
  assign DOUT_VALID = dout_valid;

  always_ff @(posedge CLK) begin
    case (input_state)
      IDLE: begin
        start_output  <= 1'b0;
        calc_wait_cnt <= '0;
        input_state   <= START ? RUN : input_state;
      end
      RUN: begin
        calc_wait_cnt <= calc_wait_cnt + 1;
        if (calc_wait_cnt == CalcLatency - 1) begin
          offset[0] <= data_out[125:118];
          offset[1] <= data_out[189:182];
          offset[2] <= data_out[253:246];
          offset[3] <= data_out[317:310];
          offset[4] <= data_out[381:374];
          offset[5] <= data_out[445:438];
          offset[6] <= data_out[509:502];
        end else if (calc_wait_cnt == CalcLatency + AccLatency) begin
          intensity <= data_out[61:54];
          input_state <= IDLE;
          start_output <= 1'b1;
        end
      end
      default: input_state <= IDLE;
    endcase
  end

  always_ff @(posedge CLK) cnt <= START ? 8'hFF : cnt + 1;

  always_ff @(posedge CLK) begin
    case (output_state)
      IDLE: begin
        output_cnt   <= '0;
        dout_valid   <= 1'b0;
        output_state <= start_output ? RUN : output_state;
      end
      RUN: begin
        output_cnt   <= output_cnt + 1;
        dout_valid   <= 1'b1;
        output_state <= (output_cnt == DEPTH - 1) ? IDLE : output_state;
      end
      default: output_state <= IDLE;
    endcase
  end

  always_ff @(posedge CLK) begin
    sin_01   <= sin[0] + sin[1];
    sin_23   <= sin[2] + sin[3];
    sin_45   <= sin[4] + sin[5];
    sin_67   <= sin[6] + sin[7];
    cos_01   <= cos[0] + cos[1];
    cos_23   <= cos[2] + cos[3];
    cos_45   <= cos[4] + cos[5];
    cos_67   <= cos[6] + cos[7];
    sin_0123 <= sin_01 + sin_23;
    sin_4567 <= sin_45 + sin_67;
    cos_0123 <= cos_01 + cos_23;
    cos_4567 <= cos_45 + cos_67;
  end

endmodule
