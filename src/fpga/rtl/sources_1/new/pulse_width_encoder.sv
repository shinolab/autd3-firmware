`timescale 1ns / 1ps
module pulse_width_encoder #(
    parameter int DEPTH = 249
) (
    input wire CLK,
    duty_table_bus_if.out_port DUTY_TABLE_BUS,
    input wire DIN_VALID,
    input wire [15:0] INTENSITY_IN,
    input wire [7:0] PHASE_IN,
    output var [7:0] PULSE_WIDTH_OUT,
    output var [7:0] PHASE_OUT,
    output var DOUT_VALID
);

  logic [14:0] addr;
  logic [7:0] dout;

  logic dout_valid;

  logic [$clog2(DEPTH)-1:0] cnt;

  assign addr = INTENSITY_IN[15:1];

  typedef enum logic {
    WAITING,
    RUN
  } state_t;

  state_t state = WAITING;

  delay_fifo #(
      .WIDTH(8),
      .DEPTH(2)
  ) phase_fifo (
      .CLK (CLK),
      .DIN (PHASE_IN),
      .DOUT(PHASE_OUT)
  );

  assign DUTY_TABLE_BUS.IDX = addr;
  assign dout = DUTY_TABLE_BUS.VALUE;

  assign PULSE_WIDTH_OUT = dout;
  assign DOUT_VALID = dout_valid;

  always_ff @(posedge CLK) begin
    case (state)
      WAITING: begin
        dout_valid <= 1'b0;
        if (DIN_VALID) begin
          cnt   <= 0;
          state <= RUN;
        end
      end
      RUN: begin
        cnt <= cnt + 1;
        dout_valid <= 1'b1;
        state <= cnt == DEPTH - 1 ? WAITING : state;
      end
      default: begin
      end
    endcase
  end

endmodule
