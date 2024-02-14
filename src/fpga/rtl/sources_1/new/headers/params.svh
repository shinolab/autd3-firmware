package params;

  localparam int NUM_TRANSDUCERS = 249;

  localparam int GAIN_STM_SIZE = 1024;
  localparam int STM_WR_ADDR_WIDTH = $clog2(GAIN_STM_SIZE * 256);
  localparam int STM_RD_ADDR_WIDTH = $clog2(GAIN_STM_SIZE * 64);

  localparam bit [7:0] VERSION_NUM = 8'h8F;
  localparam bit [7:0] VERSION_NUM_MINOR = 8'h00;

  localparam bit [1:0] BRAM_SELECT_CONTROLLER = 2'h0;
  localparam bit [1:0] BRAM_SELECT_MOD = 2'h1;
  localparam bit [1:0] BRAM_SELECT_DUTY_TABLE = 2'h2;
  localparam bit [1:0] BRAM_SELECT_STM = 2'h3;

  localparam bit STM_MODE_FOCUS = 1'b0;
  localparam bit STM_MODE_GAIN = 1'b1;

  localparam bit SILNCER_MODE_FIXED_COMPLETION_STEPS = 1'b0;
  localparam bit SILNCER_MODE_FIXED_UPDATE_RATE = 1'b1;

  localparam bit [7:0] ADDR_CTL_FLAG = 8'h00;
  localparam bit [7:0] ADDR_FPGA_STATE = 8'h01;
  localparam bit [7:0] ADDR_ECAT_SYNC_TIME_0 = 8'h11;
  localparam bit [7:0] ADDR_ECAT_SYNC_TIME_1 = ADDR_ECAT_SYNC_TIME_0 + 1;
  localparam bit [7:0] ADDR_ECAT_SYNC_TIME_2 = ADDR_ECAT_SYNC_TIME_0 + 2;
  localparam bit [7:0] ADDR_ECAT_SYNC_TIME_3 = ADDR_ECAT_SYNC_TIME_0 + 3;
  localparam bit [7:0] ADDR_MOD_MEM_WR_SEGMENT = 8'h20;
  localparam bit [7:0] ADDR_MOD_REQ_RD_SEGMENT = 8'h21;
  localparam bit [7:0] ADDR_MOD_CYCLE_0 = 8'h22;
  localparam bit [7:0] ADDR_MOD_FREQ_DIV_0_0 = 8'h23;
  localparam bit [7:0] ADDR_MOD_FREQ_DIV_0_1 = 8'h24;
  localparam bit [7:0] ADDR_MOD_CYCLE_1 = 8'h25;
  localparam bit [7:0] ADDR_MOD_FREQ_DIV_1_0 = 8'h26;
  localparam bit [7:0] ADDR_MOD_FREQ_DIV_1_1 = 8'h27;
  localparam bit [7:0] ADDR_MOD_REP_0_0 = 8'h28;
  localparam bit [7:0] ADDR_MOD_REP_0_1 = 8'h29;
  localparam bit [7:0] ADDR_MOD_REP_1_0 = 8'h2A;
  localparam bit [7:0] ADDR_MOD_REP_1_1 = 8'h2B;
  localparam bit [7:0] ADDR_VERSION_NUM_MAJOR = 8'h30;
  localparam bit [7:0] ADDR_VERSION_NUM_MINOR = 8'h31;
  localparam bit [7:0] ADDR_SILENCER_MODE = 8'h40;
  localparam bit [7:0] ADDR_SILENCER_UPDATE_RATE_INTENSITY = 8'h41;
  localparam bit [7:0] ADDR_SILENCER_UPDATE_RATE_PHASE = 8'h42;
  localparam bit [7:0] ADDR_SILENCER_COMPLETION_STEPS_INTENSITY = 8'h43;
  localparam bit [7:0] ADDR_SILENCER_COMPLETION_STEPS_PHASE = 8'h44;
  localparam bit [7:0] ADDR_STM_MEM_WR_SEGMENT = 8'h50;
  localparam bit [7:0] ADDR_STM_MEM_WR_PAGE = 8'h51;
  localparam bit [7:0] ADDR_STM_REQ_RD_SEGMENT = 8'h52;
  localparam bit [7:0] ADDR_STM_CYCLE_0 = 8'h54;
  localparam bit [7:0] ADDR_STM_FREQ_DIV_0_0 = 8'h55;
  localparam bit [7:0] ADDR_STM_FREQ_DIV_0_1 = 8'h56;
  localparam bit [7:0] ADDR_STM_CYCLE_1 = 8'h57;
  localparam bit [7:0] ADDR_STM_FREQ_DIV_1_0 = 8'h58;
  localparam bit [7:0] ADDR_STM_FREQ_DIV_1_1 = 8'h59;
  localparam bit [7:0] ADDR_STM_REP_0_0 = 8'h5A;
  localparam bit [7:0] ADDR_STM_REP_0_1 = 8'h5B;
  localparam bit [7:0] ADDR_STM_REP_1_0 = 8'h5C;
  localparam bit [7:0] ADDR_STM_REP_1_1 = 8'h5D;
  localparam bit [7:0] ADDR_STM_MODE_0 = 8'h5E;
  localparam bit [7:0] ADDR_STM_MODE_1 = 8'h5F;
  localparam bit [7:0] ADDR_STM_SOUND_SPEED_0_0 = 8'h60;
  localparam bit [7:0] ADDR_STM_SOUND_SPEED_0_1 = 8'h61;
  localparam bit [7:0] ADDR_STM_SOUND_SPEED_1_0 = 8'h62;
  localparam bit [7:0] ADDR_STM_SOUND_SPEED_1_1 = 8'h63;
  localparam bit [7:0] ADDR_PULSE_WIDTH_ENCODER_TABLE_WR_PAGE = 8'hE0;
  localparam bit [7:0] ADDR_PULSE_WIDTH_ENCODER_FULL_WIDTH_START = 8'hE1;
  localparam bit [7:0] ADDR_DEBUG_OUT_IDX = 8'hF0;

  localparam int CTL_FLAG_MOD_SET_BIT = 0;
  localparam int CTL_FLAG_STM_SET_BIT = 1;
  localparam int CTL_FLAG_SILENCER_SET_BIT = 2;
  localparam int CTL_FLAG_PULSE_WIDTH_ENCODER_SET_BIT = 3;
  localparam int CTL_FLAG_DEBUG_SET_BIT = 4;
  localparam int CTL_FLAG_SYNC_SET_BIT = 5;

  localparam int CTL_FLAG_FORCE_FAN_BIT = 13;

endpackage
