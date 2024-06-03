`timescale 1ns / 1ps
module stm_focus #(
    parameter int DEPTH = 249
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

  logic [511:0] data_out;
  logic dout_valid = 1'b0;

  logic signed [15:0] trans_x, trans_y;

  logic [$clog2(CalcLatency + params::NumFociMax + DEPTH)-1:0] cnt = '0;

  typedef enum logic [2:0] {
    WAITING,
    BRAM_WAIT_0,
    BRAM_WAIT_1,
    CALC
  } state_t;

  state_t state = WAITING;

  assign STM_BUS.FOCUS_IDX = IDX;
  assign data_out = STM_BUS.VALUE;

  dist_mem_tr dist_mem_tr (
      .a  (cnt[7:0]),
      .spo({trans_x, trans_y})
  );

  logic [7:0] phase[params::NumFociMax];
  logic [7:0] intensity_or_offsets[params::NumFociMax];
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

    sqrt_36 sqrt_36 (
        .aclk(CLK),
        .s_axis_cartesian_tvalid(1'b1),
        .s_axis_cartesian_tdata({4'd0, d2}),
        .m_axis_dout_tvalid(),
        .m_axis_dout_tdata(sqrt_dout)
    );

    div_32_16 div_32_16_quo (
        .s_axis_dividend_tdata({sqrt_dout[17:0], 14'd0}),
        .s_axis_dividend_tvalid(1'b1),
        .s_axis_divisor_tdata(SOUND_SPEED),
        .s_axis_divisor_tvalid(1'b1),
        .aclk(CLK),
        .m_axis_dout_tdata({quo, _unused_rem}),
        .m_axis_dout_tvalid()
    );

    assign phase[i] = i < NUM_FOCI ? quo[7:0] : 8'h0;
    assign intensity_or_offsets[i] = i < NUM_FOCI ? data_out[64*i+61:64*i+54] : 8'h0;
  end

  logic [7:0] phase_01, phase_23, phase_45, phase_67;
  logic [7:0] phase_0123, phase_4567;
  assign INTENSITY = intensity_or_offsets[0];
  assign PHASE = phase_0123 + phase_4567;
  assign DOUT_VALID = dout_valid;

  always_ff @(posedge CLK) begin
    case (state)
      WAITING: begin
        cnt <= 0;
        dout_valid <= 1'b0;
        state <= START ? BRAM_WAIT_0 : state;
      end
      BRAM_WAIT_0: begin
        state <= BRAM_WAIT_1;
      end
      BRAM_WAIT_1: begin
        state <= CALC;
      end
      CALC: begin
        cnt <= cnt + 1;
        dout_valid <= cnt > CalcLatency + 2;
        state <= (cnt == CalcLatency + 2 + DEPTH - 1) ? WAITING : state;
      end
      default: state <= WAITING;
    endcase
  end

  always_ff @(posedge CLK) begin
    phase_01   <= phase[0] + phase[1] + intensity_or_offsets[1];
    phase_23   <= phase[2] + intensity_or_offsets[2] + phase[3] + intensity_or_offsets[3];
    phase_45   <= phase[4] + intensity_or_offsets[4] + phase[5] + intensity_or_offsets[5];
    phase_67   <= phase[6] + intensity_or_offsets[6] + phase[7] + intensity_or_offsets[7];
    phase_0123 <= phase_01 + phase_23;
    phase_4567 <= phase_45 + phase_67;
  end

endmodule
