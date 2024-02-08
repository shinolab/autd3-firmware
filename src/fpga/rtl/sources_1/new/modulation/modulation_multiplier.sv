`timescale 1ns / 1ps
module modulation_multipiler #(
    parameter int DEPTH = 249
) (
    input var CLK,
    input var DIN_VALID,
    input var [7:0] INTENSITY_IN,
    output var [15:0] INTENSITY_OUT,
    input var [7:0] PHASE_IN,
    output var [7:0] PHASE_OUT,
    output var DOUT_VALID,
    modulation_bus_if.out_port MOD_BUS,
    mod_cnt_if.multiplier_port MOD_CNT,
    output var [14:0] DEBUG_IDX
);

  localparam int Latency = 1;

  logic [14:0] idx_0, idx_1;
  logic segment;
  logic stop;

  logic dout_valid = 1'b0;

  logic [7:0] mod;
  logic [14:0] idx;
  logic stop_buf, segment_buf;
  logic [$clog2(DEPTH+(Latency+1))-1:0] cnt, set_cnt;
  logic [7:0] intensity_buf;
  logic signed [17:0] p;

  assign segment = MOD_CNT.SEGMENT;
  assign stop = MOD_CNT.STOP;

  assign MOD_BUS.IDX = idx;
  assign mod = MOD_BUS.VALUE;
  assign MOD_BUS.SEGMENT = segment_buf;

  assign DOUT_VALID = dout_valid;
  assign INTENSITY_OUT = p[15:0];

  assign DEBUG_IDX = idx;

  delay_fifo #(
      .WIDTH(8),
      .DEPTH(3)
  ) delay_fifo_intensity (
      .CLK (CLK),
      .DIN (INTENSITY_IN),
      .DOUT(intensity_buf)
  );

  delay_fifo #(
      .WIDTH(8),
      .DEPTH(6)
  ) delay_fifo_phase (
      .CLK (CLK),
      .DIN (PHASE_IN),
      .DOUT(PHASE_OUT)
  );

  mult #(
      .WIDTH_A(9),
      .WIDTH_B(9)
  ) mult (
      .CLK(CLK),
      .A  ({1'b0, intensity_buf}),
      .B  ({1'b0, mod}),
      .P  (p)
  );

  typedef enum logic [2:0] {
    WAITING,
    WAIT_MOD_LOAD_0,
    WAIT_MOD_LOAD_1,
    MOD_LOAD,
    RUN
  } state_t;

  state_t state = WAITING;

  always_ff @(posedge CLK) begin
    case (state)
      WAITING: begin
        dout_valid <= 1'b0;
        if (DIN_VALID) begin
          cnt <= 0;
          set_cnt <= 0;
          stop_buf <= stop;
          if (stop == 1'b0) begin
            idx <= segment == 1'b0 ? idx_0 : idx_1;
            segment_buf <= segment;
          end
          state <= WAIT_MOD_LOAD_0;
        end
      end
      WAIT_MOD_LOAD_0: begin
        state <= WAIT_MOD_LOAD_1;
      end
      WAIT_MOD_LOAD_1: begin
        state <= RUN;
      end
      RUN: begin
        cnt <= cnt + 1;
        if (cnt > Latency) begin
          dout_valid <= 1'b1;
          set_cnt <= set_cnt + 1;
          if (set_cnt == DEPTH - 1) begin
            state <= WAITING;
          end
        end
      end
      default: begin
      end
    endcase
  end

  // In order to align idx_0 and idx_1 with segment and stop, we need to buffer them
  always_ff @(posedge CLK) begin
    idx_0 <= MOD_CNT.IDX_0;
    idx_1 <= MOD_CNT.IDX_1;
  end

endmodule
