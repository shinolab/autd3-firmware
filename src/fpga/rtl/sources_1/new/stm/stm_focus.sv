`timescale 1ns / 1ps
module stm_focus #(
    parameter int DEPTH = 249,
    parameter string MODE = "NearestEven"
) (
    input wire CLK,
    input wire START,
    input wire [15:0] IDX,
    stm_bus_if.out_focus_port STM_BUS,
    input wire [15:0] SOUND_SPEED,
    input wire [7:0] NUM_FOCI,
    output wire [7:0] INTENSITY,
    output wire [7:0] PHASE,
    output wire DOUT_VALID
);

  localparam int CalcLatency = 68;

  logic [15:0] base_idx, idx;
  logic [63:0] data_out;

  logic [7:0] phase_out;
  logic dout_valid;

  logic [7:0] tr_idx = '0;
  logic signed [15:0] trans_x, trans_y;

  logic [7:0] num_foci;
  logic signed [17:0]
      focus_x[params::NumFociMax], focus_y[params::NumFociMax], focus_z[params::NumFociMax];
  logic [7:0] intensity_or_offset[params::NumFociMax];

  logic [$clog2(params::NumFociMax+CalcLatency)-1:0] cnt;
  logic [$clog2(DEPTH)-1:0] output_cnt;

  logic [7:0] cos[params::NumFociMax];
  logic [7:0] sin[params::NumFociMax];

  assign INTENSITY  = intensity_or_offset[0];
  assign PHASE      = phase_out;
  assign DOUT_VALID = dout_valid;

  dist_mem_tr dist_mem_tr (
      .a  (tr_idx),
      .spo({trans_x, trans_y})
  );

  typedef enum logic [3:0] {
    IDLE,
    WAIT_IDX_0,
    WAIT_IDX_1,
    WAIT_MEM_LOAD_0,
    WAIT_MEM_LOAD_1,
    WAIT_MEM_LOAD_2,
    INPUT_FOCUS,
    WAIT_CALC,
    OUTPUT
  } state_t;

  state_t state = IDLE;

  logic [7:0] _idx_unused;
  mult #(
      .WIDTH_A(16),
      .WIDTH_B(8)
  ) mult_idx (
      .CLK(CLK),
      .A  (IDX),
      .B  (NUM_FOCI),
      .P  ({_idx_unused, base_idx})
  );

  assign STM_BUS.FOCUS_IDX = idx;
  assign data_out = STM_BUS.VALUE;

  always_ff @(posedge CLK) begin
    case (state)
      IDLE: begin
        dout_valid <= 1'b0;
        if (START) begin
          num_foci <= NUM_FOCI;
          state <= WAIT_IDX_0;
        end
      end
      WAIT_IDX_0: state <= WAIT_IDX_1;
      WAIT_IDX_1: state <= WAIT_MEM_LOAD_0;
      WAIT_MEM_LOAD_0: begin
        idx   <= base_idx;
        state <= WAIT_MEM_LOAD_1;
      end
      WAIT_MEM_LOAD_1: begin
        idx   <= idx + 1;
        state <= WAIT_MEM_LOAD_2;
      end
      WAIT_MEM_LOAD_2: begin
        idx   <= idx + 1;
        cnt   <= '0;
        state <= INPUT_FOCUS;
      end
      INPUT_FOCUS: begin
        idx <= idx + 1;
        cnt <= cnt + 1;

        focus_x[cnt] <= data_out[17:0];
        focus_y[cnt] <= data_out[35:18];
        focus_z[cnt] <= data_out[53:36];
        intensity_or_offset[cnt] <= data_out[61:54];

        if (cnt == params::NumFociMax - 1) begin
          tr_idx <= '0;
          state  <= WAIT_CALC;
        end
      end
      WAIT_CALC: begin
        cnt <= cnt + 1;
        tr_idx <= tr_idx + 1;
        if (cnt == params::NumFociMax - 1 + CalcLatency) begin
          output_cnt <= '0;
          state <= OUTPUT;
        end
      end
      OUTPUT: begin
        cnt <= cnt + 1;
        tr_idx <= tr_idx + 1;
        output_cnt <= output_cnt + 1;
        dout_valid <= 1'b1;
        if (output_cnt == DEPTH - 1) begin
          state <= IDLE;
        end
      end
      default: state <= IDLE;
    endcase
  end

  focus_calc #(
      .MODE(MODE)
  ) focus_calc_0 (
      .CLK(CLK),
      .FOCUS_X(focus_x[0]),
      .FOCUS_Y(focus_y[0]),
      .FOCUS_Z(focus_z[0]),
      .TRANS_X(trans_x),
      .TRANS_Y(trans_y),
      .SOUND_SPEED(SOUND_SPEED),
      .OFFSET(8'd0),
      .SIN(sin[0]),
      .COS(cos[0])
  );
  for (genvar i = 1; i < params::NumFociMax; i++) begin : gen_focus_calc
    focus_calc #(
        .MODE(MODE)
    ) focus_calc (
        .CLK(CLK),
        .FOCUS_X(focus_x[i]),
        .FOCUS_Y(focus_y[i]),
        .FOCUS_Z(focus_z[i]),
        .TRANS_X(trans_x),
        .TRANS_Y(trans_y),
        .SOUND_SPEED(SOUND_SPEED),
        .OFFSET(intensity_or_offset[i]),
        .SIN(sin[i]),
        .COS(cos[i])
    );
  end

  logic [8:0] sin_01, sin_23, sin_45, sin_67;
  logic [8:0] cos_01, cos_23, cos_45, cos_67;
  logic [9:0] sin_0123, sin_4567;
  logic [9:0] cos_0123, cos_4567;
  logic [10:0] sin_acc, cos_acc;
  logic [7:0] sin_ave, cos_ave;

  logic [7:0] _sin_quo_unuse, _cos_quo_unuse;
  logic [7:0] _sin_rem_unuse, _cos_rem_unuse;
  div_16_8 div_16_8_sin (
      .s_axis_dividend_tdata({5'd0, sin_acc}),
      .s_axis_dividend_tvalid(1'b1),
      .s_axis_divisor_tdata(num_foci),
      .s_axis_divisor_tvalid(1'b1),
      .aclk(CLK),
      .m_axis_dout_tdata({_sin_quo_unuse, sin_ave, _sin_rem_unuse}),
      .m_axis_dout_tvalid()
  );
  div_16_8 div_16_8_cos (
      .s_axis_dividend_tdata({5'd0, cos_acc}),
      .s_axis_dividend_tvalid(1'b1),
      .s_axis_divisor_tdata(num_foci),
      .s_axis_divisor_tvalid(1'b1),
      .aclk(CLK),
      .m_axis_dout_tdata({_cos_quo_unuse, cos_ave, _cos_rem_unuse}),
      .m_axis_dout_tvalid()
  );

  logic [13:0] atan_key;
  logic [ 7:0] phase;
  BRAM_ATAN bram_atan (
      .clka (CLK),
      .addra(atan_key),
      .douta(phase)
  );

  always_ff @(posedge CLK) begin
    sin_01 <= sin[0] + (num_foci <= 8'd1 ? 8'd0 : sin[1]);
    sin_23 <= (num_foci <= 8'd2 ? 8'd0 : sin[2]) + (num_foci <= 8'd3 ? 8'd0 : sin[3]);
    sin_45 <= (num_foci <= 8'd4 ? 8'd0 : sin[4]) + (num_foci <= 8'd5 ? 8'd0 : sin[5]);
    sin_67 <= (num_foci <= 8'd6 ? 8'd0 : sin[6]) + (num_foci <= 8'd7 ? 8'd0 : sin[7]);
    cos_01 <= cos[0] + (num_foci <= 8'd1 ? 8'd0 : cos[1]);
    cos_23 <= (num_foci <= 8'd2 ? 8'd0 : cos[2]) + (num_foci <= 8'd3 ? 8'd0 : cos[3]);
    cos_45 <= (num_foci <= 8'd4 ? 8'd0 : cos[4]) + (num_foci <= 8'd5 ? 8'd0 : cos[5]);
    cos_67 <= (num_foci <= 8'd6 ? 8'd0 : cos[6]) + (num_foci <= 8'd7 ? 8'd0 : cos[7]);
    sin_0123 <= sin_01 + sin_23;
    sin_4567 <= sin_45 + sin_67;
    cos_0123 <= cos_01 + cos_23;
    cos_4567 <= cos_45 + cos_67;
    sin_acc <= sin_0123 + sin_4567;
    cos_acc <= cos_0123 + cos_4567;
    atan_key <= {sin_ave[7:1], cos_ave[7:1]};
    phase_out <= phase;
  end

endmodule
