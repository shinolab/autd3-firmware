`timescale 1ns / 1ps
module sim_mem_cnt ();

  localparam int DEPTH = 249;
  localparam int SIZE = 256;

  logic CLK;
  logic locked;

  sim_helper_random sim_helper_random ();
  sim_helper_bram #(.DEPTH(DEPTH)) sim_helper_bram ();

  clock_bus_if clock_bus ();
  cnt_bus_if cnt_bus ();
  modulation_bus_if mod_bus ();
  stm_bus_if stm_bus ();
  pwe_table_bus_if pwe_table_bus ();

  memory memory (
      .CLK(CLK),
      .MRCC_25P6M(MRCC_25P6M),
      .MEM_BUS(sim_helper_bram.memory_bus.bram_port),
      .CLOCK_BUS(clock_bus.in_port),
      .CNT_BUS(cnt_bus.in_port),
      .MOD_BUS(mod_bus.in_port),
      .STM_BUS(stm_bus.in_port),
      .PWE_TABLE_BUS(pwe_table_bus.in_port)
  );

  sim_helper_clk sim_helper_clk (
      .MRCC_25P6M(MRCC_25P6M),
      .CLK(CLK),
      .CLOCK_BUS(clock_bus.out_port),
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
    logic [ 7:0] idx;
    logic [15:0] expect_value;
    repeat (3) @(posedge CLK);
    for (int i = 0; i < SIZE; i++) begin
      @(posedge CLK);
      idx = (addr + SIZE - 2) % SIZE;
      expect_value = buffer[idx];
      if (expect_value !== value) begin
        $error("%d != %d @ %d", expect_value, value, idx);
        $finish();
      end
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

    $display("OK! sim_mem_normal");
    $finish();
  end

endmodule
