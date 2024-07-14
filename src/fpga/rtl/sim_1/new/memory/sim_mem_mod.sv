`timescale 1ns / 1ps
module sim_mem_mod ();

  `include "define.vh"

  localparam int DEPTH = 249;
  localparam int SIZE = 32768;

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
      .SYS_TIME()
  );

  logic [14:0] idx;
  logic [7:0] value;
  logic segment;

  assign mod_bus.out_port.IDX = idx;
  assign mod_bus.out_port.SEGMENT = segment;
  assign value = mod_bus.out_port.VALUE;

  logic [7:0] mod_buf[params::NumSegment][SIZE];

  task automatic progress();
    for (int i = 0; i < SIZE + 3; i++) begin
      @(posedge CLK);
      idx <= i % SIZE;
    end
  endtask

  task automatic check(input logic segment);
    logic [14:0] cur_idx;
    logic [ 7:0] expect_value;
    repeat (3) @(posedge CLK);
    for (int i = 0; i < SIZE; i++) begin
      @(posedge CLK);
      cur_idx = (idx + SIZE - 2) % SIZE;
      expect_value = mod_buf[segment][cur_idx];
      `ASSERT_EQ(expect_value, value);
      if (i % 1024 == 1023) $display("segment %d: %d/%d...done", segment, i + 1, SIZE);
    end
  endtask

  initial begin
    sim_helper_random.init();

    idx = 0;
    segment = 0;

    @(posedge locked);

    for (int s = 0; s < params::NumSegment; s++) begin
      for (int i = 0; i < SIZE; i++) begin
        mod_buf[s][i] = sim_helper_random.range(8'hFF, 0);
      end
      sim_helper_bram.write_mod(s, mod_buf[s], SIZE);
    end
    $display("memory initialized");

    segment = 0;
    fork
      progress();
      check(segment);
    join

    segment = 1;
    fork
      progress();
      check(segment);
    join

    $display("OK! sim_mem_mod");
    $finish();
  end

endmodule
