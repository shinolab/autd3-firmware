`timescale 1ns / 1ps
module sim_clock ();

  logic CLK;
  logic locked;
  logic [63:0] sys_time;

  sim_helper_bram sim_helper_bram ();

  clock_bus_if clock_bus ();
  cnt_bus_if cnt_bus ();
  modulation_bus_if mod_bus ();
  stm_bus_if stm_bus ();
  duty_table_bus_if duty_table_bus ();

  memory memory (
      .CLK(CLK),
      .MRCC_25P6M(MRCC_25P6M),
      .MEM_BUS(sim_helper_bram.memory_bus.bram_port),
      .CLOCK_BUS(clock_bus.in_port),
      .CNT_BUS(cnt_bus.in_port),
      .MOD_BUS(mod_bus.in_port),
      .STM_BUS(stm_bus.in_port),
      .DUTY_TABLE_BUS(duty_table_bus.in_port)
  );

  sim_helper_clk sim_helper_clk (
      .MRCC_25P6M(MRCC_25P6M),
      .CLK(CLK),
      .CLOCK_BUS(clock_bus.out_port),
      .LOCKED(locked),
      .SYS_TIME(sys_time)
  );

  logic ultrasound_clk;
  assign ultrasound_clk = sys_time[8:0] == 9'd0;

  initial begin
    @(posedge locked);
    #125000;

    sim_helper_bram.config_clk(38'h3a280003cf, 38'h0000400041, 38'h3c5800030c, 40'hffd90fa401,
                               10'h170);  // 41kHz
    @(posedge locked);
    #125000;

    sim_helper_bram.config_clk(38'h3a3800038e, 38'h0000400041, 38'h3c480002cb, 40'hffda9fa401,
                               10'h170);  // 40kHz
    @(posedge locked);
    #125000;

    $finish();

  end

endmodule
