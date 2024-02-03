`timescale 1ns / 1ps
module sim_mem_mod_delay ();

  localparam int DEPTH = 249;

  logic CLK;
  logic locked;
  sim_helper_clk sim_helper_clk (
      .CLK_20P48M(CLK),
      .LOCKED(locked),
      .SYS_TIME()
  );

  sim_helper_random sim_helper_random ();
  sim_helper_bram #(.DEPTH(DEPTH)) sim_helper_bram ();

  cnt_bus_if cnt_bus ();
  modulation_delay_bus_if mod_delay_bus ();
  modulation_bus_if mod_bus ();
  normal_bus_if normal_bus ();
  stm_bus_if stm_bus ();
  duty_table_bus_if duty_table_bus ();

  memory memory (
      .CLK(CLK),
      .MEM_BUS(sim_helper_bram.memory_bus.bram_port),
      .CNT_BUS_IF(cnt_bus.in_port),
      .MOD_DELAY_BUS(mod_delay_bus.in_port),
      .MOD_BUS(mod_bus.in_port),
      .NORMAL_BUS(normal_bus.in_port),
      .STM_BUS(stm_bus.in_port),
      .DUTY_TABLE_BUS(duty_table_bus.in_port)
  );

  logic [15:0] buffer[DEPTH];

  logic [ 7:0] idx;
  logic [15:0] value;

  assign modulation_delay_bus_if.out_port.IDX = idx;
  assign value = modulation_delay_bus_if.out_port.VALUE;

  task automatic progress();
    for (int i = 0; i < DEPTH + 3; i++) begin
      @(posedge CLK);
      idx <= i % DEPTH;
    end
  endtask

  task automatic check();
    logic [ 7:0] cur_idx;
    logic [15:0] expect_value;
    repeat (3) @(posedge CLK);
    for (int i = 0; i < DEPTH; i++) begin
      @(posedge CLK);
      cur_idx = (idx + DEPTH - 2) % DEPTH;
      expect_value = buffer[cur_idx];
      if (expect_value !== value) begin
        $error("%d != %d @ %d", expect_value, value, cur_idx);
        $finish();
      end
    end
  endtask

  initial begin
    sim_helper_random.init();

    idx = 0;

    @(posedge locked);

    for (int i = 0; i < DEPTH; i++) begin
      buffer[i] = sim_helper_random.range(16'hFFFF, 0);
    end
    sim_helper_bram.write_mod_delay(buffer);
    $display("memory initialized");
    fork
      progress();
      check();
    join

    $display("OK! sim_mem_mod_delay");
    $finish();
  end

endmodule
