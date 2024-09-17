`timescale 1ns / 1ps
module phase_correction #(
    parameter int DEPTH = 249
) (
    input wire CLK,
    phase_corr_bus_if.out_port PHASE_CORR_BUS,
    input wire DIN_VALID,
    input wire [7:0] PHASE_IN,
    output wire [7:0] PHASE_OUT,
    output wire DOUT_VALID
);

  logic [7:0] addr;
  logic [7:0] dout;

  logic dout_valid;
  logic [7:0] phase_in, phase_out;

  typedef enum logic [2:0] {
    IDLE,
    WAIT_BRAM_0,
    WAIT_BRAM_1,
    WAIT_ADD_0,
    WAIT_ADD_1,
    RUN
  } state_t;

  state_t state = IDLE;

  delay_fifo #(
      .WIDTH(8),
      .DEPTH(3)
  ) phase_in_fifo (
      .CLK (CLK),
      .DIN (PHASE_IN),
      .DOUT(phase_in)
  );

  delay_fifo #(
      .WIDTH(8),
      .DEPTH(1)
  ) phase_out_fifo (
      .CLK (CLK),
      .DIN (phase_out),
      .DOUT(PHASE_OUT)
  );

  addsub #(
      .WIDTH(8)
  ) addsub (
      .CLK(CLK),
      .A  (phase_in),
      .B  (dout),
      .ADD(1'b1),
      .S  (phase_out)
  );

  assign PHASE_CORR_BUS.IDX = addr;
  assign dout = PHASE_CORR_BUS.VALUE;

  assign DOUT_VALID = dout_valid;

  always_ff @(posedge CLK) begin
    case (state)
      IDLE: begin
        dout_valid <= 1'b0;
        if (DIN_VALID) begin
          addr  <= 0;
          state <= WAIT_BRAM_0;
        end
      end
      WAIT_BRAM_0: begin
        addr  <= addr + 1;
        state <= WAIT_BRAM_1;
      end
      WAIT_BRAM_1: begin
        addr  <= addr + 1;
        state <= WAIT_ADD_0;
      end
      WAIT_ADD_0: begin
        addr  <= addr + 1;
        state <= WAIT_ADD_1;
      end
      WAIT_ADD_1: begin
        addr  <= addr + 1;
        state <= RUN;
      end
      RUN: begin
        addr <= addr + 1;
        dout_valid <= 1'b1;
        state <= addr == DEPTH - 1 + 4 ? IDLE : state;
      end
      default: begin
      end
    endcase
  end

endmodule
