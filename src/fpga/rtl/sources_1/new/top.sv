`timescale 1ns / 1ps
module top (
    input var [16:1] CPU_ADDR,
    inout tri [15:0] CPU_DATA,
    input var CPU_CKIO,
    input var CPU_CS1_N,
    input var RESET_N,
    input var CPU_WE0_N,
    input var CPU_RD_N,
    input var CPU_RDWR,
    input var MRCC_25P6M,
    input var CAT_SYNC0,
    output var FORCE_FAN,
    input var THERMO,
    output var [252:1] XDCR_OUT,
    output var GPIO_OUT[2]
);

  logic clk;
  logic reset;

  logic PWM_OUT[NUM_TRANSDUCERS];

  assign reset = ~RESET_N;

  for (genvar i = 0; i < NUM_TRANSDUCERS; i++) begin : gen_output
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
      .DEPTH(NUM_TRANSDUCERS)
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
