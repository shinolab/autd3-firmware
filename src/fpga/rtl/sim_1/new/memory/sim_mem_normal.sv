`timescale 1ns / 1ps
module sim_mem_normal ();

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

  modulation_bus_if mod_bus ();
  normal_bus_if normal_bus ();
  stm_bus_if stm_bus ();

  memory memory (
      .CLK(CLK),
      .MEM_BUS(sim_helper_bram.memory_bus.bram_port),
      .MOD_BUS(mod_bus.in_port),
      .NORMAL_BUS(normal_bus.in_port),
      .STM_BUS(stm_bus.in_port)
  );

  logic [7:0] addr;
  logic [15:0] value;
  logic segment;

  assign normal_bus.out_port.ADDR = addr;
  assign normal_bus.out_port.SEGMENT = segment;
  assign value = normal_bus.out_port.VALUE;

  logic [7:0] phase_buf_0[DEPTH];
  logic [7:0] intensity_buf_0[DEPTH];
  logic [7:0] phase_buf_1[DEPTH];
  logic [7:0] intensity_buf_1[DEPTH];

  task automatic progress();
    for (int i = 0; i < DEPTH + 3; i++) begin
      @(posedge CLK);
      addr <= i % DEPTH;
    end
  endtask

  task automatic check(logic segment);
    logic [7:0] idx;
    logic [7:0] expect_phase;
    logic [7:0] expect_intensity;
    repeat (3) @(posedge CLK);
    for (int i = 0; i < DEPTH; i++) begin
      @(posedge CLK);
      idx = (addr + DEPTH - 2) % DEPTH;
      expect_phase = segment === 1'b0 ? phase_buf_0[idx] : phase_buf_1[idx];
      expect_intensity = segment === 1'b0 ? intensity_buf_0[idx] : intensity_buf_1[idx];
      if (expect_phase !== value[7:0]) begin
        $error("Phase: %d != %d @ %d", expect_phase, value[7:0], idx);
        $finish();
      end
      if (expect_intensity !== value[15:8]) begin
        $error("Intensity: %d != %d @ %d", expect_intensity, value[15:8], idx);
        $finish();
      end
    end
  endtask

  initial begin
    sim_helper_random.init();

    addr = 0;
    segment = 0;

    @(posedge locked);

    for (int i = 0; i < DEPTH; i++) begin
      phase_buf_0[i] = sim_helper_random.range(8'hFF, 0);
      intensity_buf_0[i] = sim_helper_random.range(8'hFF, 0);
      phase_buf_1[i] = sim_helper_random.range(8'hFF, 0);
      intensity_buf_1[i] = sim_helper_random.range(8'hFF, 0);
    end
    sim_helper_bram.write_intensity_phase(0, intensity_buf_0, phase_buf_0);
    sim_helper_bram.write_intensity_phase(1, intensity_buf_1, phase_buf_1);
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

    $display("OK! sim_mem_normal");
    $finish();
  end

endmodule
