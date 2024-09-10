package params;

  localparam int NumTransducers = 249;
  localparam int NumSegment = 2;

  localparam int GainSTMSize = 1024;
  localparam int STMWrAddrWidth = $clog2(GainSTMSize * 256);
  localparam int STMRdAddrWidth = $clog2(GainSTMSize * 8);
  localparam int NumFociMax = 8;

  localparam bit [7:0] VersionNumMajor = 8'hA2;
  localparam bit [7:0] VersionNumMinor = 8'h00;

  typedef enum int {
    CTL_FLAG_BIT_MOD_SET = 0,
    CTL_FLAG_BIT_STM_SET = 1,
    CTL_FLAG_BIT_SILENCER_SET = 2,
    //
    CTL_FLAG_BIT_DEBUG_SET = 4,
    CTL_FLAG_BIT_SYNC_SET = 5,
    CTL_FLAG_BIT_GPIO_IN_0 = 8,
    CTL_FLAG_BIT_GPIO_IN_1 = 9,
    CTL_FLAG_BIT_GPIO_IN_2 = 10,
    CTL_FLAG_BIT_GPIO_IN_3 = 11,
    CTL_FLAG_BIT_FORCE_FAN = 13
  } ctl_flag_bit_t;

  typedef enum int {
    //
    FPGA_STATE_BIT_READS_FPGA_STATE_ENABLED = 7
  } fpga_state_bit_t;

  typedef enum logic [1:0] {
    BRAM_SELECT_CONTROLLER = 2'h0,
    BRAM_SELECT_MOD = 2'h1,
    BRAM_SELECT_PWE_TABLE = 2'h2,
    BRAM_SELECT_STM = 2'h3
  } bram_select_t;

  typedef enum logic [5:0] {BRAM_CNT_SELECT_MAIN = 6'h00} bram_cnt_select_t;

  typedef enum logic [7:0] {
    TRANSITION_MODE_SYNC_IDX = 8'h00,
    TRANSITION_MODE_SYS_TIME = 8'h01,
    TRANSITION_MODE_GPIO = 8'h02,
    TRANSITION_MODE_EXT = 8'hF0
  } transition_mode_t;

  typedef enum logic {
    STM_MODE_FOCUS = 1'b0,
    STM_MODE_GAIN  = 1'b1
  } stm_mode_t;

  typedef enum int {
    SILENCER_FLAG_BIT_FIXED_UPDATE_RATE_MODE = 0,
    SILENCER_FLAG_BIT_PULSE_WIDTH = 1
  } silencer_mode_bit_t;

  typedef enum logic [7:0] {
    DBG_NONE = 8'h00,
    DBG_BASE_SIG = 8'h01,
    DBG_THERMO = 8'h02,
    DBG_FORCE_FAN = 8'h03,
    DBG_SYNC = 8'h10,
    DBG_MOD_SEGMENT = 8'h20,
    DBG_MOD_IDX = 8'h21,
    DBG_STM_SEGMENT = 8'h50,
    DBG_STM_IDX = 8'h51,
    DBG_IS_STM_MODE = 8'h52,
    DBG_SYS_TIME_EQ = 8'h60,
    DBG_PWM_OUT = 8'hE0,
    DBG_DIRECT = 8'hF0
  } debug_type_t;

  typedef enum logic [7:0] {
    ADDR_CTL_FLAG          = 8'h00,
    ADDR_FPGA_STATE        = 8'h01,
    ADDR_VERSION_NUM_MAJOR = 8'h02,
    ADDR_VERSION_NUM_MINOR = 8'h03,

    ADDR_ECAT_SYNC_TIME_0 = 8'h10,
    ADDR_ECAT_SYNC_TIME_1 = 8'h11,
    ADDR_ECAT_SYNC_TIME_2 = 8'h12,
    ADDR_ECAT_SYNC_TIME_3 = 8'h13,

    ADDR_MOD_MEM_WR_SEGMENT     = 8'h20,
    ADDR_MOD_REQ_RD_SEGMENT     = 8'h21,
    ADDR_MOD_CYCLE0             = 8'h22,
    ADDR_MOD_FREQ_DIV0          = 8'h23,
    ADDR_MOD_REP0               = 8'h24,
    ADDR_MOD_CYCLE1             = 8'h25,
    ADDR_MOD_FREQ_DIV1          = 8'h26,
    ADDR_MOD_REP1               = 8'h27,
    ADDR_MOD_TRANSITION_MODE    = 8'h28,
    ADDR_MOD_TRANSITION_VALUE_0 = 8'h29,
    ADDR_MOD_TRANSITION_VALUE_1 = 8'h2A,
    ADDR_MOD_TRANSITION_VALUE_2 = 8'h2B,
    ADDR_MOD_TRANSITION_VALUE_3 = 8'h2C,

    ADDR_SILENCER_FLAG                       = 8'h40,
    ADDR_SILENCER_UPDATE_RATE_INTENSITY      = 8'h41,
    ADDR_SILENCER_UPDATE_RATE_PHASE          = 8'h42,
    ADDR_SILENCER_COMPLETION_STEPS_INTENSITY = 8'h43,
    ADDR_SILENCER_COMPLETION_STEPS_PHASE     = 8'h44,

    ADDR_STM_MEM_WR_SEGMENT     = 8'h50,
    ADDR_STM_MEM_WR_PAGE        = 8'h51,
    ADDR_STM_REQ_RD_SEGMENT     = 8'h52,
    ADDR_STM_CYCLE0             = 8'h53,
    ADDR_STM_FREQ_DIV0          = 8'h54,
    ADDR_STM_REP0               = 8'h55,
    ADDR_STM_MODE0              = 8'h56,
    ADDR_STM_SOUND_SPEED0       = 8'h57,
    ADDR_STM_NUM_FOCI0          = 8'h58,
    ADDR_STM_CYCLE1             = 8'h59,
    ADDR_STM_FREQ_DIV1          = 8'h5A,
    ADDR_STM_REP1               = 8'h5B,
    ADDR_STM_MODE1              = 8'h5C,
    ADDR_STM_SOUND_SPEED1       = 8'h5D,
    ADDR_STM_NUM_FOCI1          = 8'h5E,
    ADDR_STM_TRANSITION_MODE    = 8'h5F,
    ADDR_STM_TRANSITION_VALUE_0 = 8'h60,
    ADDR_STM_TRANSITION_VALUE_1 = 8'h61,
    ADDR_STM_TRANSITION_VALUE_2 = 8'h62,
    ADDR_STM_TRANSITION_VALUE_3 = 8'h63,

    ADDR_DEBUG_TYPE0    = 8'hF0,
    ADDR_DEBUG_VALUE0_0 = 8'hF1,
    ADDR_DEBUG_VALUE0_1 = 8'hF2,
    ADDR_DEBUG_VALUE0_2 = 8'hF3,
    ADDR_DEBUG_TYPE1    = 8'hF4,
    ADDR_DEBUG_VALUE1_0 = 8'hF5,
    ADDR_DEBUG_VALUE1_1 = 8'hF6,
    ADDR_DEBUG_VALUE1_2 = 8'hF7,
    ADDR_DEBUG_TYPE2    = 8'hF8,
    ADDR_DEBUG_VALUE2_0 = 8'hF9,
    ADDR_DEBUG_VALUE2_1 = 8'hFA,
    ADDR_DEBUG_VALUE2_2 = 8'hFB,
    ADDR_DEBUG_TYPE3    = 8'hFC,
    ADDR_DEBUG_VALUE3_0 = 8'hFD,
    ADDR_DEBUG_VALUE3_1 = 8'hFE,
    ADDR_DEBUG_VALUE3_2 = 8'hFF
  } bram_addr_t;

endpackage
