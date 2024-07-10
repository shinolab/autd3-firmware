`timescale 1ns / 1ps
module sim_mod_modulation ();

  `define ASSERT_EQ(expected, actual) \
  if (expected !== actual) begin \
    $error("%s:%d: expected is %s, but actual is %s", `__FILE__, `__LINE__, $sformatf("%0d", expected), $sformatf("%0d", actual));\
    $finish();\
  end

  localparam int DEPTH = 249;
  localparam int SIZE = 10;

  logic CLK;
  logic locked;
  logic [63:0] sys_time;

  sim_helper_random sim_helper_random ();
  sim_helper_bram #(.DEPTH(DEPTH)) sim_helper_bram ();

  settings::mod_settings_t mod_settings;

  cnt_bus_if cnt_bus ();
  modulation_bus_if mod_bus ();
  stm_bus_if stm_bus ();
  pwe_table_bus_if pwe_table_bus ();

  memory memory (
      .CLK(CLK),
      .MRCC_25P6M(MRCC_25P6M),
      .MEM_BUS(sim_helper_bram.memory_bus.bram_port),
      .CNT_BUS(cnt_bus.in_port),
      .MOD_BUS(mod_bus.in_port),
      .STM_BUS(stm_bus.in_port),
      .PWE_TABLE_BUS(pwe_table_bus.in_port)
  );

  sim_helper_clk sim_helper_clk (
      .MRCC_25P6M(MRCC_25P6M),
      .CLK(CLK),
      .LOCKED(locked),
      .SYS_TIME(sys_time)
  );

  logic din_valid;
  logic [7:0] intensity_in;
  logic [7:0] phase_in;

  logic dout_valid;
  logic [7:0] intensity_out;
  logic [7:0] phase_out;
  logic [14:0] idx_debug;

  modulation #(
      .DEPTH(DEPTH)
  ) modulation (
      .CLK(CLK),
      .SYS_TIME(sys_time),
      .MOD_SETTINGS(mod_settings),
      .DIN_VALID(din_valid),
      .INTENSITY_IN(intensity_in),
      .INTENSITY_OUT(intensity_out),
      .PHASE_IN(phase_in),
      .PHASE_OUT(phase_out),
      .DOUT_VALID(dout_valid),
      .MOD_BUS(mod_bus.out_port),
      .DEBUG_IDX(idx_debug),
      .DEBUG_SEGMENT(segment_debug),
      .DEBUG_STOP(stop_debug)
  );

  logic [14:0] cycle_buf[2];
  logic [15:0] freq_div_buf[2];
  logic [7:0] mod_buf[2][SIZE];
  logic [7:0] intensity_buf[DEPTH];
  logic [7:0] phase_buf[DEPTH];

  task automatic update(input logic req_segment, input logic [31:0] rep);
    @(posedge CLK);
    mod_settings.UPDATE <= 1'b1;
    mod_settings.REQ_RD_SEGMENT <= req_segment;
    mod_settings.CYCLE[req_segment] = cycle_buf[req_segment] - 1;
    mod_settings.FREQ_DIV[req_segment] = freq_div_buf[req_segment];
    mod_settings.REP[req_segment] <= rep;
    @(posedge CLK);
    mod_settings.UPDATE <= 1'b0;
  endtask

  task automatic set();
    for (int i = 0; i < DEPTH; i++) begin
      intensity_buf[i] = sim_helper_random.range(8'hFF, 0);
      phase_buf[i] = sim_helper_random.range(8'hFF, 0);
    end
    while (sys_time[8:0] !== '0) @(posedge CLK);
    for (int i = 0; i < DEPTH; i++) begin
      @(posedge CLK);
      din_valid <= 1'b1;
      intensity_in <= intensity_buf[i];
      phase_in <= phase_buf[i];
    end
    @(posedge CLK);
    din_valid <= 1'b0;
  endtask

  logic [7:0] expect_intensity;
  logic [7:0] expect_phase;
  task automatic check();
    while (1) begin
      @(posedge CLK);
      if (dout_valid) begin
        break;
      end
    end
    for (int i = 0; i < DEPTH; i++) begin
      if (stop_debug == 1'b0) begin
        expect_intensity = (int'(intensity_buf[i]) * (mod_buf[segment_debug][(idx_debug+cycle_buf[segment_debug])%cycle_buf[segment_debug]]+1)) / 256;
      end else begin
        expect_intensity = (int'(intensity_buf[i]) * (mod_buf[segment_debug][cycle_buf[segment_debug]-1]+1)) / 256;
      end
      expect_phase = phase_buf[i];
      `ASSERT_EQ(expect_intensity, intensity_out);
      `ASSERT_EQ(phase_buf[i], phase_out);
      @(posedge CLK);
    end
  endtask

  initial begin
    sim_helper_random.init();

    cycle_buf[0] = SIZE;
    cycle_buf[1] = SIZE / 2;
    freq_div_buf[0] = 1;
    freq_div_buf[1] = 2;

    din_valid = 1'b0;

    mod_settings.UPDATE = 1'b0;
    mod_settings.TRANSITION_MODE = params::TRANSITION_MODE_SYNC_IDX;
    mod_settings.TRANSITION_VALUE = '0;
    mod_settings.CYCLE[0] = '0;
    mod_settings.FREQ_DIV[0] = '1;
    mod_settings.CYCLE[1] = '0;
    mod_settings.FREQ_DIV[1] = '1;

    mod_buf[0] = '{SIZE{'0}};
    mod_buf[1] = '{SIZE{'0}};

    @(posedge locked);

    for (int segment = 0; segment < 2; segment++) begin
      for (int i = 0; i < SIZE; i++) begin
        mod_buf[segment][i] = sim_helper_random.range(8'hFF, 0);
      end
      sim_helper_bram.write_mod(segment, mod_buf[segment], cycle_buf[segment]);
    end

    update(0, 32'hFFFFFFFF);
    while (1'b1) begin
      fork
        set();
        check();
      join
      if (idx_debug === 5) break;
      @(posedge CLK);
    end

    update(1, 32'd0);
    for (int i = 0; i < 15; i++) begin
      fork
        set();
        check();
      join
    end

    update(0, 32'd1);
    for (int i = 0; i < 25; i++) begin
      fork
        set();
        check();
      join
    end

    $display("OK! sim_mod_modulation");
    $finish();
  end

endmodule
