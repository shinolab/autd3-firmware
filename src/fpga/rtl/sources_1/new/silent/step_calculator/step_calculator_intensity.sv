`timescale 1ns / 1ps
module step_calculator_intensity #(
    parameter int DEPTH = 249
) (
    input var CLK,
    input var DIN_VALID,
    input var [7:0] COMPLETION_STEPS,
    input var [7:0] INTENSITY,
    output var [7:0] UPDATE_RATE,
    output var DOUT_VALID
);

  localparam int DivLatency = 6;

  `RAM
  logic [7:0] current_target_mem[256] = '{256{8'h00}};
  `RAM
  logic [7:0] diff_mem[256] = '{256{8'h00}};
  `RAM
  logic [7:0] step_remainds_mem[256] = '{256{8'h00}};

  logic [7:0] cnt;
  logic reset_in, reset_out;
  logic [7:0] diff_tmp, diff_s;
  logic [7:0] step_quo, step_rem;

  logic dout_valid = 0;
  logic [7:0] update_rate;

  assign UPDATE_RATE = update_rate;
  assign DOUT_VALID  = dout_valid;

  div_8_8 div_8_8 (
      .s_axis_dividend_tdata(diff_s),
      .s_axis_dividend_tvalid(1'b1),
      .s_axis_divisor_tdata(COMPLETION_STEPS),
      .s_axis_divisor_tvalid(1'b1),
      .aclk(CLK),
      .m_axis_dout_tdata({step_quo, step_rem}),
      .m_axis_dout_tvalid()
  );

  delay_fifo #(
      .WIDTH(1),
      .DEPTH(DivLatency)
  ) fifo_reset (
      .CLK (CLK),
      .DIN (reset_in),
      .DOUT(reset_out)
  );

  typedef enum logic [1:0] {
    IDLE,
    WAIT_DIV,
    RUN
  } state_t;

  state_t state = IDLE;

  always_ff @(posedge CLK) begin
    if (DIN_VALID) begin
      current_target_mem[cnt] <= INTENSITY;
    end
  end

  always_ff @(posedge CLK) begin
    diff_tmp <= (INTENSITY < current_target_mem[cnt]) ? current_target_mem[cnt] - INTENSITY :  INTENSITY - current_target_mem[cnt];

    // diff_mem's index is shifted by 1
    if (diff_tmp == 8'd0) begin
      reset_in <= 1'b0;
      diff_s   <= diff_mem[cnt];
    end else begin
      reset_in <= 1'b1;
      diff_s <= diff_tmp;
      diff_mem[cnt] <= diff_tmp;
    end

    // step_remainds_mem's index is shifted by DivLatency
    if (reset_out) begin
      update_rate <= step_quo;
      step_remainds_mem[cnt] <= step_rem;
    end else begin
      if (step_remainds_mem[cnt] == '0) begin
        update_rate <= step_quo;
      end else begin
        update_rate <= step_quo + 1;
        step_remainds_mem[cnt] <= step_remainds_mem[cnt] - 1;
      end
    end
  end

  always_ff @(posedge CLK) begin
    case (state)
      IDLE: begin
        dout_valid <= 1'b0;
        if (DIN_VALID) begin
          cnt   <= 8'd1;
          state <= WAIT_DIV;
        end else begin
          cnt <= '0;
        end
      end
      WAIT_DIV: begin
        cnt   <= cnt + 1;
        state <= cnt == DivLatency + 1 ? RUN : state;
      end
      RUN: begin
        cnt <= cnt + 1;
        dout_valid <= 1'b1;
        state <= (cnt == 1 + DivLatency + DEPTH - 1) ? IDLE : state;
      end
      default: state <= IDLE;
    endcase
  end

endmodule
