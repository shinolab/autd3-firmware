`timescale 1ns / 1ps
module sim_synchronizer ();

  localparam int ECAT_SYNC_BASE = 500000;  // 500 us
  localparam logic [15:0] ECAT_SYNC_CYCLE_TICKS = 4;

  logic CLK_20P48M, CLK_20P48M_p50, CLK_20P48M_m50;
  logic [63:0] SYS_TIME, SYS_TIME_p50, SYS_TIME_m50;
  logic [63:0] SYS_TIME_WO_SYNC, SYS_TIME_p50_WO_SYNC, SYS_TIME_m50_WO_SYNC;
  logic signed [64:0] diff_p50, diff_m50;

  logic ECAT_SYNC;

  logic set;
  logic [63:0] ecat_sync_time;  // [ns]
  settings::sync_settings_t SYNC_SETTINGS;
  assign SYNC_SETTINGS.UPDATE = set;
  assign SYNC_SETTINGS.ECAT_SYNC_BASE_CNT = 40000 * 512 / 2000;
  assign SYNC_SETTINGS.ECAT_SYNC_TIME = ecat_sync_time;

  assign diff_p50 = SYS_TIME_p50 - SYS_TIME;
  assign diff_m50 = SYS_TIME_m50 - SYS_TIME;

  synchronizer synchronizer (
      .CLK(CLK_20P48M),
      .SYNC_SETTINGS(SYNC_SETTINGS),
      .ECAT_SYNC(ECAT_SYNC),
      .SYS_TIME(SYS_TIME),
      .SYNC(),
      .SKIP_ONE_ASSERT()
  );

  synchronizer synchronizer_p50 (
      .CLK(CLK_20P48M_p50),
      .SYNC_SETTINGS(SYNC_SETTINGS),
      .ECAT_SYNC(ECAT_SYNC),
      .SYS_TIME(SYS_TIME_p50),
      .SYNC(),
      .SKIP_ONE_ASSERT()
  );

  synchronizer synchronizer_m50 (
      .CLK(CLK_20P48M_m50),
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
    @(posedge CLK_20P48M);
    @(posedge CLK_20P48M_p50);
    @(posedge CLK_20P48M_m50);
    set = 0;
    @(negedge ECAT_SYNC);
    SYS_TIME_WO_SYNC <= SYS_TIME;
    SYS_TIME_p50_WO_SYNC <= SYS_TIME_p50;
    SYS_TIME_m50_WO_SYNC <= SYS_TIME_m50;
  endtask

  initial begin
    CLK_20P48M = 1;
    CLK_20P48M_p50 = 1;
    CLK_20P48M_m50 = 1;
    SYS_TIME = 0;
    SYS_TIME_p50 = 0;
    SYS_TIME_m50 = 0;
    SYS_TIME_WO_SYNC = 0;
    SYS_TIME_p50_WO_SYNC = 0;
    SYS_TIME_m50_WO_SYNC = 0;

    set = 0;

    #10000;

    sync();

    #1000000000;

    $finish();
  end

  // (7 + 1) / (48.828ns * 7 + 48.829ns * 1) = 20.48MHz
  always begin
    for (int i = 0; i < 7; i++) begin
      #24.414 CLK_20P48M = ~CLK_20P48M;
      #24.414 CLK_20P48M = ~CLK_20P48M;
    end
    #24.414 CLK_20P48M = ~CLK_20P48M;
    #24.415 CLK_20P48M = ~CLK_20P48M;
  end

  // (6326 + 13675) / (48.825ns * 6326 + 48.826ns * 13675) = 20.48MHz + 50ppm
  always begin
    for (int i = 0; i < 6326; i++) begin
      #24.412 CLK_20P48M_p50 = ~CLK_20P48M_p50;
      #24.413 CLK_20P48M_p50 = ~CLK_20P48M_p50;
      #24.413 CLK_20P48M_p50 = ~CLK_20P48M_p50;
      #24.413 CLK_20P48M_p50 = ~CLK_20P48M_p50;
      #24.413 CLK_20P48M_p50 = ~CLK_20P48M_p50;
      #24.413 CLK_20P48M_p50 = ~CLK_20P48M_p50;
    end
    for (int i = 0; i < 13675 - 6326 * 2; i++) begin
      #24.413 CLK_20P48M_p50 = ~CLK_20P48M_p50;
      #24.413 CLK_20P48M_p50 = ~CLK_20P48M_p50;
    end
  end

  // (8669 + 11330) / (48.830ns * 8669 + 48.831ns * 11330) = 20.48MHz - 50ppm
  always begin
    for (int i = 0; i < 8669; i++) begin
      #24.415 CLK_20P48M_m50 = ~CLK_20P48M_m50;
      #24.415 CLK_20P48M_m50 = ~CLK_20P48M_m50;
      #24.415 CLK_20P48M_m50 = ~CLK_20P48M_m50;
      #24.416 CLK_20P48M_m50 = ~CLK_20P48M_m50;
    end
    for (int i = 0; i < 11330 - 8669; i++) begin
      #24.415 CLK_20P48M_m50 = ~CLK_20P48M_m50;
      #24.416 CLK_20P48M_m50 = ~CLK_20P48M_m50;
    end
  end

  always begin
    #800 ECAT_SYNC = 0;
    #(ECAT_SYNC_BASE * ECAT_SYNC_CYCLE_TICKS - 800) ECAT_SYNC = 1;
  end

  always @(posedge CLK_20P48M) SYS_TIME_WO_SYNC <= SYS_TIME_WO_SYNC + 1;

  always @(posedge CLK_20P48M_p50) SYS_TIME_p50_WO_SYNC <= SYS_TIME_p50_WO_SYNC + 1;

  always @(posedge CLK_20P48M_m50) SYS_TIME_m50_WO_SYNC <= SYS_TIME_m50_WO_SYNC + 1;


endmodule
