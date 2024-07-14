`timescale 1ns / 1ps
module sim_mem_cnt ();

  `include "define.vh"

  localparam int DEPTH = 249;
  localparam int SIZE = 256;

  logic CLK;
  logic locked;

  sim_helper_random sim_helper_random ();
  sim_helper_bram #(.DEPTH(DEPTH)) sim_helper_bram ();

  cnt_bus_if cnt_bus ();
  modulation_bus_if mod_bus ();
  stm_bus_if stm_bus ();
  pwe_table_bus_if pwe_table_bus ();

  memory memory (
      .CLK(CLK),
      .MRCC_25P6M(MRCC_25P6M),
      .MEM_BUS(sim_helper_bram.memory_bus.bram_port),
      .CNT_BUS(cnt_bus.in_port),
      .MOD_BUS(mod_bus.in_port),
      .STM_BUS(stm_bus.in_port),
      .PWE_TABLE_BUS(pwe_table_bus.in_port)
  );

  sim_helper_clk sim_helper_clk (
      .MRCC_25P6M(MRCC_25P6M),
      .CLK(CLK),
      .LOCKED(locked),
      .SYS_TIME(sys_time)
  );

  logic [ 7:0] addr;
  logic [15:0] value;

  assign cnt_bus_if.out_port.ADDR = addr;
  assign value = cnt_bus_if.out_port.DOUT;

  logic [15:0] buffer[SIZE];

  task automatic progress();
    for (int i = 0; i < SIZE + 3; i++) begin
      @(posedge CLK);
      addr <= i % SIZE;
    end
  endtask

  task automatic check();
    repeat (3) @(posedge CLK);
    for (int i = 0; i < SIZE; i++) begin
      @(posedge CLK);
      `ASSERT_EQ(buffer[(addr+SIZE-2)%SIZE], value);
    end
  endtask

  initial begin
    sim_helper_random.init();

    addr = 0;

    @(posedge locked);

    for (int i = 0; i < SIZE; i++) begin
      buffer[i] = sim_helper_random.range(16'hFFFF, 0);
    end
    for (int i = 0; i < SIZE; i++) begin
      sim_helper_bram.write_cnt(i, buffer[i]);
    end
    $display("memory initialized");

    fork
      progress();
      check();
    join

    $display("OK! sim_mem_cnt");
    $finish();
  end

endmodule
