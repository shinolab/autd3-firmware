package params;

  const int NUM_TRANSDUCERS = 249;

  const bit [7:0] VERSION_NUM = 8'h8F;
  const bit [7:0] VERSION_NUM_MINOR = 8'h00;

  const bit [1:0] BRAM_SELECT_CONTROLLER = 2'h0;
  const bit [1:0] BRAM_SELECT_MOD = 2'h1;
  const bit [1:0] BRAM_SELECT_NORMAL = 2'h2;
  const bit [1:0] BRAM_SELECT_STM = 2'h3;

  const bit [4:0] BRAM_SELECT_CNT_CNT = 5'h0;

  // const bit [2:0] BRAM_SELECT_CONTROLLER_MAIN = 3'b000;
  // const bit [2:0] BRAM_SELECT_CONTROLLER_DELAY = 3'b010;

  // const bit [13:0] ADDR_CTL_FLAG = 14'h000;
  // const bit [13:0] ADDR_FPGA_STATE = 14'h001;
  // const bit [13:0] ADDR_EC_SYNC_TIME_0 = 14'h011;
  // const bit [13:0] ADDR_EC_SYNC_TIME_1 = ADDR_EC_SYNC_TIME_0 + 1;
  // const bit [13:0] ADDR_EC_SYNC_TIME_2 = ADDR_EC_SYNC_TIME_0 + 2;
  // const bit [13:0] ADDR_EC_SYNC_TIME_3 = ADDR_EC_SYNC_TIME_0 + 3;
  const bit [13:0] ADDR_MOD_MEM_WR_SEGMENT = 14'h020;
  // const bit [13:0] ADDR_MOD_CYCLE = 14'h021;
  // const bit [13:0] ADDR_MOD_FREQ_DIV_0 = 14'h022;
  // const bit [13:0] ADDR_MOD_FREQ_DIV_1 = 14'h023;
  // const bit [13:0] ADDR_VERSION_NUM_MAJOR = 14'h030;
  // const bit [13:0] ADDR_VERSION_NUM_MINOR = 14'h031;
  // const bit [13:0] ADDR_SILENCER_UPDATE_RATE_INTENSITY = 14'h040;
  // const bit [13:0] ADDR_SILENCER_UPDATE_RATE_PHASE = 14'h041;
  // const bit [13:0] ADDR_SILENCER_CTL_FLAG = 14'h042;
  // const bit [13:0] ADDR_SILENCER_COMPLETION_STEPS_INTENSITY = 14'h043;
  // const bit [13:0] ADDR_SILENCER_COMPLETION_STEPS_PHASE = 14'h044;
  const bit [13:0] ADDR_STM_MEM_WR_SEGMENT = 14'h050;
  // const bit [13:0] ADDR_STM_CYCLE = 14'h051;
  // const bit [13:0] ADDR_STM_FREQ_DIV_0 = 14'h052;
  // const bit [13:0] ADDR_STM_FREQ_DIV_1 = 14'h053;
  // const bit [13:0] ADDR_SOUND_SPEED_0 = 14'h054;
  // const bit [13:0] ADDR_SOUND_SPEED_1 = 14'h055;
  // const bit [13:0] ADDR_STM_START_IDX = 14'h056;
  // const bit [13:0] ADDR_STM_FINISH_IDX = 14'h057;
  const bit [13:0] ADDR_STM_MEM_WR_PAGE = 14'h058;
  const bit [13:0] ADDR_DUTY_TABLE_WR_PAGE = 14'h060;
  // const bit [13:0] ADDR_DEBUG_OUT_IDX = 14'h0F0;

  // const int CTL_FLAG_FORCE_FAN_BIT = 0;
  // const int CTL_FLAG_OP_MODE_BIT = 9;
  // const int CTL_FLAG_STM_GAIN_MODE_BIT = 10;
  // const int CTL_FLAG_USE_STM_FINISH_IDX_BIT = 11;
  // const int CTL_FLAG_USE_STM_START_IDX_BIT = 12;
  // const int CTL_FLAG_FORCE_FAN_EX_BIT = 13;
  // const int CTL_FLAG_SYNC_BIT = 15;

  // const int SILENCER_CTL_FLAG_FIXED_COMPLETION_STEPS = 0;

endpackage
