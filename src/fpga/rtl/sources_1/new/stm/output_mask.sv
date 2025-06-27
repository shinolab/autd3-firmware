module output_mask #(
    parameter int DEPTH = 249
) (
    input wire CLK,
    output_mask_bus_if.out_port OUTPUT_MASK_BUS,
    input wire DIN_VALID,
    input wire [7:0] INTENSITY_IN,
    output wire [7:0] INTENSITY_OUT,
    input wire [7:0] PHASE_IN,
    output wire [7:0] PHASE_OUT,
    output wire DOUT_VALID
);

  logic [  7:0] cnt;
  logic [255:0] dout;

  logic [7:0] intensity_in, intensity_out;

  typedef enum logic {
    IDLE,
    RUN
  } state_t;

  state_t state = IDLE;

  assign dout = OUTPUT_MASK_BUS.VALUE;

  assign INTENSITY_OUT = intensity_out;

  delay_fifo #(
      .WIDTH(8),
      .DEPTH(2)
  ) phase_out_fifo (
      .CLK (CLK),
      .DIN (PHASE_IN),
      .DOUT(PHASE_OUT)
  );

  delay_fifo #(
      .WIDTH(1),
      .DEPTH(2)
  ) dout_valid_fifo (
      .CLK (CLK),
      .DIN (DIN_VALID),
      .DOUT(DOUT_VALID)
  );

  always_ff @(posedge CLK) begin
    case (state)
      IDLE: begin
        if (DIN_VALID) begin
          cnt   <= '0;
          state <= RUN;
        end
      end
      RUN: begin
        cnt <= cnt + 1;
        intensity_out <= dout[cnt] ? intensity_in : 8'h00;
        state <= cnt == DEPTH - 1 ? IDLE : state;
      end
      default: begin
      end
    endcase
  end

  always_ff @(posedge CLK) intensity_in <= INTENSITY_IN;

endmodule
