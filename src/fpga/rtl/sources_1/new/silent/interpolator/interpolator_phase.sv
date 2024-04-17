module interpolator_phase #(
    parameter int DEPTH = 249
) (
    input var CLK,
    input var DIN_VALID,
    input var [15:0] UPDATE_RATE,
    input var [15:0] PHASE_IN,
    output var [7:0] PHASE_OUT,
    output var DOUT_VALID
);

  localparam int AddSubLatency = 2;
  localparam int TotalLatency = 2 + AddSubLatency + AddSubLatency + AddSubLatency;

  logic [15:0] phase_in;
  logic [15:0] current;

  logic [15:0] update_rate;
  logic signed [16:0] update_rate_p, update_rate_n;
  assign update_rate_p = $signed({1'b0, update_rate});
  assign update_rate_n = -$signed({1'b0, update_rate});

  logic signed [16:0] step;
  logic signed [17:0] a_fg, b_fg, s_fg;
  logic add_fg = 1'b0;
  logic [15:0] a;
  logic signed [16:0] b, s;
  logic [8:0] cnt;
  logic [7:0] set_cnt;

  logic dout_valid = 0;
  logic [15:0] phase_out;

  assign PHASE_OUT  = phase_out[15:8];
  assign DOUT_VALID = dout_valid;

  typedef enum logic [1:0] {
    WAITING,
    WAIT0,
    RUN
  } state_t;

  state_t state = WAITING;

  BRAM16x256 bram_current (
      .clka (CLK),
      .addra(cnt[7:0]),
      .dina ('0),
      .douta(current),
      .wea  ('0),
      .clkb (CLK),
      .addrb(set_cnt),
      .dinb (phase_out),
      .doutb(),
      .web  (dout_valid)
  );

  delay_fifo #(
      .WIDTH(16),
      .DEPTH(2)
  ) fifo_phase_in (
      .CLK (CLK),
      .DIN (PHASE_IN),
      .DOUT(phase_in)
  );

  delay_fifo #(
      .WIDTH(16),
      .DEPTH(7)
  ) fifo_update_rate (
      .CLK (CLK),
      .DIN (UPDATE_RATE),
      .DOUT(update_rate)
  );

  addsub #(
      .WIDTH(17)
  ) sub_step (
      .CLK(CLK),
      .A  ({1'b0, phase_in}),
      .B  ({1'b0, current}),
      .ADD(1'b0),
      .S  (step)
  );

  addsub #(
      .WIDTH(18)
  ) fg (
      .CLK(CLK),
      .A  (a_fg),
      .B  (b_fg),
      .ADD(add_fg),
      .S  (s_fg)
  );

  delay_fifo #(
      .WIDTH(16),
      .DEPTH(6)
  ) fifo_current (
      .CLK (CLK),
      .DIN (current),
      .DOUT(a)
  );

  addsub #(
      .WIDTH(17)
  ) addsub (
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
        cnt  <= cnt + 1;

        // step 1: should phase go forward or back?
        a_fg <= {step[16], step};
        if (step[16]) begin
          if (-17'sd32768 <= step) begin
            b_fg <= '0;
          end else begin
            b_fg   <= 18'sd65536;
            add_fg <= 1'b1;
          end
        end else begin
          if (step <= 17'sd32768) begin
            b_fg <= '0;
          end else begin
            b_fg   <= 18'sd65536;
            add_fg <= 1'b0;
          end
        end

        // step 2: calculate next phase
        if (s_fg[17]) begin
          b <= (update_rate_n < s_fg) ? s_fg[16:0] : update_rate_n;
        end else begin
          b <= (s_fg < update_rate_p) ? s_fg[16:0] : update_rate_p;
        end

        phase_out <= s[15:0];
        dout_valid <= cnt > TotalLatency;
        set_cnt <= set_cnt + 1;
        state <= (cnt == TotalLatency + DEPTH) ? WAITING : state;
      end
      default: begin
        state <= WAITING;
      end
    endcase
  end

endmodule
