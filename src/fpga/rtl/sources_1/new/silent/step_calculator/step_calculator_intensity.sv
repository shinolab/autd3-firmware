module step_calculator_intensity #(
    parameter int DEPTH = 249
) (
    input var CLK,
    input var DIN_VALID,
    input var [15:0] COMPLETION_STEPS,
    input var [15:0] INTENSITY,
    output var [15:0] UPDATE_RATE,
    output var DOUT_VALID
);

  localparam int AddSubLatency = 2;
  localparam int DivLatency = 18;

  logic dout_valid = 0;
  logic [15:0] intensity, intensity_buf;

  logic [15:0] update_rate;

  logic [ 8:0] cnt;
  logic [7:0] diff_addr, target_set_cnt, remainds_load_cnt, remainds_set_cnt;

  logic [15:0] completion_steps;
  logic [15:0] current_target;
  logic current_target_web;
  logic [15:0] diff, diff_din;
  logic [15:0] step_remainds, remainds_din;
  logic [15:0] diff_a, diff_b, diff_tmp, diff_s;
  logic [15:0] step_quo, step_rem;
  logic reset_in, reset_out;

  assign UPDATE_RATE = update_rate;
  assign DOUT_VALID  = dout_valid;

  BRAM16x256 bram_current_target (
      .clka (CLK),
      .addra(cnt[7:0]),
      .dina ('0),
      .douta(current_target),
      .wea  ('0),
      .clkb (CLK),
      .addrb(target_set_cnt),
      .dinb (intensity_buf),
      .doutb(),
      .web  (current_target_web)
  );

  BRAM16x256 bram_diff (
      .clka (CLK),
      .addra(diff_addr),
      .dina ('0),
      .douta(diff),
      .wea  ('0),
      .clkb (CLK),
      .addrb(target_set_cnt),
      .dinb (diff_din),
      .doutb(),
      .web  (current_target_web)
  );

  BRAM16x256 bram_remainds (
      .clka (CLK),
      .addra(remainds_load_cnt),
      .dina ('0),
      .douta(step_remainds),
      .wea  ('0),
      .clkb (CLK),
      .addrb(remainds_set_cnt),
      .dinb (remainds_din),
      .doutb(),
      .web  (dout_valid)
  );

  addsub #(
      .WIDTH(16)
  ) addsub_diff (
      .CLK(CLK),
      .A  (diff_a),
      .B  (diff_b),
      .ADD(1'b0),
      .S  (diff_tmp)
  );

  div_16_16 div_16_16 (
      .s_axis_dividend_tdata(diff_s),
      .s_axis_dividend_tvalid(1'b1),
      .s_axis_divisor_tdata(completion_steps),
      .s_axis_divisor_tvalid(1'b1),
      .aclk(CLK),
      .m_axis_dout_tdata({step_quo, step_rem}),
      .m_axis_dout_tvalid()
  );

  delay_fifo #(
      .WIDTH(16),
      .DEPTH(2)
  ) fifo_intensity (
      .CLK (CLK),
      .DIN (INTENSITY),
      .DOUT(intensity)
  );

  delay_fifo #(
      .WIDTH(16),
      .DEPTH(1 + AddSubLatency + AddSubLatency + 1)
  ) fifo_intensity_target (
      .CLK (CLK),
      .DIN (INTENSITY),
      .DOUT(intensity_buf)
  );

  delay_fifo #(
      .WIDTH(1),
      .DEPTH(DivLatency)
  ) fifo_reset (
      .CLK (CLK),
      .DIN (reset_in),
      .DOUT(reset_out)
  );

  typedef enum logic {
    WAITING,
    RUN
  } state_t;

  state_t state = WAITING;

  always_ff @(posedge CLK) begin
    case (state)
      WAITING: begin
        dout_valid <= 1'b0;
        if (DIN_VALID) begin
          cnt <= 0;
          diff_addr <= 8'hFF - AddSubLatency;
          target_set_cnt <= 8'hFF - 1;
          remainds_set_cnt <= 8'hFF;
          remainds_load_cnt <= 8'hFF - DivLatency - AddSubLatency - 1;

          completion_steps <= COMPLETION_STEPS;

          state <= RUN;
        end
      end
      RUN: begin
        cnt <= cnt + 1;
        diff_addr <= diff_addr + 1;
        remainds_load_cnt <= remainds_load_cnt + 1;

        if (intensity < current_target) begin
          diff_a <= current_target;
          diff_b <= intensity;
        end else begin
          diff_a <= intensity;
          diff_b <= current_target;
        end

        if (cnt > AddSubLatency) begin
          target_set_cnt <= (target_set_cnt == DEPTH) ? target_set_cnt : target_set_cnt + 1;
          if (diff_tmp != 0) begin
            reset_in <= 1'b1;
            diff_din <= diff_tmp;
            diff_s <= diff_tmp;
            current_target_web <= 1'b1;
          end else begin
            reset_in <= 1'b0;
            diff_din <= '0;
            diff_s <= diff;
            current_target_web <= 1'b0;
          end
        end

        if (cnt > AddSubLatency + AddSubLatency + DivLatency) begin
          if (reset_out) begin
            update_rate  <= step_quo;
            remainds_din <= step_rem;
          end else begin
            if (step_remainds == 0) begin
              update_rate  <= step_quo;
              remainds_din <= 0;
            end else begin
              update_rate  <= step_quo + 1;
              remainds_din <= step_remainds - 1;
            end
          end
          remainds_set_cnt <= remainds_set_cnt + 1;

          dout_valid <= 1'b1;
          if (cnt == DEPTH + AddSubLatency + AddSubLatency + DivLatency) begin
            state <= WAITING;
          end
        end
      end
      default: begin
        state <= WAITING;
      end
    endcase
  end


endmodule
