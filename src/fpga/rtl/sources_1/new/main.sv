`timescale 1ns / 1ps
module main #(
    parameter int DEPTH = 249
) (
    input var CLK,
    input var CAT_SYNC0,
    memory_bus_if.bram_port MEM_BUS,
    input var THERMO,
    output var FORCE_FAN,
    output var PWM_OUT[DEPTH],
    output var GPIO_OUT[2]
);

  `include "params.vh"

  //

  cnt_bus_if cnt_bus ();
  modulation_delay_bus_if mod_delay_bus ();
  modulation_bus_if mod_bus ();
  normal_bus_if normal_bus ();
  stm_bus_if stm_bus ();
  duty_table_bus_if duty_table_bus ();

  memory memory (
      .CLK(CLK),
      .MEM_BUS(MEM_BUS),
      .CNT_BUS_IF(cnt_bus.in_port),
      .MOD_DELAY_BUS(mod_delay_bus.in_port),
      .MOD_BUS(mod_bus.in_port),
      .NORMAL_BUS(normal_bus.in_port),
      .STM_BUS(stm_bus.in_port),
      .DUTY_TABLE_BUS(duty_table_bus.in_port)
  );

endmodule
