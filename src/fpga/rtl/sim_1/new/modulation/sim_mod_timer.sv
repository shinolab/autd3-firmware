`timescale 1ns / 1ps
module sim_mod_timer ();

  `include "define.vh"

  localparam int DivLatency = 50;
  localparam int DEPTH = 249;

  logic CLK;
  logic locked;
  logic [56:0] sys_time;
  sim_helper_clk sim_helper_clk (
      .MRCC_25P6M(),
      .CLK(CLK),
      .LOCKED(locked),
      .SYS_TIME(sys_time)
  );

  sim_helper_random sim_helper_random ();
  sim_helper_bram #(.DEPTH(DEPTH)) sim_helper_bram ();

  settings::mod_settings_t mod_settings;
  logic update_settings;
  logic [15:0] idx[params::NumSegment];

  modulation_timer modulation_timer (
      .CLK(CLK),
      .UPDATE_SETTINGS_IN(update_settings),
      .SYS_TIME(sys_time),
      .CYCLE(mod_settings.CYCLE),
      .FREQ_DIV(mod_settings.FREQ_DIV),
      .IDX(idx),
      .UPDATE_SETTINGS_OUT()
  );

  logic [15:0] expect_idx[params::NumSegment];
  for (genvar i = 0; i < params::NumSegment; i++) begin
    assign expect_idx[i] = ((sys_time - 2 * DivLatency - 2) / 512 / mod_settings.FREQ_DIV[i]) % (mod_settings.CYCLE[i] + 1);
  end

  task automatic check(int segment);
    automatic logic [15:0] idx_old;
    idx_old = idx[segment];
    for (int i = 0; i < mod_settings.CYCLE[segment] + 1; i++) begin
      while (1) begin
        @(posedge CLK);
        if (idx_old !== idx[segment]) begin
          break;
        end
      end
      idx_old = idx[segment];
      `ASSERT_EQ(expect_idx[segment], idx[segment]);
      $display("Check[%1d] %d/%d...done", segment, i + 1, mod_settings.CYCLE[segment] + 1);
    end
  endtask

  initial begin
    sim_helper_random.init();

    update_settings = 1'b0;
    mod_settings.REQ_RD_SEGMENT = 1'b0;
    mod_settings.CYCLE[0] = 65536 - 1;
    mod_settings.FREQ_DIV[0] = 1;
    mod_settings.CYCLE[1] = 1000 - 1;
    mod_settings.FREQ_DIV[1] = 3;
    mod_settings.REP[0] = 16'hFFFF;
    mod_settings.REP[1] = 16'hFFFF;

    @(posedge locked);

    while (sys_time < 2 * DivLatency) begin
      @(posedge CLK);
    end

    @(posedge CLK);
    update_settings <= 1'b1;
    @(posedge CLK);
    update_settings <= 1'b0;

    #15000;

    fork
      check(0);
      check(1);
    join

    $display("OK! sim_mod_timer");
    $finish();
  end

endmodule
