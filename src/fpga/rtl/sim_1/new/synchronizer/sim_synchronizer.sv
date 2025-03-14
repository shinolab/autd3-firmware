`timescale 1ns / 1ps
module sim_synchronizer ();

  localparam int ECAT_SYNC_BASE = 500000;  // 500 us
  localparam logic [15:0] ECAT_SYNC_CYCLE_TICKS = 4;

  logic CLK_25P6M, CLK_25P6M_p50, CLK_25P6M_m50;

  logic CLK, CLK_p50, CLK_m50;
  logic [60:0] SYS_TIME, SYS_TIME_p50, SYS_TIME_m50;
  logic [60:0] SYS_TIME_WO_SYNC, SYS_TIME_p50_WO_SYNC, SYS_TIME_m50_WO_SYNC;
  logic signed [64:0] diff_p50, diff_m50;

  logic ECAT_SYNC;

  logic set;
  logic [63:0] ecat_sync_time;  // [ns]
  settings::sync_settings_t SYNC_SETTINGS;
  assign SYNC_SETTINGS.UPDATE = set;
  assign SYNC_SETTINGS.ECAT_SYNC_TIME = ecat_sync_time;

  assign diff_p50 = SYS_TIME_p50 - SYS_TIME;
  assign diff_m50 = SYS_TIME_m50 - SYS_TIME;

  clk_wiz clk_wiz (
      .clk_in1(CLK_25P6M),
      .clk_out1(CLK),
      .reset(),
      .locked(lock)
  );

  clk_wiz clk_wiz_p50 (
      .clk_in1(CLK_25P6M_p50),
      .clk_out1(CLK_p50),
      .reset(),
      .locked(lock_p50)
  );

  clk_wiz clk_wiz_m50 (
      .clk_in1(CLK_25P6M_m50),
      .clk_out1(CLK_m50),
      .reset(),
      .locked(lock_m50)
  );

  synchronizer synchronizer (
      .CLK(CLK),
      .SYNC_SETTINGS(SYNC_SETTINGS),
      .ECAT_SYNC(ECAT_SYNC),
      .SYS_TIME(SYS_TIME),
      .SYNC(),
      .SKIP_ONE_ASSERT()
  );

  synchronizer synchronizer_p50 (
      .CLK(CLK_p50),
      .SYNC_SETTINGS(SYNC_SETTINGS),
      .ECAT_SYNC(ECAT_SYNC),
      .SYS_TIME(SYS_TIME_p50),
      .SYNC(),
      .SKIP_ONE_ASSERT()
  );

  synchronizer synchronizer_m50 (
      .CLK(CLK_m50),
      .SYNC_SETTINGS(SYNC_SETTINGS),
      .ECAT_SYNC(ECAT_SYNC),
      .SYS_TIME(SYS_TIME_m50),
      .SYNC(),
      .SKIP_ONE_ASSERT()
  );

  task sync();
    @(posedge ECAT_SYNC);
    #1000;

    ecat_sync_time = ECAT_SYNC_BASE * 3;
    set = 1;
    @(posedge CLK);
    @(posedge CLK_p50);
    @(posedge CLK_m50);
    set = 0;
    @(negedge ECAT_SYNC);
    SYS_TIME_WO_SYNC <= SYS_TIME;
    SYS_TIME_p50_WO_SYNC <= SYS_TIME_p50;
    SYS_TIME_m50_WO_SYNC <= SYS_TIME_m50;
  endtask

  initial begin
    CLK_25P6M = 1;
    CLK_25P6M_p50 = 1;
    CLK_25P6M_m50 = 1;
    SYS_TIME = 0;
    SYS_TIME_p50 = 0;
    SYS_TIME_m50 = 0;
    SYS_TIME_WO_SYNC = 0;
    SYS_TIME_p50_WO_SYNC = 0;
    SYS_TIME_m50_WO_SYNC = 0;

    set = 0;

    while (~(lock & lock_p50 & lock_m50)) #1000;

    sync();

    #1000000000;

    $finish();
  end

  // (1 + 1) / (39.062ns * 1 + 39.063ns * 1) = 25.6MHz
  always begin
    #19.531 CLK_25P6M = ~CLK_25P6M;
    #19.531 CLK_25P6M = ~CLK_25P6M;
    #19.531 CLK_25P6M = ~CLK_25P6M;
    #19.532 CLK_25P6M = ~CLK_25P6M;
  end

  // (10940 + 9061) / (39.061ns * 10940 + 39.060ns * 9061) = 25.6MHz + 50ppm
  always begin
    for (int i = 0; i < 9061; i++) begin
      #19.530 CLK_25P6M_p50 = ~CLK_25P6M_p50;
      #19.530 CLK_25P6M_p50 = ~CLK_25P6M_p50;
      #19.530 CLK_25P6M_p50 = ~CLK_25P6M_p50;
      #19.531 CLK_25P6M_p50 = ~CLK_25P6M_p50;
    end
    for (int i = 0; i < 10940 - 9061; i++) begin
      #19.530 CLK_25P6M_p50 = ~CLK_25P6M_p50;
      #19.531 CLK_25P6M_p50 = ~CLK_25P6M_p50;
    end
  end

  // (9064 + 10935) / (39.065ns * 9064 +  39.064ns * 10935) = 25.6MHz - 50ppm
  always begin
    for (int i = 0; i < 9064; i++) begin
      #19.532 CLK_25P6M_m50 = ~CLK_25P6M_m50;
      #19.533 CLK_25P6M_m50 = ~CLK_25P6M_m50;
      #19.532 CLK_25P6M_m50 = ~CLK_25P6M_m50;
      #19.532 CLK_25P6M_m50 = ~CLK_25P6M_m50;
    end
    for (int i = 0; i < 10935 - 9064; i++) begin
      #19.532 CLK_25P6M_m50 = ~CLK_25P6M_m50;
      #19.533 CLK_25P6M_m50 = ~CLK_25P6M_m50;
    end
  end

  always begin
    #800 ECAT_SYNC = 0;
    #(ECAT_SYNC_BASE * ECAT_SYNC_CYCLE_TICKS - 800) ECAT_SYNC = 1;
  end

  always @(posedge CLK) SYS_TIME_WO_SYNC <= SYS_TIME_WO_SYNC + 1;
  always @(posedge CLK_p50) SYS_TIME_p50_WO_SYNC <= SYS_TIME_p50_WO_SYNC + 1;
  always @(posedge CLK_m50) SYS_TIME_m50_WO_SYNC <= SYS_TIME_m50_WO_SYNC + 1;

endmodule
