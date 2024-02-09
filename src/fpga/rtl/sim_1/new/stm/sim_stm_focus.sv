module sim_stm_focus ();

  logic CLK;
  logic locked;
  logic [63:0] SYS_TIME;
  sim_helper_clk sim_helper_clk (
      .CLK_20P48M(CLK),
      .LOCKED(locked),
      .SYS_TIME(SYS_TIME)
  );

  localparam int DEPTH = 249;
  localparam int SIZE = 128;

  sim_helper_bram sim_helper_bram ();
  sim_helper_random sim_helper_random ();

  settings::stm_settings_t stm_settings;
  logic update_settings;

  logic signed [17:0] focus_x_0[SIZE], focus_x_1[SIZE/4];
  logic signed [17:0] focus_y_0[SIZE], focus_y_1[SIZE/4];
  logic signed [17:0] focus_z_0[SIZE], focus_z_1[SIZE/4];
  logic [7:0] intensity_buf_0[SIZE], intensity_buf_1[SIZE/4];

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

  logic [15:0] idx_buf;
  always @(posedge CLK) if (UPDATE) idx_buf = debug_idx;

  task automatic update(input logic req_segment, input logic [31:0] rep);
    @(posedge CLK);
    update_settings <= 1'b1;
    stm_settings.REQ_RD_SEGMENT = req_segment;
    stm_settings.REP = rep;
    @(posedge CLK);
    update_settings <= 1'b0;
  endtask

  task automatic check(input logic segment);
    automatic int id = 0;
    automatic logic signed [63:0] x, y, z;
    automatic logic [63:0] r, lambda;
    automatic int p;

    while (1) begin
      @(posedge CLK);
      if (~dout_valid) begin
        break;
      end
    end
    for (int j = 0; j < SIZE; j++) begin
      while (1) begin
        @(posedge CLK);
        if (dout_valid) begin
          break;
        end
      end
      $display("check %d @%d", idx_buf, SYS_TIME);
      id = 0;
      for (int iy = 0; iy < 14; iy++) begin
        y = (segment ? focus_y_1[idx_buf] : focus_y_0[idx_buf]) -
            $rtoi(10.16 * iy / 0.025);  // [0.025mm]
        for (int ix = 0; ix < 18; ix++) begin
          if ((iy === 1) && (ix === 1 || ix === 2 || ix === 16)) begin
            continue;
          end
          x = (segment ? focus_x_1[idx_buf] : focus_x_0[idx_buf]) -
              $rtoi(10.16 * ix / 0.025);  // [0.025mm]
          z = segment ? focus_z_1[idx_buf] : focus_z_0[idx_buf];  // [0.025mm]
          r = $rtoi($sqrt($itor(x * x + y * y + z * z)));  // [0.025mm]
          lambda = (r << 18) / stm_settings.SOUND_SPEED;
          p = lambda % 256;
          if (intensity !== (segment ? intensity_buf_1[idx_buf] : intensity_buf_0[idx_buf])) begin
            $error("Failed at d_out=%d, d_in=%d @%d", intensity,
                   (segment ? intensity_buf_1[idx_buf] : intensity_buf_0[idx_buf]), id);
            $finish();
          end
          if (phase !== p) begin
            $error("Failed at p_out=%d, p_in=%d (r2=%d, r=%d, lambda=%d) @%d", phase, p,
                   x * x + y * y + z * z, r, lambda, id);
            $error("x=%d, y=%d, z=%d", x, y, z);
            $finish();
          end
          @(posedge CLK);
          id = id + 1;
        end
      end
    end
  endtask

  initial begin
    sim_helper_random.init();

    stm_settings.MODE = params::STM_MODE_FOCUS;
    stm_settings.SOUND_SPEED = 340 * 1024;
    stm_settings.CYCLE_0 = SIZE - 1;
    stm_settings.FREQ_DIV_0 = 512;
    stm_settings.CYCLE_1 = SIZE / 4 - 1;
    stm_settings.FREQ_DIV_1 = 512 * 3;

    update(0, 32'hFFFFFFFF);

    @(posedge locked);

    for (int i = 0; i < SIZE; i++) begin
      $display("write %d/%d", i + 1, SIZE);
      focus_x_0[i] = sim_helper_random.range(131071, -131072 + 6908);
      focus_y_0[i] = sim_helper_random.range(131071, -131072 + 5283);
      focus_z_0[i] = sim_helper_random.range(131071, -131072);
      intensity_buf_0[i] = sim_helper_random.range(8'hFF, 0);
    end
    for (int i = 0; i < SIZE / 4; i++) begin
      $display("write %d/%d", i + 1, SIZE / 4);
      focus_x_1[i] = sim_helper_random.range(131071, -131072 + 6908);
      focus_y_1[i] = sim_helper_random.range(131071, -131072 + 5283);
      focus_z_1[i] = sim_helper_random.range(131071, -131072);
      intensity_buf_1[i] = sim_helper_random.range(8'hFF, 0);
    end
    sim_helper_bram.write_stm_focus(0, focus_x_0, focus_y_0, focus_z_0, intensity_buf_0, SIZE);
    sim_helper_bram.write_stm_focus(1, focus_x_1, focus_y_1, focus_z_1, intensity_buf_1, SIZE / 4);

    check(0);
    update(1, 32'hFFFFFFFF);
    check(1);

    $display("OK! sim_stm_focus");
    $finish();
  end

endmodule
