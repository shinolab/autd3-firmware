module sim_stm_focus ();

  logic CLK;
  logic locked;
  logic [63:0] SYS_TIME;
  sim_helper_clk #(
      .SPEED_UP(1.0)
  ) sim_helper_clk (
      .CLK_20P48M(CLK),
      .LOCKED(locked),
      .SYS_TIME(SYS_TIME)
  );

  localparam int DEPTH = 249;
  localparam int SIZE = 16;

  sim_helper_bram sim_helper_bram ();
  sim_helper_random sim_helper_random ();

  settings::stm_settings_t stm_settings;
  logic update_settings;

  logic [15:0] cycle_buf[2];
  logic [31:0] freq_div_buf[2];
  logic signed [17:0] focus_x[2][SIZE];
  logic signed [17:0] focus_y[2][SIZE];
  logic signed [17:0] focus_z[2][SIZE];
  logic [7:0] intensity_buf[2][SIZE];

  logic [15:0] debug_idx;
  logic debug_segment;
  logic [7:0] intensity;
  logic [7:0] phase;
  logic dout_valid;

  cnt_bus_if cnt_bus ();
  modulation_delay_bus_if mod_delay_bus ();
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

  time_cnt_generator #(
      .DEPTH(DEPTH)
  ) time_cnt_generator (
      .CLK(CLK),
      .SYS_TIME(SYS_TIME),
      .SKIP_ONE_ASSERT(1'b0),
      .TIME_CNT(),
      .UPDATE(UPDATE)
  );

  stm #(
      .DEPTH(DEPTH)
  ) stm (
      .CLK(CLK),
      .SYS_TIME(SYS_TIME),
      .UPDATE(UPDATE),
      .UPDATE_SETTINGS(update_settings),
      .STM_SETTINGS(stm_settings),
      .STM_BUS(stm_bus.stm_port),
      .STM_BUS_FOCUS(stm_bus.out_focus_port),
      .STM_BUS_GAIN(stm_bus.out_gain_port),
      .INTENSITY(intensity),
      .PHASE(phase),
      .DOUT_VALID(dout_valid),
      .DEBUG_IDX(debug_idx),
      .DEBUG_SEGMENT(debug_segment)
  );

  task automatic update(input logic req_segment, input logic [31:0] rep);
    @(posedge CLK);
    update_settings <= 1'b1;
    stm_settings.REQ_RD_SEGMENT <= req_segment;
    stm_settings.REP <= rep;
    if (req_segment === 1'b0) begin
      stm_settings.CYCLE_0 = cycle_buf[req_segment] - 1;
      stm_settings.FREQ_DIV_0 = 512 * freq_div_buf[req_segment];
    end else begin
      stm_settings.CYCLE_1 = cycle_buf[req_segment] - 1;
      stm_settings.FREQ_DIV_1 = 512 * freq_div_buf[req_segment];
    end

    @(posedge CLK);
    update_settings <= 1'b0;
  endtask

  task automatic wait_segment(input logic segment);
    while (1) begin
      @(posedge CLK);
      if (debug_segment === segment) begin
        break;
      end
    end
  endtask

  task automatic check(input logic segment);
    automatic int idx, ix, iy;
    automatic logic signed [63:0] x, y, z;
    automatic logic [63:0] r, lambda;
    automatic int p;

    while (1) begin
      @(posedge CLK);
      if (~dout_valid) begin
        break;
      end
    end
    for (int j = 0; j < cycle_buf[segment] * freq_div_buf[segment]; j++) begin
      while (1) begin
        @(posedge CLK);
        if (dout_valid) begin
          break;
        end
      end
      $display("check %d @%d", debug_idx, SYS_TIME);
      idx = 0;
      for (int id = 0; idx < DEPTH; id++) begin
        ix = id % 18;
        iy = id / 18;
        if ((iy === 1) && (ix === 1 || ix === 2 || ix === 16)) begin
          continue;
        end
        idx++;
        x = focus_x[segment][debug_idx] - $rtoi(10.16 * ix / 0.025);  // [0.025mm]
        y = focus_y[segment][debug_idx] - $rtoi(10.16 * iy / 0.025);  // [0.025mm]
        z = focus_z[segment][debug_idx];  // [0.025mm]
        r = $rtoi($sqrt($itor(x * x + y * y + z * z)));  // [0.025mm]
        lambda = (r << 18) / stm_settings.SOUND_SPEED;
        p = lambda % 256;
        if (intensity !== intensity_buf[segment][debug_idx]) begin
          $error("Failed at d_out=%d, d_in=%d @%d", intensity, intensity_buf[segment][debug_idx],
                 id);
          $finish();
        end
        if (phase !== p) begin
          $error("Failed at p_out=%d, p_in=%d (r2=%d, r=%d, lambda=%d) @%d", phase, p,
                 x * x + y * y + z * z, r, lambda, id);
          $error("x=%d, y=%d, z=%d", x, y, z);
          $finish();
        end
        @(posedge CLK);
      end
    end
  endtask

  initial begin
    sim_helper_random.init();

    cycle_buf[0] = SIZE;
    cycle_buf[1] = SIZE / 4;
    freq_div_buf[0] = 1;
    freq_div_buf[1] = 3;

    stm_settings.MODE = params::STMModeFocus;
    stm_settings.SOUND_SPEED = 340 * 1024;
    stm_settings.CYCLE_0 = '0;
    stm_settings.FREQ_DIV_0 = '1;
    stm_settings.CYCLE_1 = '0;
    stm_settings.FREQ_DIV_1 = '1;

    @(posedge locked);

    for (int segment = 0; segment < 2; segment++) begin
      for (int i = 0; i < SIZE; i++) begin
        focus_x[segment][i] = sim_helper_random.range(131071, -131072 + 6908);
        focus_y[segment][i] = sim_helper_random.range(131071, -131072 + 5283);
        focus_z[segment][i] = sim_helper_random.range(131071, -131072);
        intensity_buf[segment][i] = sim_helper_random.range(8'hFF, 0);
      end
      sim_helper_bram.write_stm_focus(segment, focus_x[segment], focus_y[segment], focus_z[segment],
                                      intensity_buf[segment], cycle_buf[segment]);
    end
    $display("memory initialized");

    fork
      update(0, 32'hFFFFFFFF);
      wait_segment(0);
    join
    check(0);

    fork
      update(1, 32'd0);
      wait_segment(1);
    join
    check(1);

    $display("OK! sim_stm_focus");
    $finish();
  end

endmodule
