module sim_pulse_width_encoder ();

  `define M_PI 3.14159265358979323846

  localparam int DEPTH = 249;

  logic CLK;
  logic locked;
  sim_helper_clk sim_helper_clk (
      .CLK_20P48M(CLK),
      .LOCKED(locked),
      .SYS_TIME()
  );

  sim_helper_random sim_helper_random ();
  sim_helper_bram sim_helper_bram ();

  cnt_bus_if cnt_bus ();
  modulation_bus_if mod_bus ();
  stm_bus_if stm_bus ();
  duty_table_bus_if duty_table_bus ();

  memory memory (
      .CLK(CLK),
      .MEM_BUS(sim_helper_bram.memory_bus.bram_port),
      .CNT_BUS_IF(cnt_bus.in_port),
      .MOD_BUS(mod_bus.in_port),
      .STM_BUS(stm_bus.in_port),
      .DUTY_TABLE_BUS(duty_table_bus.in_port)
  );

  settings::pulse_width_encoder_settings_t pulse_width_encoder_settings;
  logic din_valid, dout_valid;
  logic [15:0] intensity_in;
  logic [8:0] pulse_width_out;
  logic [7:0] phase;
  logic [7:0] phase_out;

  logic [15:0] intensity_buf[DEPTH];
  logic [7:0] phase_buf[DEPTH];

  pulse_width_encoder #(
      .DEPTH(DEPTH)
  ) pulse_width_encoder (
      .CLK(CLK),
      .PULSE_WIDTH_ENCODER_SETTINGS(pulse_width_encoder_settings),
      .DUTY_TABLE_BUS(duty_table_bus.out_port),
      .DIN_VALID(din_valid),
      .INTENSITY_IN(intensity_in),
      .PHASE_IN(phase),
      .PULSE_WIDTH_OUT(pulse_width_out),
      .PHASE_OUT(phase_out),
      .DOUT_VALID(dout_valid)
  );

  task automatic set(logic [15:0] intensity[DEPTH], logic [7:0] p[DEPTH]);
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

  task automatic set_random();
    for (int i = 0; i < DEPTH; i++) begin
      intensity_buf[i] = sim_helper_random.range(16'hFFFF, 0);
      phase_buf[i] = sim_helper_random.range(8'hFF, 0);
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

  task automatic check();
    int expect_pulse_width;
    while (1) begin
      @(posedge CLK);
      if (dout_valid) begin
        break;
      end
    end

    for (int i = 0; i < DEPTH; i++) begin
      expect_pulse_width = intensity_buf[i] >= pulse_width_encoder_settings.FULL_WIDTH_START ? 256 :
          int'(($asin($itor(intensity_buf[i]) / 255.0 / 255.0) * 2.0 / `M_PI * 256.0));
      if (pulse_width_out !== expect_pulse_width) begin
        $error("At %d: i=%d, d=%d, d_m=%d", i, intensity_buf[i], expect_pulse_width,
               pulse_width_out);
        $finish();
      end
      if (phase_out !== phase_buf[i]) begin
        $error("At %d: p=%d, p_m=%d", i, phase_buf[i], phase_out);
        $finish();
      end

      @(posedge CLK);
    end
  endtask

  logic [15:0] intensity_tmp[DEPTH];
  logic [7:0] phase_tmp[DEPTH];
  initial begin
    din_valid = 0;
    sim_helper_random.init();
    pulse_width_encoder_settings.FULL_WIDTH_START = 255 * 255;

    @(posedge locked);

    for (int j = 0; j < 1000; j++) begin
      $display("Check %d", j);
      fork
        set_random();
        check();
      join
    end

    for (int i = 0; i <= 16'hFFFF;) begin
      $display("Check %d/%d", i, 16'hFFFF);
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
