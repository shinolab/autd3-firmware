`timescale 1ns / 1ps
module sim_stm_timer ();

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

  settings::stm_settings_t stm_settings;
  logic update_settings;
  logic [15:0] idx[2];

  stm_timer stm_timer (
      .CLK(CLK),
      .UPDATE_SETTINGS_IN(update_settings),
      .SYS_TIME(sys_time),
      .CYCLE(stm_settings.CYCLE),
      .FREQ_DIV(stm_settings.FREQ_DIV),
      .IDX(idx),
      .UPDATE_SETTINGS_OUT()
  );

  logic [15:0] expect_idx[2];
  assign expect_idx[0] = ((sys_time - DivLatency * 2) / stm_settings.FREQ_DIV[0]) % (stm_settings.CYCLE[0] + 1);
  assign expect_idx[1] = ((sys_time - DivLatency * 2) / stm_settings.FREQ_DIV[1]) % (stm_settings.CYCLE[1] + 1);

  task automatic check_0();
    logic [15:0] idx_old;
    idx_old = idx[0];
    for (int i = 0; i < stm_settings.CYCLE[0] + 10; i++) begin
      while (1) begin
        @(posedge CLK);
        if (idx_old !== idx[0]) begin
          break;
        end
      end
      idx_old = idx[0];
      if (expect_idx[0] !== idx[0]) begin
        $error("Index[0] %d !== %d", expect_idx[0], idx[0]);
        $finish();
      end
      $display("Check[0] %d/%d...done", i + 1, stm_settings.CYCLE[0] + 1);
    end
  endtask

  task automatic check_1();
    logic [14:0] idx_old;
    idx_old = idx[1];
    for (int i = 0; i < stm_settings.CYCLE[0] + 1; i++) begin
      while (1) begin
        @(posedge CLK);
        if (idx_old !== idx[1]) begin
          break;
        end
      end
      idx_old = idx[1];
      if (expect_idx[1] !== idx[1]) begin
        $error("Index[1] %d !== %d", expect_idx[1], idx[1]);
        $finish();
      end
      $display("Check[1][%d] %d/%d...done", (i + 1) / (stm_settings.CYCLE[1] + 1),
               (i + 1) % (stm_settings.CYCLE[1] + 1), stm_settings.CYCLE[1] + 1);
    end
  endtask

  initial begin
    sim_helper_random.init();

    update_settings = 1'b0;
    stm_settings.REQ_RD_SEGMENT = 1'b0;
    stm_settings.CYCLE[0] = 65536 - 1;
    stm_settings.FREQ_DIV[0] = 8;
    stm_settings.CYCLE[1] = 1000 - 1;
    stm_settings.FREQ_DIV[1] = 8 * 3;
    stm_settings.REP[0] = 32'hFFFFFFFF;
    stm_settings.REP[1] = 32'hFFFFFFFF;

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

    $display("OK! sim_stm_timer");
    $finish();
  end

endmodule
