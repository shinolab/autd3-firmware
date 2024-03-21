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

  localparam int AddSubLatency = 2;

  logic [7:0] phase_buf;

  logic signed [9:0] a_phase, b_phase, s_phase;
  logic signed [9:0] a_phase_fold, b_phase_fold, s_phase_fold;
  logic add_fold;
  logic [$clog2(DEPTH+(AddSubLatency+1)*2)-1:0] calc_cnt, fold_cnt, set_cnt;

  logic [7:0] phase_f;

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
      .WIDTH(10)
  ) addsub_phase (
      .CLK(CLK),
      .A  (a_phase),
      .B  (b_phase),
      .ADD(1'b1),
      .S  (s_phase)
  );

  addsub #(
      .WIDTH(10)
  ) addsub_phase_fold (
      .CLK(CLK),
      .A  (a_phase_fold),
      .B  (b_phase_fold),
      .ADD(add_fold),
      .S  (s_phase_fold)
  );

  always_ff @(posedge CLK) begin
    case (state)
      WAITING: begin
        dout_valid <= 1'b0;
        if (DIN_VALID) begin
          calc_cnt <= '0;
          fold_cnt <= '0;
          set_cnt <= '0;
          bus_addr <= '0;

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
        bus_addr <= bus_addr + 1;

        // step 1: calculate next pulse_width/phase
        a_phase <= {1'b0, phase_buf};
        b_phase <= phase_filter_value;
        calc_cnt <= calc_cnt + 1;

        // step 2: make pulse_width/phase be in [0, T-1]
        a_phase_fold <= s_phase;
        if (s_phase >= 10'sd512) begin
          b_phase_fold <= 10'sd512;
          add_fold <= 1'b0;
        end else if (s_phase < 10'sd0) begin
          b_phase_fold <= 10'sd512;
          add_fold <= 1'b1;
        end else begin
          b_phase_fold <= '0;
          add_fold <= 1'b1;
        end

        if (calc_cnt > AddSubLatency) begin
          fold_cnt <= fold_cnt + 1;
        end

        if (fold_cnt > AddSubLatency) begin
          dout_valid <= 1'b1;
          phase_f <= s_phase_fold[7:0];
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

endmodule
