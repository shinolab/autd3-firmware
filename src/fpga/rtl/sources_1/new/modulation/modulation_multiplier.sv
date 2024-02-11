`timescale 1ns / 1ps
module modulation_multiplier #(
    parameter int DEPTH = 249
) (
    input wire CLK,
    input wire DIN_VALID,
    input wire [7:0] INTENSITY_IN,
    output wire [15:0] INTENSITY_OUT,
    input wire [7:0] PHASE_IN,
    output wire [7:0] PHASE_OUT,
    output wire DOUT_VALID,
    modulation_bus_if.out_port MOD_BUS,
    input wire [14:0] IDX_0,
    input wire [14:0] IDX_1,
    input wire SEGMENT,
    input wire STOP,
    output wire [14:0] DEBUG_IDX,
    output wire DEBUG_SEGMENT,
    output wire DEBUG_STOP
);

  localparam int Latency = 1;

  logic segment;
  logic stop;

  logic dout_valid = 1'b0;

  logic [7:0] mod;
  logic [14:0] idx = '0;
  logic stop_buf = 1'b0, segment_buf = 1'b0;
  logic [$clog2(DEPTH+(Latency+1))-1:0] cnt, set_cnt;
  logic [7:0] intensity_buf;
  logic signed [17:0] p;

  assign segment = SEGMENT;
  assign stop = STOP;

  assign MOD_BUS.IDX = idx;
  assign mod = MOD_BUS.VALUE;
  assign MOD_BUS.SEGMENT = segment_buf;

  assign DOUT_VALID = dout_valid;
  assign INTENSITY_OUT = p[15:0];

  assign DEBUG_IDX = idx;
  assign DEBUG_SEGMENT = segment_buf;
  assign DEBUG_STOP = stop_buf;

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
          if (stop === 1'b0) begin
            idx <= segment == 1'b0 ? IDX_0 : IDX_1;
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
          if (set_cnt === DEPTH - 1) begin
            state <= WAITING;
          end
        end
      end
      default: begin
      end
    endcase
  end

endmodule
