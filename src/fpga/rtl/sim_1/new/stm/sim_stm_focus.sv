`timescale 1ns / 1ps
module sim_stm_focus ();

  logic CLK;
  logic locked;
  logic [63:0] SYS_TIME;

  localparam int DEPTH = 249;
  localparam int SIZE = 16;

  sim_helper_bram sim_helper_bram ();
  sim_helper_random sim_helper_random ();

  settings::stm_settings_t stm_settings;

  logic [13:0] cycle_buf[2];
  logic [31:0] freq_div_buf[2];
  logic signed [17:0] focus_x[2][SIZE][8];
  logic signed [17:0] focus_y[2][SIZE][8];
  logic signed [17:0] focus_z[2][SIZE][8];
  logic [7:0] intensity_buf[2][SIZE][8];

  logic [12:0] debug_idx;
  logic debug_segment;
  logic [7:0] intensity;
  logic [7:0] phase;
  logic dout_valid;

  clock_bus_if clock_bus ();
  cnt_bus_if cnt_bus ();
  modulation_bus_if mod_bus ();
  stm_bus_if stm_bus ();
  duty_table_bus_if duty_table_bus ();

  memory memory (
      .CLK(CLK),
      .MRCC_25P6M(MRCC_25P6M),
      .MEM_BUS(sim_helper_bram.memory_bus.bram_port),
      .CLOCK_BUS(clock_bus.in_port),
      .CNT_BUS(cnt_bus.in_port),
      .MOD_BUS(mod_bus.in_port),
      .STM_BUS(stm_bus.in_port),
      .DUTY_TABLE_BUS(duty_table_bus.in_port)
  );

  sim_helper_clk sim_helper_clk (
      .MRCC_25P6M(MRCC_25P6M),
      .CLK(CLK),
      .CLOCK_BUS(clock_bus.out_port),
      .LOCKED(locked),
      .SYS_TIME(SYS_TIME)
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
      .DEPTH(DEPTH),
      .MODE ("TRUNC")
  ) stm (
      .CLK(CLK),
      .SYS_TIME(SYS_TIME),
      .UPDATE(UPDATE),
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
    stm_settings.UPDATE <= 1'b1;
    stm_settings.REQ_RD_SEGMENT <= req_segment;
    stm_settings.REP[req_segment] <= rep;
    if (req_segment === 1'b0) begin
      stm_settings.CYCLE[0] = cycle_buf[req_segment] - 1;
      stm_settings.FREQ_DIV[0] = 512 * freq_div_buf[req_segment];
    end else begin
      stm_settings.CYCLE[1] = cycle_buf[req_segment] - 1;
      stm_settings.FREQ_DIV[1] = 512 * freq_div_buf[req_segment];
    end

    @(posedge CLK);
    stm_settings.UPDATE <= 1'b0;
  endtask

  task automatic wait_segment(input logic segment);
    while (1) begin
      @(posedge CLK);
      if (debug_segment === segment) begin
        break;
      end
    end
  endtask

  function automatic int abs_diff(input int x, input int y);
    automatic int abs = (x < y) ? y - x : x - y;
    abs_diff = (abs < 128) ? abs : 255 - abs;
  endfunction

  logic [7:0] sin_table [  256];
  logic [7:0] atan_table[16384];

  task automatic check(input logic segment);
    automatic int idx, ix, iy;
    automatic logic signed [63:0] x, y, z;
    automatic logic [63:0] r, lambda;
    automatic logic [7:0] p, phase_expect;
    automatic logic [7:0] cos, sin;

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
        x = focus_x[segment][debug_idx][0] - int'(10.16 * ix / 0.025);  // [0.025mm]
        y = focus_y[segment][debug_idx][0] - int'(10.16 * iy / 0.025);  // [0.025mm]
        z = focus_z[segment][debug_idx][0];  // [0.025mm]
        r = $rtoi($sqrt($itor(x * x + y * y + z * z)));  // [0.025mm]
        lambda = (r << 14) / stm_settings.SOUND_SPEED[segment];
        p = lambda % 256;
        sin = sin_table[p];
        cos = sin_table[(p+64)%256];
        phase_expect = atan_table[{sin[7:1], cos[7:1]}];
        if (intensity !== intensity_buf[segment][debug_idx][0]) begin
          $error("Failed at d_out=%d, d_in=%d @%d", intensity, intensity_buf[segment][debug_idx],
                 id);
          $finish();
        end
        if (abs_diff(phase_expect, phase) > 1) begin
          $error("Failed at p_out=%d, p_in=%d (r2=%d, r=%d, lambda=%d) @%d", phase, phase_expect,
                 x * x + y * y + z * z, r, lambda, idx);
          $error("x=%d, y=%d, z=%d", x, y, z);
          $error("cos=%d, sin=%d", cos, sin);
          $finish();
        end
        @(posedge CLK);
        idx++;
      end
    end
  endtask


  initial begin
    $readmemh("sin.txt", sin_table);
    $readmemh("atan.txt", atan_table);

    sim_helper_random.init();

    cycle_buf[0] = SIZE;
    cycle_buf[1] = SIZE / 4;
    freq_div_buf[0] = 1;
    freq_div_buf[1] = 3;

    stm_settings.TRANSITION_MODE = params::TRANSITION_MODE_SYNC_IDX;
    stm_settings.TRANSITION_VALUE = 0;
    stm_settings.MODE[0] = params::STM_MODE_FOCUS;
    stm_settings.MODE[1] = params::STM_MODE_FOCUS;
    stm_settings.SOUND_SPEED[0] = 340 * 64;
    stm_settings.SOUND_SPEED[1] = 340 * 64;
    stm_settings.CYCLE[0] = '0;
    stm_settings.FREQ_DIV[0] = '1;
    stm_settings.NUM_FOCI[0] = 1;
    stm_settings.CYCLE[1] = '0;
    stm_settings.FREQ_DIV[1] = '1;
    stm_settings.NUM_FOCI[1] = 1;

    @(posedge locked);

    for (int segment = 0; segment < 2; segment++) begin
      for (int i = 0; i < SIZE; i++) begin
        focus_x[segment][i][0] = sim_helper_random.range(131071, -131072 + 6908);
        focus_y[segment][i][0] = sim_helper_random.range(131071, -131072 + 5283);
        focus_z[segment][i][0] = sim_helper_random.range(131071, -131072);
        intensity_buf[segment][i][0] = sim_helper_random.range(8'hFF, 0);
      end
      sim_helper_bram.write_stm_focus(segment, focus_x[segment], focus_y[segment], focus_z[segment],
                                      intensity_buf[segment], cycle_buf[segment], 1);
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
