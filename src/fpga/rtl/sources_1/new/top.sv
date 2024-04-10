`timescale 1ns / 1ps
module top (
    input wire [16:1] CPU_ADDR,
    inout tri [15:0] CPU_DATA,
    input wire CPU_CKIO,
    input wire CPU_CS1_N,
    input wire RESET_N,
    input wire CPU_WE0_N,
    input wire CPU_RD_N,
    input wire CPU_RDWR,
    input wire MRCC_25P6M,
    input wire CAT_SYNC0,
    output wire FORCE_FAN,
    input wire THERMO,
    output wire [252:1] XDCR_OUT,
    output wire GPIO_OUT[4]
);

  logic clk;
  logic reset;

  logic PWM_OUT[params::NumTransducers];

  assign reset = ~RESET_N;

  for (genvar i = 0; i < params::NumTransducers; i++) begin : gen_output
    assign XDCR_OUT[cvt_uid(i)+1] = PWM_OUT[i];
  end

  memory_bus_if memory_bus ();
  assign memory_bus.BUS_CLK = CPU_CKIO;
  assign memory_bus.EN = ~CPU_CS1_N;
  assign memory_bus.RD = ~CPU_RD_N;
  assign memory_bus.RDWR = CPU_RDWR;
  assign memory_bus.WE = ~CPU_WE0_N;
  assign memory_bus.BRAM_SELECT = CPU_ADDR[16:15];
  assign memory_bus.BRAM_ADDR = CPU_ADDR[14:1];
  assign memory_bus.CPU_DATA = CPU_DATA;

  ultrasound_cnt_clk_gen ultrasound_cnt_clk_gen (
      .clk_in1(MRCC_25P6M),
      .reset  (reset),
      .clk_out(clk),
      .locked ()
  );

  main #(
      .DEPTH(params::NumTransducers)
  ) main (
      .CLK(clk),
      .CAT_SYNC0(CAT_SYNC0),
      .MEM_BUS(memory_bus.bram_port),
      .THERMO(THERMO),
      .FORCE_FAN(FORCE_FAN),
      .PWM_OUT(PWM_OUT),
      .GPIO_OUT(GPIO_OUT)
  );

  function automatic [7:0] cvt_uid(input logic [7:0] idx);
    if (idx < 8'd19) begin
      cvt_uid = idx;
    end else if (idx < 8'd32) begin
      cvt_uid = idx + 2;
    end else begin
      cvt_uid = idx + 3;
    end
  endfunction

endmodule
