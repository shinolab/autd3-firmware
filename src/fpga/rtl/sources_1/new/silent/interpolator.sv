module interpolator #(
    parameter int DEPTH = 249
) (
    input var CLK,
    input var DIN_VALID,
    input var [15:0] UPDATE_RATE_INTENSITY,
    input var [15:0] UPDATE_RATE_PHASE,
    input var [15:0] INTENSITY_IN,
    input var [15:0] PHASE_IN,
    output var [15:0] INTENSITY_OUT,
    output var [7:0] PHASE_OUT,
    output var DOUT_VALID
);

  localparam int AddSubLatency = 2;

  logic signed [17:0] update_rate_intensity[7];
  logic signed [17:0] update_rate_intensity_n[7];
  logic signed [17:0] update_rate_phase[7];
  logic signed [17:0] update_rate_phase_n[7];
  logic [15:0] intensity_buf;
  logic [15:0] phase_buf;

  logic signed [17:0] current_intensity[DEPTH] = '{DEPTH{0}};
  logic signed [17:0] current_phase[DEPTH] = '{DEPTH{0}};
  logic signed [17:0] a_intensity_step, b_intensity_step, intensity_step;
  logic signed [17:0] intensity_step_buf[3];
  logic signed [17:0] a_phase_step, b_phase_step, phase_step;
  logic signed [17:0] a_phase_fg, b_phase_fg, s_phase_fg;
  logic add_phase_fg;
  logic signed [17:0] a_intensity, b_intensity, s_intensity;
  logic signed [17:0] a_phase, b_phase, s_phase;
  logic [$clog2(DEPTH+AddSubLatency*3+1)-1:0] calc_cnt, calc_step_cnt, set_cnt;

  logic [15:0] intensity_s;
  logic [7:0] phase_s;

  logic dout_valid = 0;

  assign INTENSITY_OUT = intensity_s;
  assign PHASE_OUT = phase_s;
  assign DOUT_VALID = dout_valid;

  typedef enum logic {
    WAITING,
    RUN
  } state_t;

  state_t state = WAITING;

  addsub #(
      .WIDTH(18)
  ) sub_intensity_step (
      .CLK(CLK),
      .A  (a_intensity_step),
      .B  (b_intensity_step),
      .ADD(1'b0),
      .S  (intensity_step)
  );

  addsub #(
      .WIDTH(18)
  ) sub_phase_step (
      .CLK(CLK),
      .A  (a_phase_step),
      .B  (b_phase_step),
      .ADD(1'b0),
      .S  (phase_step)
  );

  addsub #(
      .WIDTH(18)
  ) phase_fg (
      .CLK(CLK),
      .A  (a_phase_fg),
      .B  (b_phase_fg),
      .ADD(add_phase_fg),
      .S  (s_phase_fg)
  );

  addsub #(
      .WIDTH(18)
  ) add_intensity (
      .CLK(CLK),
      .A  (a_intensity),
      .B  (b_intensity),
      .ADD(1'b1),
      .S  (s_intensity)
  );

  addsub #(
      .WIDTH(18)
  ) addsub_phase (
      .CLK(CLK),
      .A  (a_phase),
      .B  (b_phase),
      .ADD(1'b1),
      .S  (s_phase)
  );

  always_ff @(posedge CLK) begin
    case (state)
      WAITING: begin
        dout_valid <= 1'b0;
        if (DIN_VALID) begin
          calc_step_cnt <= '0;
          calc_cnt <= '0;
          set_cnt <= '0;

          state <= RUN;
        end
      end
      RUN: begin
        // intensity 1: calculate step
        a_intensity_step <= {2'b00, intensity_buf};
        b_intensity_step <= current_intensity[calc_step_cnt];

        // intensity 2: wait phase
        intensity_step_buf[0] <= intensity_step;
        intensity_step_buf[1] <= intensity_step_buf[0];
        intensity_step_buf[2] <= intensity_step_buf[1];

        // intensity 3: calculate next intensity
        a_intensity <= current_intensity[calc_cnt];
        if (intensity_step_buf[2][17] == 1'b0) begin
          b_intensity <= (intensity_step_buf[2] < update_rate_intensity[6]) ? intensity_step_buf[2] : update_rate_intensity[6];
        end else begin
          b_intensity <= (update_rate_intensity_n[6] < intensity_step_buf[2]) ? intensity_step_buf[2] : update_rate_intensity_n[6];
        end

        // phase 1: calculate step
        a_phase_step <= {2'b00, phase_buf};
        b_phase_step <= current_phase[calc_step_cnt];

        // phase 2: should phase go forward or back?
        a_phase_fg   <= phase_step;
        if (phase_step[17] == 1'b0) begin
          if (phase_step <= 18'sd32768) begin
            b_phase_fg <= '0;
          end else begin
            b_phase_fg   <= 18'sd65536;
            add_phase_fg <= 1'b0;
          end
        end else begin
          if (-18'sd32768 <= phase_step) begin
            b_phase_fg <= '0;
          end else begin
            b_phase_fg   <= 18'sd65536;
            add_phase_fg <= 1'b1;
          end
        end

        // phase 3: calculate next phase
        a_phase <= current_phase[calc_cnt];
        if (s_phase_fg[17] == 1'b0) begin
          b_phase <= (s_phase_fg < update_rate_phase[6]) ? s_phase_fg : update_rate_phase[6];
        end else begin
          b_phase <= (update_rate_phase_n[6] < s_phase_fg) ? s_phase_fg : update_rate_phase_n[6];
        end

        calc_step_cnt <= calc_step_cnt + 1;
        if (calc_step_cnt > 1 + AddSubLatency + AddSubLatency) begin
          calc_cnt <= calc_cnt + 1;
        end
        if (calc_cnt > AddSubLatency) begin
          dout_valid <= 1'b1;
          current_intensity[set_cnt] <= s_intensity;
          current_phase[set_cnt] <= {2'b00, s_phase[15:0]};
          intensity_s <= s_intensity;
          phase_s <= s_phase[15:8];
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

  always_ff @(posedge CLK) begin
    intensity_buf <= INTENSITY_IN;
    phase_buf <= PHASE_IN;

    update_rate_intensity[0] <= {2'b00, UPDATE_RATE_INTENSITY};
    update_rate_intensity_n[0] <= -{2'b00, UPDATE_RATE_INTENSITY};
    update_rate_phase[0] <= {2'b00, UPDATE_RATE_PHASE};
    update_rate_phase_n[0] <= -{2'b00, UPDATE_RATE_PHASE};
  end

  for (genvar i = 1; i < 7; i++) begin : g_update_rate_buf
    always_ff @(posedge CLK) begin
      update_rate_intensity[i] <= update_rate_intensity[i-1];
      update_rate_intensity_n[i] <= update_rate_intensity_n[i-1];
      update_rate_phase[i] <= update_rate_phase[i-1];
      update_rate_phase_n[i] <= update_rate_phase_n[i-1];
    end
  end

endmodule
