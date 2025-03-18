`timescale 1ns / 1ps
module ec_time_to_sys_time (
    input wire CLK,
    input wire [63:0] EC_TIME,
    input wire DIN_VALID,
    output wire [56:0] SYS_TIME,
    output wire DOUT_VALID
);
  // This module converts the 1ns unit time of EtherCAT to the 1/20.48MHz unit time.
  // That is, SYS_TIME = EC_TIME * 20.48MHz / 1GHz = EC_TIME * 64 / 3125.
  // The number of bits required for SYS_TIME is 64 + log2(64 / 3125) = 58.4, but for simplification, it is truncated to 57 bits.
  // This means that this firmware works fine only until 2000/1/1 (EtherCAT reference time) + (2^57 - 1) / 20.48MHz ~ 2220, but it is practically no problem.

  logic [56:0] sys_time;

  logic [63:0] quo;
  logic [15:0] quo_rem_unused;

  logic [63:0] ec_time;
  logic din_valid;
  logic din_ready;

  logic div_dout_valid;
  logic dout_valid;

  assign DOUT_VALID = dout_valid;

  div_64_16 div_lap (
      .s_axis_dividend_tdata(ec_time),
      .s_axis_dividend_tvalid(din_valid),
      .s_axis_dividend_tready(din_ready),
      .s_axis_divisor_tdata(16'd3125),
      .s_axis_divisor_tvalid(1'b1),
      .s_axis_divisor_tready(),
      .aclk(CLK),
      .m_axis_dout_tdata({quo, quo_rem_unused}),
      .m_axis_dout_tvalid(div_dout_valid)
  );

  assign SYS_TIME = sys_time;

  typedef enum logic [1:0] {
    WAIT,
    LOAD,
    DIV_WAIT
  } state_t;

  state_t state = WAIT;

  always_ff @(posedge CLK) begin
    case (state)
      WAIT: begin
        dout_valid <= 1'b0;
        if (DIN_VALID) begin
          ec_time <= EC_TIME;
          din_valid <= 1'b1;
          state <= LOAD;
        end else begin
          state <= WAIT;
        end
      end
      LOAD: begin
        if (din_ready) begin
          din_valid <= 1'b0;
          state <= DIV_WAIT;
        end else begin
          state <= LOAD;
        end
      end
      DIV_WAIT: begin
        if (div_dout_valid) begin
          sys_time <= {quo[50:0], 6'd0};
          dout_valid <= 1'b1;
          state <= WAIT;
        end else begin
          state <= DIV_WAIT;
        end
      end
      default: state <= WAIT;
    endcase
  end

endmodule
