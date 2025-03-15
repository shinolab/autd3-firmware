`timescale 1ns / 1ps
module ec_time_to_sys_time (
    input wire CLK,
    input wire [63:0] EC_TIME,
    input wire DIN_VALID,
    output wire [60:0] SYS_TIME,
    output wire DOUT_VALID
);
  localparam int MultLatency = 4;

  logic [54:0] sys_time;

  logic [63:0] lap;
  logic [15:0] lap_rem_unused;

  logic [63:0] ec_time;
  logic din_valid;
  logic din_ready;

  logic div_dout_valid;
  logic [$clog2(MultLatency)-1:0] mult_cnt;
  logic dout_valid;

  assign DOUT_VALID = dout_valid;

  div_64_16 div_lap (
      .s_axis_dividend_tdata(ec_time),
      .s_axis_dividend_tvalid(din_valid),
      .s_axis_dividend_tready(din_ready),
      .s_axis_divisor_tdata(16'd15625),
      .s_axis_divisor_tvalid(1'b1),
      .s_axis_divisor_tready(),
      .aclk(CLK),
      .m_axis_dout_tdata({lap, lap_rem_unused}),
      .m_axis_dout_tvalid(div_dout_valid)
  );

  // multiple by 5
  add_53_51 add_53_51 (
      .CLK(CLK),
      .A  ({lap[50:0], 2'b00}),
      .B  (lap[50:0]),
      .S  (sys_time)
  );
  // and then multiple by 64, resulting multiple by 320
  assign SYS_TIME = {sys_time, 6'd0};

  typedef enum logic [1:0] {
    WAIT,
    LOAD,
    DIV_WAIT,
    MULT_WAIT
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
          mult_cnt <= '0;
          state <= MULT_WAIT;
        end else begin
          state <= DIV_WAIT;
        end
      end
      MULT_WAIT: begin
        if (mult_cnt == MultLatency - 1) begin
          dout_valid <= 1'b1;
          state <= WAIT;
        end else begin
          mult_cnt <= mult_cnt + 1;
          state <= MULT_WAIT;
        end
      end
      default: state <= WAIT;
    endcase
  end

endmodule
