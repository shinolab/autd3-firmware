`timescale 1ns / 1ps
module pulse_width_encoder #(
    parameter int DEPTH = 249
) (
    input wire CLK,
    input wire settings::pulse_width_encoder_settings_t PULSE_WIDTH_ENCODER_SETTINGS,
    duty_table_bus_if.out_port DUTY_TABLE_BUS,
    input wire DIN_VALID,
    input wire [15:0] INTENSITY_IN,
    input wire [7:0] PHASE_IN,
    output var [8:0] PULSE_WIDTH_OUT,
    output var [7:0] PHASE_OUT,
    output var DOUT_VALID
);

  localparam int Latency = 1;

  logic [15:0] addr;
  logic [ 7:0] dout;

  logic full_width_in, full_width_out;

  logic [8:0] pulse_width_out;
  logic dout_valid;

  logic [$clog2(DEPTH+(2+Latency+1))-1:0] cnt;

  typedef enum logic {
    WAITING,
    RUN
  } state_t;

  state_t state = WAITING;

  delay_fifo #(
      .WIDTH(1),
      .DEPTH(2)
  ) full_width_fifo (
      .CLK (CLK),
      .DIN (full_width_in),
      .DOUT(full_width_out)
  );

  delay_fifo #(
      .WIDTH(8),
      .DEPTH(4)
  ) phase_fifo (
      .CLK (CLK),
      .DIN (PHASE_IN),
      .DOUT(PHASE_OUT)
  );

  assign DUTY_TABLE_BUS.IDX = addr;
  assign dout = DUTY_TABLE_BUS.VALUE;

  assign PULSE_WIDTH_OUT = pulse_width_out;
  assign DOUT_VALID = dout_valid;

  always_ff @(posedge CLK) begin
    case (state)
      WAITING: begin
        dout_valid <= 1'b0;
        if (DIN_VALID) begin
          cnt   <= 0;
          addr  <= INTENSITY_IN;
          state <= RUN;
        end
      end
      RUN: begin
        addr <= INTENSITY_IN;
        cnt  <= cnt + 1;
        if (cnt > Latency) begin
          dout_valid <= 1'b1;
          pulse_width_out <= {full_width_out, dout[7:0]};
          state <= cnt == Latency + DEPTH ? WAITING : state;
        end
      end
      default: begin
      end
    endcase
  end

  always_ff @(posedge CLK)
    full_width_in <= INTENSITY_IN >= PULSE_WIDTH_ENCODER_SETTINGS.FULL_WIDTH_START;

endmodule
