`timescale 1ns / 1ps
module sim_pulse_width_encoder ();

  `define M_PI 3.14159265358979323846

  localparam int DEPTH = 249;
  localparam int TABLE_SIZE = 256;

  sim_helper_random sim_helper_random ();
  sim_helper_bram sim_helper_bram ();

  cnt_bus_if cnt_bus ();
  phase_corr_bus_if phase_corr_bus ();
  modulation_bus_if mod_bus ();
  stm_bus_if stm_bus ();
  pwe_table_bus_if pwe_table_bus ();

  logic CLK;
  logic locked;
  sim_helper_clk sim_helper_clk (
      .MRCC_25P6M(MRCC_25P6M),
      .CLK(CLK),
      .LOCKED(locked),
      .SYS_TIME()
  );

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

  logic din_valid, dout_valid;
  logic [7:0] intensity_in;
  logic [7:0] pulse_width_out;
  logic [7:0] phase;
  logic [7:0] phase_out;

  logic [7:0] intensity_buf[DEPTH];
  logic [7:0] phase_buf[DEPTH];
  logic [7:0] pwe_table[TABLE_SIZE];

  pulse_width_encoder #(
      .DEPTH(DEPTH)
  ) pulse_width_encoder (
      .CLK(CLK),
      .PWE_TABLE_BUS(pwe_table_bus.out_port),
      .DIN_VALID(din_valid),
      .INTENSITY_IN(intensity_in),
      .PHASE_IN(phase),
      .PULSE_WIDTH_OUT(pulse_width_out),
      .PHASE_OUT(phase_out),
      .DOUT_VALID(dout_valid)
  );

  task automatic set(logic [7:0] intensity[DEPTH], logic [7:0] p[DEPTH]);
    for (int i = 0; i < DEPTH; i++) begin
      intensity_buf[i] = intensity[i];
      phase_buf[i] = p[i];
    end
    for (int i = 0; i < DEPTH; i++) begin
      @(posedge CLK);
      din_valid <= 1'b1;
      intensity_in <= intensity_buf[i];
      phase <= phase_buf[i];
    end
    @(posedge CLK);
    din_valid <= 1'b0;
  endtask

  task automatic check_default();
    int expect_pulse_width;
    while (1) begin
      @(posedge CLK);
      if (dout_valid) begin
        break;
      end
    end

    for (int i = 0; i < DEPTH; i++) begin
      expect_pulse_width = int'(($asin($itor(intensity_buf[i]) / 255.0) * 2.0 / `M_PI * 128.0));
      `ASSERT_EQ(expect_pulse_width, pulse_width_out);
      `ASSERT_EQ(phase_buf[i], phase_out);
      @(posedge CLK);
    end
  endtask

  task automatic check();
    int expect_pulse_width;
    while (1) begin
      @(posedge CLK);
      if (dout_valid) begin
        break;
      end
    end

    for (int i = 0; i < DEPTH; i++) begin
      expect_pulse_width = pwe_table[intensity_buf[i]];
      `ASSERT_EQ(expect_pulse_width, pulse_width_out);
      `ASSERT_EQ(phase_buf[i], phase_out);
      @(posedge CLK);
    end
  endtask

  logic [7:0] intensity_tmp[DEPTH];
  logic [7:0] phase_tmp[DEPTH];
  initial begin
    din_valid = 0;
    sim_helper_random.init();

    @(posedge locked);

    for (int i = 0; i <= TABLE_SIZE;) begin
      for (int j = i; j < i + DEPTH; j++) begin
        intensity_tmp[j-i] = j;
        phase_tmp[j-i] = sim_helper_random.range(8'hFF, 0);
      end
      fork
        set(intensity_tmp, phase_tmp);
        check_default();
      join
      i += DEPTH;
    end

    // config bram
    for (int i = 0; i < TABLE_SIZE; i++) begin
      pwe_table[i] = sim_helper_random.range(8'hFF, 0);
    end
    sim_helper_bram.write_pwe_table(pwe_table);

    for (int i = 0; i <= TABLE_SIZE;) begin
      for (int j = i; j < i + DEPTH; j++) begin
        intensity_tmp[j-i] = j;
        phase_tmp[j-i] = sim_helper_random.range(8'hFF, 0);
      end
      fork
        set(intensity_tmp, phase_tmp);
        check();
      join
      i += DEPTH;
    end

    $display("OK! sim_pulse_width_encoder");
    $finish();
  end

endmodule
