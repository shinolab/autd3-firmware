`timescale 1ns / 1ps
module sim_mod_modulation ();

  localparam int DEPTH = 249;
  localparam int SIZE = 32768;

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

  logic update_settings;
  settings::mod_settings_t mod_settings;
  mod_cnt_if mod_cnt ();

  cnt_bus_if cnt_bus ();
  modulation_bus_if mod_bus ();
  normal_bus_if normal_bus ();
  stm_bus_if stm_bus ();
  duty_table_bus_if duty_table_bus ();

  memory memory (
      .CLK(CLK),
      .MEM_BUS(sim_helper_bram.memory_bus.bram_port),
      .CNT_BUS_IF(cnt_bus.in_port),
      .MOD_BUS(mod_bus.in_port),
      .NORMAL_BUS(normal_bus.in_port),
      .STM_BUS(stm_bus.in_port),
      .DUTY_TABLE_BUS(duty_table_bus.in_port)
  );

  logic din_valid;
  logic [7:0] intensity_in;
  logic [7:0] phase_in;

  logic dout_valid;
  logic [15:0] intensity_out;
  logic [7:0] phase_out;
  logic [14:0] idx_debug;

  modulation #(
      .DEPTH(DEPTH)
  ) modulation (
      .CLK(CLK),
      .SYS_TIME(sys_time),
      .UPDATE_SETTINGS(update_settings),
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

  logic [7:0] mod_0[SIZE] = '{SIZE{'0}}, mod_1[SIZE] = '{SIZE{'0}};
  logic [7:0] intensity_buf[DEPTH];
  logic [7:0] phase_buf[DEPTH];
  logic [14:0] idx_buf;

  always @(posedge din_valid) begin
    @(posedge CLK);
    @(posedge CLK);
    idx_buf <= idx_debug;
  end

  task automatic update(logic req_segment, logic [31:0] rep);
    @(posedge CLK);
    update_settings <= 1'b1;
    mod_settings.REQ_RD_SEGMENT = req_segment;
    mod_settings.REP = rep;
    @(posedge CLK);
    update_settings <= 1'b0;
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

  logic [15:0] expect_intensity;
  task automatic check(logic segment);
    while (1) begin
      @(posedge CLK);
      if (dout_valid) begin
        break;
      end
    end
    for (int i = 0; i < DEPTH; i++) begin
      if (stop_debug == 1'b0) begin
        if (segment === 1'b0) begin
          expect_intensity = int'(intensity_buf[i]) * mod_0[(idx_buf+mod_settings.CYCLE_0+1)%(mod_settings.CYCLE_0+1)];
        end else begin
          expect_intensity = int'(intensity_buf[i]) * mod_1[(idx_buf+mod_settings.CYCLE_1+1)%(mod_settings.CYCLE_1+1)];
        end
      end else begin
        if (segment === 1'b0) begin
          expect_intensity = int'(intensity_buf[i]) * mod_0[mod_settings.CYCLE_0];
        end else begin
          expect_intensity = int'(intensity_buf[i]) * mod_1[mod_settings.CYCLE_1];
        end
      end
      if (intensity_out !== expect_intensity) begin
        $error("Intensity[%d] at %d: d=%d, %d !== %d", segment, i, intensity_buf[i],
               expect_intensity, intensity_out);
        $finish();
      end
      if (phase_out !== phase_buf[i]) begin
        $error("Phase[%d] at %d: %d !== %d", segment, i, phase_buf[i], phase_out);
        $finish();
      end
      @(posedge CLK);
    end
  endtask

  initial begin
    sim_helper_random.init();

    din_valid <= 1'b0;
    //    mod_settings.CYCLE_0 = 16'hFFFF;
    mod_settings.CYCLE_0 = 10 - 1;
    mod_settings.FREQ_DIV_0 = 512;
    mod_settings.CYCLE_1 = 5 - 1;
    mod_settings.FREQ_DIV_1 = 512 * 2;
    update(0, 32'hFFFFFFFF);

    @(posedge locked);

    #15000;

    for (int i = 0; i < mod_settings.CYCLE_0 + 1; i++) begin
      mod_0[i] = sim_helper_random.range(8'hFF, 0);
    end
    sim_helper_bram.write_mod(0, mod_0, mod_settings.CYCLE_0 + 1);
    for (int i = 0; i < mod_settings.CYCLE_1 + 1; i++) begin
      mod_1[i] = sim_helper_random.range(8'hFF, 0);
    end
    sim_helper_bram.write_mod(1, mod_1, mod_settings.CYCLE_1 + 1);

    while (1'b1) begin
      fork
        set();
        check(0);
      join
      if (idx_buf === 5) break;
      @(posedge CLK);
    end

    update(1, 32'd0);
    while (1'b1) begin
      if (segment_debug == 1'b1) break;
      @(posedge CLK);
    end

    for (int i = 0; i < 15; i++) begin
      fork
        set();
        check(1);
      join
    end

    #1000;
    update(0, 32'd1);
    @(negedge stop_debug);
    for (int i = 0; i < 25; i++) begin
      fork
        set();
        check(0);
      join
    end

    $display("OK! sim_mod_modulation");
  end

endmodule
