`timescale 1ns / 1ps
module sim_mem_stm_focus ();

  localparam int DEPTH = 249;
  localparam int SIZE = 65536;

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

  logic [15:0] idx;
  logic [63:0] value;
  logic segment;

  assign stm_bus.GAIN_STM_MODE = 1'b0;
  assign stm_bus.out_focus_port.FOCUS_IDX = idx;
  assign stm_bus.out_focus_port.SEGMENT = segment;
  assign value = stm_bus.out_focus_port.VALUE;

  logic [17:0] x;
  logic [17:0] y;
  logic [17:0] z;
  logic [17:0] intensity;
  assign x = value[17:0];
  assign y = value[35:18];
  assign z = value[53:36];
  assign intensity = value[61:54];

  logic [17:0] x_buf_0[SIZE];
  logic [17:0] y_buf_0[SIZE];
  logic [17:0] z_buf_0[SIZE];
  logic [7:0] intensity_buf_0[SIZE];
  logic [17:0] x_buf_1[SIZE];
  logic [17:0] y_buf_1[SIZE];
  logic [17:0] z_buf_1[SIZE];
  logic [7:0] intensity_buf_1[SIZE];

  task automatic progress();
    for (int i = 0; i < SIZE + 3; i++) begin
      @(posedge CLK);
      idx <= i % SIZE;
    end
  endtask

  task automatic check(logic segment);
    logic [15:0] cur_idx;
    logic [17:0] expect_x;
    logic [17:0] expect_y;
    logic [17:0] expect_z;
    logic [ 7:0] expect_intensity;
    repeat (3) @(posedge CLK);
    for (int i = 0; i < SIZE; i++) begin
      @(posedge CLK);
      cur_idx = (idx + SIZE - 2) % SIZE;
      expect_x = segment === 1'b0 ? x_buf_0[cur_idx] : x_buf_1[cur_idx];
      expect_y = segment === 1'b0 ? y_buf_0[cur_idx] : y_buf_1[cur_idx];
      expect_z = segment === 1'b0 ? z_buf_0[cur_idx] : z_buf_1[cur_idx];
      expect_intensity = segment === 1'b0 ? intensity_buf_0[cur_idx] : intensity_buf_1[cur_idx];
      if (expect_x !== x) begin
        $error("X: %d != %d @ %d", expect_x, x, cur_idx);
        $finish();
      end
      if (expect_y !== y) begin
        $error("Y: %d != %d @ %d", expect_y, y, cur_idx);
        $finish();
      end
      if (expect_z !== z) begin
        $error("Z: %d != %d @ %d", expect_z, z, cur_idx);
        $finish();
      end
      if (expect_intensity !== intensity) begin
        $error("Intensity: %d != %d @ %d", expect_intensity, intensity, cur_idx);
        $finish();
      end
      if (i % 2048 == 2047) $display("segment %d: %d/%d...done", segment, i + 1, SIZE);
    end
  endtask

  initial begin
    sim_helper_random.init();

    idx = 0;
    segment = 0;

    @(posedge locked);

    for (int i = 0; i < SIZE; i++) begin
      x_buf_0[i] = sim_helper_random.range(17'h1FFFF, 0);
      y_buf_0[i] = sim_helper_random.range(17'h1FFFF, 0);
      z_buf_0[i] = sim_helper_random.range(17'h1FFFF, 0);
      intensity_buf_0[i] = sim_helper_random.range(8'hFF, 0);
      x_buf_1[i] = sim_helper_random.range(17'h1FFFF, 0);
      y_buf_1[i] = sim_helper_random.range(17'h1FFFF, 0);
      z_buf_1[i] = sim_helper_random.range(17'h1FFFF, 0);
      intensity_buf_1[i] = sim_helper_random.range(8'hFF, 0);
    end
    sim_helper_bram.write_stm_focus(0, x_buf_0, y_buf_0, z_buf_0, intensity_buf_0, SIZE);
    sim_helper_bram.write_stm_focus(1, x_buf_1, y_buf_1, z_buf_1, intensity_buf_1, SIZE);
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

    $display("OK! sim_mem_stm_focus");
    $finish();
  end

  always @(posedge CLK) begin
    if (locked) begin
      if ($countones(
              sim_helper_bram.memory_bus.bram_port.ENABLES
          ) !== 0 && $countones(
              sim_helper_bram.memory_bus.bram_port.ENABLES
          ) !== 1) begin
        $error("multiple enabled bram: %b", sim_helper_bram.memory_bus.bram_port.ENABLES);
        $finish();
      end
    end
  end

endmodule
