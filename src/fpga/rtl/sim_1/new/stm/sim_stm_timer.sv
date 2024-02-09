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
  stm_cnt_if stm_cnt ();
  logic [15:0] idx_0, idx_1;

  assign idx_0 = stm_cnt.IDX_0;
  assign idx_1 = stm_cnt.IDX_1;

  stm_timer stm_timer (
      .CLK(CLK),
      .SYS_TIME(sys_time),
      .CYCLE_0(stm_settings.CYCLE_0),
      .FREQ_DIV_0(stm_settings.FREQ_DIV_0),
      .CYCLE_1(stm_settings.CYCLE_1),
      .FREQ_DIV_1(stm_settings.FREQ_DIV_1),
      .STM_CNT(stm_cnt.timer_port)
  );

  logic [15:0] expect_idx_0, expect_idx_1;
  assign expect_idx_0 = ((sys_time - DivLatency * 2 - 1) / stm_settings.FREQ_DIV_0) % (stm_settings.CYCLE_0 + 1);
  assign expect_idx_1 = ((sys_time - DivLatency * 2 - 1) / stm_settings.FREQ_DIV_1) % (stm_settings.CYCLE_1 + 1);

  task automatic check_0();
    logic [15:0] idx_old;
    idx_old = idx_0;
    for (int i = 0; i < stm_settings.CYCLE_0 + 10; i++) begin
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
      $display("Check[0] %d/%d...done", i + 1, stm_settings.CYCLE_0 + 1);
    end
  endtask

  task automatic check_1();
    logic [14:0] idx_old;
    idx_old = idx_1;
    for (int i = 0; i < stm_settings.CYCLE_0 + 1; i++) begin
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
      $display("Check[1][%d] %d/%d...done", (i + 1) / (stm_settings.CYCLE_1 + 1),
               (i + 1) % (stm_settings.CYCLE_1 + 1), stm_settings.CYCLE_1 + 1);
    end
  endtask

  initial begin
    sim_helper_random.init();

    stm_settings.REQ_RD_SEGMENT = 1'b0;
    stm_settings.CYCLE_0 = 65536 - 1;
    stm_settings.FREQ_DIV_0 = 8;
    stm_settings.CYCLE_1 = 1000 - 1;
    stm_settings.FREQ_DIV_1 = 8 * 3;
    stm_settings.REP = 32'hFFFFFFFF;

    @(posedge locked);

    #15000;

    fork
      check_0();
      check_1();
    join

    $display("OK! sim_stm_timer");
    $finish();
  end

endmodule
