`timescale 1ns / 1ps
module modulation_multiplier #(
    parameter int DEPTH = 249
) (
    input wire CLK,
    input wire DIN_VALID,
    input wire [7:0] INTENSITY_IN,
    output wire [7:0] INTENSITY_OUT,
    output wire DOUT_VALID,
    modulation_bus_if.out_port MOD_BUS,
    input wire [14:0] IDX[params::NumSegment],
    input wire SEGMENT,
    input wire STOP,
    output wire [14:0] DEBUG_IDX,
    output wire DEBUG_SEGMENT,
    output wire DEBUG_STOP
);

  localparam int Latency = 1;

  logic dout_valid = 1'b0;

  logic [7:0] mod;
  logic [14:0] idx = '0;
  logic stop = 1'b0, segment = 1'b0;
  logic [$clog2(DEPTH+(Latency+1))-1:0] cnt;
  logic [7:0] intensity_buf;
  logic [16:0] p;

  assign MOD_BUS.IDX = idx;
  assign mod = MOD_BUS.VALUE;
  assign MOD_BUS.SEGMENT = segment;

  assign INTENSITY_OUT = p[15:8];
  assign DOUT_VALID = dout_valid;

  assign DEBUG_IDX = idx;
  assign DEBUG_SEGMENT = segment;
  assign DEBUG_STOP = stop;

  delay_fifo #(
      .WIDTH(8),
      .DEPTH(3)
  ) delay_fifo_intensity (
      .CLK (CLK),
      .DIN (INTENSITY_IN),
      .DOUT(intensity_buf)
  );

  mult_8x9 mult (
      .CLK(CLK),
      .A  (intensity_buf),
      .B  ({1'b0, mod} + 9'd1),
      .P  (p)
  );

  typedef enum logic [2:0] {
    IDLE,
    WAIT_MOD_LOAD_0,
    WAIT_MOD_LOAD_1,
    WAIT_MUL_0,
    WAIT_MUL_1,
    RUN
  } state_t;

  state_t state = IDLE;

  always_ff @(posedge CLK) begin
    case (state)
      IDLE: begin
        dout_valid <= 1'b0;
        if (DIN_VALID) begin
          stop <= STOP;
          if (~STOP) begin
            idx <=    IDX[SEGMENT];
            segment <= SEGMENT;
          end
          state <= WAIT_MOD_LOAD_0;
        end
      end
      WAIT_MOD_LOAD_0: begin
        state <= WAIT_MOD_LOAD_1;
      end
      WAIT_MOD_LOAD_1: begin
        state <= WAIT_MUL_0;
      end
      WAIT_MUL_0: begin
        state <= WAIT_MUL_1;
      end
      WAIT_MUL_1: begin
        cnt   <= '0;
        state <= RUN;
      end
      RUN: begin
        cnt <= cnt + 1;
        dout_valid <= 1'b1;
        state <= (cnt == DEPTH - 1) ? IDLE : state;
      end
      default: state <= IDLE;
    endcase
  end

endmodule
