`timescale 1ns / 1ps
module sim_mod_timer ();

  localparam int DivLatency = 66;
  localparam int DEPTH = 249;

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
  logic update_settings;
  logic [14:0] idx_0, idx_1;

  modulation_timer modulation_timer (
      .CLK(CLK),
      .UPDATE_SETTINGS_IN(update_settings),
      .SYS_TIME(sys_time),
      .CYCLE_0(mod_settings.CYCLE_0),
      .FREQ_DIV_0(mod_settings.FREQ_DIV_0),
      .CYCLE_1(mod_settings.CYCLE_1),
      .FREQ_DIV_1(mod_settings.FREQ_DIV_1),
      .IDX_0(idx_0),
      .IDX_1(idx_1),
      .UPDATE_SETTINGS_OUT()
  );

  logic [14:0] expect_idx_0, expect_idx_1;
  assign expect_idx_0 = ((sys_time - DivLatency * 2) / mod_settings.FREQ_DIV_0) % (mod_settings.CYCLE_0 + 1);
  assign expect_idx_1 = ((sys_time - DivLatency * 2) / mod_settings.FREQ_DIV_1) % (mod_settings.CYCLE_1 + 1);

  task automatic check_0();
    automatic logic [14:0] idx_old;
    idx_old = idx_0;
    for (int i = 0; i < mod_settings.CYCLE_0 + 1; i++) begin
      while (1) begin
        @(posedge CLK);
        if (idx_old !== idx_0) begin
          break;
        end
      end
      idx_old = idx_0;
      if (expect_idx_0 !== idx_0) begin
        $error("Index[0] %d !== %d", expect_idx_0, idx_0);
        $finish();
      end
      $display("Check[0] %d/%d...done", i + 1, mod_settings.CYCLE_0 + 1);
    end
  endtask

  task automatic check_1();
    automatic logic [14:0] idx_old;
    idx_old = idx_1;
    for (int i = 0; i < (mod_settings.CYCLE_0 + 1) / 3; i++) begin
      while (1) begin
        @(posedge CLK);
        if (idx_old !== idx_1) begin
          break;
        end
      end
      idx_old = idx_1;
      if (expect_idx_1 !== idx_1) begin
        $error("Index[1] %d !== %d", expect_idx_1, idx_1);
        $finish();
      end
      $display("Check[1][%d] %d/%d...done", (i + 1) / (mod_settings.CYCLE_1 + 1),
               (i + 1) % (mod_settings.CYCLE_1 + 1), mod_settings.CYCLE_1 + 1);
    end
  endtask

  initial begin
    sim_helper_random.init();

    update_settings = 1'b0;
    mod_settings.REQ_RD_SEGMENT = 1'b0;
    mod_settings.CYCLE_0 = 32768 - 1;
    mod_settings.FREQ_DIV_0 = 8;
    mod_settings.CYCLE_1 = 1000 - 1;
    mod_settings.FREQ_DIV_1 = 8 * 3;
    mod_settings.REP = 32'hFFFFFFFF;

    @(posedge locked);

    @(posedge CLK);
    update_settings <= 1'b1;
    @(posedge CLK);
    update_settings <= 1'b0;

    #15000;

    fork
      check_0();
      check_1();
    join

    $display("OK! sim_mod_timer");
    $finish();
  end

endmodule
