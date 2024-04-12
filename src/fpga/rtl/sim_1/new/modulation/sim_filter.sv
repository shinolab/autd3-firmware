`timescale 1ns / 1ps
module sim_filter ();

  localparam int DEPTH = 249;
  localparam int SIZE = 10;

  logic CLK;
  logic locked;
  logic [63:0] sys_time;
  sim_helper_clk sim_helper_clk (
      .CLK_20P48M(CLK),
      .LOCKED(locked),
      .SYS_TIME(sys_time)
  );

  sim_helper_random sim_helper_random ();
  sim_helper_bram #(.DEPTH(DEPTH)) sim_helper_bram ();

  settings::mod_settings_t mod_settings;

  cnt_bus_if cnt_bus ();
  modulation_bus_if mod_bus ();
  stm_bus_if stm_bus ();
  duty_table_bus_if duty_table_bus ();
  filter_bus_if filter_bus ();

  memory memory (
      .CLK(CLK),
      .MEM_BUS(sim_helper_bram.memory_bus.bram_port),
      .CNT_BUS_IF(cnt_bus.in_port),
      .MOD_BUS(mod_bus.in_port),
      .STM_BUS(stm_bus.in_port),
      .DUTY_TABLE_BUS(duty_table_bus.in_port),
      .FILTER_BUS(filter_bus_if.in_port)
  );

  logic din_valid;
  logic [7:0] phase_in;
  logic [7:0] phase_out;
  logic dout_valid;

  phase_filter #(
      .DEPTH(DEPTH)
  ) phase_filter (
      .CLK(CLK),
      .DIN_VALID(din_valid),
      .FILTER_BUS(filter_bus_if.out_port),
      .PHASE_IN(phase_in),
      .PHASE_OUT(phase_out),
      .DOUT_VALID(dout_valid)
  );

  logic [7:0] phase_buf[DEPTH];
  logic [7:0] phase_offset_buf[DEPTH];

  task automatic set();
    for (int i = 0; i < DEPTH; i++) begin
      phase_buf[i] = sim_helper_random.range(8'hFF, 0);
    end
    while (sys_time[8:0] !== '0) @(posedge CLK);
    for (int i = 0; i < DEPTH; i++) begin
      @(posedge CLK);
      din_valid <= 1'b1;
      phase_in  <= phase_buf[i];
    end
    @(posedge CLK);
    din_valid <= 1'b0;
  endtask

  logic [7:0] expect_phase;
  task automatic check();
    while (1) begin
      @(posedge CLK);
      if (dout_valid) begin
        break;
      end
    end
    for (int i = 0; i < DEPTH; i++) begin
      expect_phase = phase_buf[i] + phase_offset_buf[i] + 0;
      if (phase_out !== expect_phase) begin
        $error("Phase at %d: %d !== %d", i, expect_phase, phase_out);
        $finish();
      end
      @(posedge CLK);
    end
  endtask

  initial begin
    sim_helper_random.init();

    @(posedge locked);

    for (int i = 0; i < DEPTH; i++) begin
      phase_offset_buf[i] = sim_helper_random.range(8'hFF, 0);
    end
    sim_helper_bram.write_phase_filter(phase_offset_buf);

    for (int i = 0; i < 100; i++) begin
      fork
        set();
        check();
      join
      $display("Check %d/%d...done", i + 1, 100);
    end

    $display("OK! sim_filter");
    $finish();
  end

endmodule
