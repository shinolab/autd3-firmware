`timescale 1ns / 1ps
module stm_focus #(
    parameter int DEPTH = 249
) (
    input wire CLK,
    input wire START,
    input wire [12:0] IDX,
    stm_bus_if.out_focus_port STM_BUS,
    input wire [15:0] SOUND_SPEED,
    output wire [7:0] INTENSITY,
    output wire [7:0] PHASE,
    output wire DOUT_VALID
);

  localparam int CalcLatency = 2 + 2 + 2 + 11 + 34 + 1;

  logic [511:0] data_out;
  logic dout_valid = 1'b0;

  wire signed [17:0] focus_x = data_out[17:0];
  wire signed [17:0] focus_y = data_out[35:18];
  wire signed [17:0] focus_z = data_out[53:36];
  logic signed [15:0] trans_x, trans_y;
  logic signed [17:0] dx, dy;
  logic [35:0] dx2, dy2, dz2, dxy2, d2;
  logic [23:0] sqrt_dout;

  logic [31:0] quo;
  logic [15:0] _unused_rem;

  logic [$clog2(CalcLatency + DEPTH)-1:0] cnt = '0;

  typedef enum logic [1:0] {
    WAITING,
    BRAM_WAIT_0,
    BRAM_WAIT_1,
    CALC
  } state_t;

  state_t state = WAITING;

  dist_mem_tr dist_mem_tr (
      .a  (cnt[7:0]),
      .spo({trans_x, trans_y})
  );

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

  assign STM_BUS.FOCUS_IDX = IDX;
  assign data_out = STM_BUS.VALUE;

  assign INTENSITY = data_out[61:54];
  assign PHASE = quo[7:0];
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
        dout_valid <= cnt > CalcLatency;
        state <= (cnt == CalcLatency + DEPTH - 1) ? WAITING : state;
      end
      default: state <= WAITING;
    endcase
  end

endmodule
