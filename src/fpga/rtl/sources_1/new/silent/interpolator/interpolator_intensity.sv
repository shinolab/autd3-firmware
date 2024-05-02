`timescale 1ns / 1ps
module interpolator_intensity #(
    parameter int DEPTH = 249
) (
    input var CLK,
    input var DIN_VALID,
    input var [15:0] UPDATE_RATE,
    input var [15:0] INTENSITY_IN,
    output var [15:0] INTENSITY_OUT,
    output var DOUT_VALID
);

  localparam int AddSubLatency = 2;
  localparam int TotalLatency = 1 + AddSubLatency + AddSubLatency;

  logic [15:0] intensity_in;
  logic [15:0] current;

  logic [15:0] update_rate;
  logic signed [16:0] update_rate_p, update_rate_n;
  assign update_rate_p = $signed({1'b0, update_rate});
  assign update_rate_n = -$signed({1'b0, update_rate});

  logic signed [16:0] step;
  logic [15:0] a;
  logic signed [16:0] b, s;
  logic [7:0] cnt, set_cnt;

  logic dout_valid = 0;
  logic [15:0] intensity_out;

  assign INTENSITY_OUT = intensity_out;
  assign DOUT_VALID = dout_valid;

  typedef enum logic [1:0] {
    WAITING,
    WAIT0,
    RUN
  } state_t;

  state_t state = WAITING;

  BRAM16x256 bram_current (
      .clka (CLK),
      .addra(cnt),
      .dina ('0),
      .douta(current),
      .wea  ('0),
      .clkb (CLK),
      .addrb(set_cnt),
      .dinb (intensity_out),
      .doutb(),
      .web  (dout_valid)
  );

  delay_fifo #(
      .WIDTH(16),
      .DEPTH(2)
  ) fifo_intensity_in (
      .CLK (CLK),
      .DIN (INTENSITY_IN),
      .DOUT(intensity_in)
  );

  delay_fifo #(
      .WIDTH(16),
      .DEPTH(4)
  ) fifo_update_rate (
      .CLK (CLK),
      .DIN (UPDATE_RATE),
      .DOUT(update_rate)
  );

  addsub #(
      .WIDTH(17)
  ) sub_step (
      .CLK(CLK),
      .A  ({1'b0, intensity_in}),
      .B  ({1'b0, current}),
      .ADD(1'b0),
      .S  (step)
  );

  delay_fifo #(
      .WIDTH(16),
      .DEPTH(3)
  ) fifo_current (
      .CLK (CLK),
      .DIN (current),
      .DOUT(a)
  );

  addsub #(
      .WIDTH(17)
  ) add (
      .CLK(CLK),
      .A  ({1'b0, a}),
      .B  (b),
      .ADD(1'b1),
      .S  (s)
  );

  always_ff @(posedge CLK) begin
    case (state)
      WAITING: begin
        dout_valid <= 1'b0;
        cnt <= '0;
        set_cnt <= 8'hFF - TotalLatency;
        state <= DIN_VALID ? WAIT0 : state;
      end
      WAIT0: begin
        cnt   <= cnt + 1;
        state <= RUN;
      end
      RUN: begin
        cnt <= cnt + 1;

        if (step[16]) begin
          b <= (update_rate_n < step) ? step : update_rate_n;
        end else begin
          b <= (step < update_rate_p) ? step : update_rate_p;
        end

        intensity_out <= s[15:0];
        dout_valid <= cnt > TotalLatency;
        set_cnt <= set_cnt + 1;
        state <= (cnt == TotalLatency + DEPTH) ? WAITING : state;
      end
      default: state <= WAITING;
    endcase
  end

endmodule
