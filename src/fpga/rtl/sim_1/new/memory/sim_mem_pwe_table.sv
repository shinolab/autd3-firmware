`timescale 1ns / 1ps
module sim_mem_pwe_table ();

  `include "define.vh"

  localparam int DEPTH = 249;
  localparam int SIZE = 256;

  logic CLK;
  logic locked;

  sim_helper_random sim_helper_random ();
  sim_helper_bram #(.DEPTH(DEPTH)) sim_helper_bram ();

  cnt_bus_if cnt_bus ();
  phase_corr_bus_if phase_corr_bus ();
  modulation_bus_if mod_bus ();
  stm_bus_if stm_bus ();
  pwe_table_bus_if pwe_table_bus ();

  memory memory (
      .CLK(CLK),
      .MRCC_25P6M(MRCC_25P6M),
      .MEM_BUS(sim_helper_bram.memory_bus.bram_port),
      .CNT_BUS(cnt_bus.in_port),
      .PHASE_CORR_BUS(phase_corr_bus.in_port),
      .MOD_BUS(mod_bus.in_port),
      .STM_BUS(stm_bus.in_port),
      .PWE_TABLE_BUS(pwe_table_bus.in_port)
  );

  sim_helper_clk sim_helper_clk (
      .MRCC_25P6M(MRCC_25P6M),
      .CLK(CLK),
      .LOCKED(locked),
      .SYS_TIME()
  );

  logic [8:0] buffer[SIZE];

  logic [7:0] idx;
  logic [8:0] value;

  assign pwe_table_bus.out_port.IDX = idx;
  assign value = pwe_table_bus.out_port.VALUE;

  task automatic progress();
    for (int i = 0; i < SIZE + 3; i++) begin
      @(posedge CLK);
      idx <= i % SIZE;
    end
  endtask

  task automatic check_initial_asin();
    logic [7:0] cur_idx;
    logic [8:0] expect_value;
    repeat (3) @(posedge CLK);
    for (int i = 0; i < SIZE; i++) begin
      @(posedge CLK);
      cur_idx = (idx + SIZE - 2) % SIZE;
      expect_value = int'($asin(cur_idx / 255.0) / $acos(-1) * 512.0);
      `ASSERT_EQ(expect_value, value);
    end
  endtask

  task automatic check();
    logic [7:0] cur_idx;
    logic [8:0] expect_value;
    repeat (3) @(posedge CLK);
    for (int i = 0; i < SIZE; i++) begin
      @(posedge CLK);
      cur_idx = (idx + SIZE - 2) % SIZE;
      expect_value = buffer[cur_idx];
      `ASSERT_EQ(expect_value, value);
    end
  endtask

  initial begin
    sim_helper_random.init();

    idx = 0;

    @(posedge locked);

    fork
      progress();
      check_initial_asin();
    join

    idx = 0;
    for (int i = 0; i < SIZE; i++) begin
      buffer[i] = sim_helper_random.range(9'h1FF, 0);
    end
    sim_helper_bram.write_pwe_table(buffer);
    $display("memory initialized");
    fork
      progress();
      check();
    join

    $display("OK! sim_mem_pwe_table");
    $finish();
  end

endmodule
