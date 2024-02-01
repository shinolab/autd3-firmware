`timescale 1ns / 1ps
module sim_mem_mod ();

  logic CLK;
  logic locked;
  sim_helper_clk sim_helper_clk (
      .CLK_20P48M(CLK),
      .LOCKED(locked),
      .SYS_TIME()
  );

  sim_helper_random sim_helper_random ();
  sim_helper_bram sim_helper_bram ();

  localparam int DEPTH = 249;
  localparam int SIZE = 32768;

  modulation_bus_if mod_bus ();
  normal_bus_if normal_bus ();

  memory memory (
      .CLK(CLK),
      .MEM_NORMAL_BUS(sim_helper_bram.memory_bus.normal_port),
      .MEM_MOD_BUS(sim_helper_bram.memory_bus.mod_port),
      .MOD_BUS(mod_bus.in_port),
      .NORMAL_BUS(normal_bus.in_port)
  );

  logic [14:0] addr;
  logic [7:0] value;
  logic page;

  assign mod_bus.out_port.ADDR = addr;
  assign mod_bus.out_port.PAGE = page;
  assign value = mod_bus.out_port.VALUE;

  logic [7:0] mod_buf_0[SIZE];
  logic [7:0] mod_buf_1[SIZE];

  task automatic progress();
    for (int i = 0; i < SIZE + 3; i++) begin
      @(posedge CLK);
      addr <= i % SIZE;
    end
  endtask

  task automatic check(logic page);
    logic [14:0] idx;
    logic [ 7:0] expect_value;
    repeat (3) @(posedge CLK);
    for (int i = 0; i < SIZE; i++) begin
      @(posedge CLK);
      idx = (addr + SIZE - 2) % SIZE;
      expect_value = page === 1'b0 ? mod_buf_0[idx] : mod_buf_1[idx];
      if (expect_value !== value) begin
        $error("%d != %d @ %d", expect_value, value, idx);
        $finish();
      end
      if (i % 1024 == 1023) $display("page %d: done %d/%d...", page, i + 1, SIZE);
    end
  endtask

  initial begin
    sim_helper_random.init();

    addr = 0;
    page = 0;

    @(posedge locked);

    for (int i = 0; i < SIZE; i++) begin
      mod_buf_0[i] = sim_helper_random.range(8'hFF, 0);
      mod_buf_1[i] = sim_helper_random.range(8'hFF, 0);
    end
    sim_helper_bram.write_mod(0, mod_buf_0, SIZE);
    sim_helper_bram.write_mod(1, mod_buf_1, SIZE);
    $display("memory initialized");

    page = 0;
    fork
      progress();
      check(page);
    join

    page = 1;
    fork
      progress();
      check(page);
    join

    $display("OK! sim_mem_mod");
    $finish();
  end

endmodule
