`timescale 1ns / 1ps
module phase_filter #(
    parameter int DEPTH = 249
) (
    input var CLK,
    filter_bus_if.out_port FILTER_BUS,
    input var DIN_VALID,
    input var [7:0] PHASE_IN,
    output var [7:0] PHASE_OUT,
    output var DOUT_VALID
);

  localparam int AddSubLatency = 1;

  logic [7:0] phase_buf;
  logic [7:0] phase_f;

  logic [8:0] s_phase;
  logic [$clog2(DEPTH+AddSubLatency)-1:0] cnt;

  logic dout_valid = 0;

  assign PHASE_OUT  = phase_f;
  assign DOUT_VALID = dout_valid;

  logic [7:0] bus_addr = '0;
  logic [7:0] phase_filter_value;

  assign FILTER_BUS.ADDR = bus_addr;
  assign phase_filter_value = FILTER_BUS.DOUT;

  typedef enum logic [1:0] {
    WAITING,
    WAITING_BRAM_0,
    WAITING_BRAM_1,
    RUN
  } state_t;

  state_t state = WAITING;

  delay_fifo #(
      .WIDTH(8),
      .DEPTH(3)
  ) delay_fifo_phase (
      .CLK (CLK),
      .DIN (PHASE_IN),
      .DOUT(phase_buf)
  );

  addsub #(
      .WIDTH(9)
  ) addsub_phase (
      .CLK(CLK),
      .A  ({1'b0, phase_buf}),
      .B  ({1'b0, phase_filter_value}),
      .ADD(1'b1),
      .S  (s_phase)
  );

  always_ff @(posedge CLK) begin
    case (state)
      WAITING: begin
        bus_addr   <= '0;
        dout_valid <= 1'b0;
        if (DIN_VALID) begin
          cnt   <= '0;
          state <= WAITING_BRAM_0;
        end
      end
      WAITING_BRAM_0: begin
        bus_addr <= bus_addr + 1;
        state <= WAITING_BRAM_1;
      end
      WAITING_BRAM_1: begin
        bus_addr <= bus_addr + 1;
        state <= RUN;
      end
      RUN: begin
        bus_addr   <= bus_addr + 1;
        cnt        <= cnt + 1;
        phase_f    <= s_phase[7:0];
        dout_valid <= cnt > AddSubLatency;
        state      <= (cnt == AddSubLatency + DEPTH) ? WAITING : state;
      end
    endcase
  end

endmodule
