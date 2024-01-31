#ifndef INC_PARAMS_H_
#define INC_PARAMS_H_

#define CPU_VERSION_MAJOR (0x8E) /* v5.1 */
#define CPU_VERSION_MINOR (0x01)

#define TRANS_NUM (249)

#define BRAM_SELECT_CONTROLLER (0x0)
#define BRAM_SELECT_MOD (0x1)
#define BRAM_SELECT_NORMAL (0x2)
#define BRAM_SELECT_STM (0x3)

#define BRAM_ADDR_CTL_FLAG (0x000)
#define BRAM_ADDR_FPGA_STATE (0x001)
#define BRAM_ADDR_EC_SYNC_TIME_0 (0x011)
#define BRAM_ADDR_EC_SYNC_TIME_1 (BRAM_ADDR_EC_SYNC_TIME_0 + 1)
#define BRAM_ADDR_EC_SYNC_TIME_2 (BRAM_ADDR_EC_SYNC_TIME_0 + 2)
#define BRAM_ADDR_EC_SYNC_TIME_3 (BRAM_ADDR_EC_SYNC_TIME_0 + 3)
#define BRAM_ADDR_MOD_MEM_PAGE (0x020)
#define BRAM_ADDR_MOD_CYCLE (0x021)
#define BRAM_ADDR_MOD_FREQ_DIV_0 (0x022)
#define BRAM_ADDR_MOD_FREQ_DIV_1 (0x023)
#define BRAM_ADDR_VERSION_NUM (0x030)
#define BRAM_ADDR_VERSION_NUM_MINOR (0x031)
#define BRAM_ADDR_SILENCER_UPDATE_RATE_INTENSITY (0x040)
#define BRAM_ADDR_SILENCER_UPDATE_RATE_PHASE (0x041)
#define BRAM_ADDR_SILENCER_CTL_FLAG (0x042)
#define BRAM_ADDR_SILENCER_COMPLETION_STEPS_INTENSITY (0x043)
#define BRAM_ADDR_SILENCER_COMPLETION_STEPS_PHASE (0x044)
#define BRAM_ADDR_STM_MEM_PAGE (0x050)
#define BRAM_ADDR_STM_CYCLE (0x051)
#define BRAM_ADDR_STM_FREQ_DIV_0 (0x052)
#define BRAM_ADDR_STM_FREQ_DIV_1 (0x053)
#define BRAM_ADDR_SOUND_SPEED_0 (0x054)
#define BRAM_ADDR_SOUND_SPEED_1 (0x055)
#define BRAM_ADDR_STM_START_IDX (0x056)
#define BRAM_ADDR_STM_FINISH_IDX (0x057)
#define BRAM_ADDR_DEBUG_OUT_IDX (0x0F0)
#define BRAM_ADDR_MOD_DELAY_BASE (0x200)

#define CTL_FLAG_OP_MODE_BIT (9)
#define CTL_FLAG_STM_GAIN_MODE_BIT (10)
#define CTL_FLAG_USE_STM_FINISH_IDX_BIT (11)
#define CTL_FLAG_USE_STM_START_IDX_BIT (12)
#define CTL_FLAG_FORCE_FAN_EX_BIT (13)
#define CTL_FLAG_SYNC_BIT (15)

#define CTL_FLAG_OP_MODE (1 << CTL_FLAG_OP_MODE_BIT)
#define CTL_FLAG_STM_GAIN_MODE (1 << CTL_FLAG_STM_GAIN_MODE_BIT)
#define CTL_FLAG_USE_STM_FINISH_IDX (1 << CTL_FLAG_USE_STM_FINISH_IDX_BIT)
#define CTL_FLAG_USE_STM_START_IDX (1 << CTL_FLAG_USE_STM_START_IDX_BIT)
#define CTL_FLAG_FORCE_FAN_EX (1 << CTL_FLAG_FORCE_FAN_EX_BIT)
#define CTL_FLAG_SYNC (1 << CTL_FLAG_SYNC_BIT)

#define READS_FPGA_STATE_ENABLED_BIT (7)
#define READS_FPGA_STATE_ENABLED (1 << READS_FPGA_STATE_ENABLED_BIT)

#define SILENCER_CTL_FLAG_FIXED_COMPLETION_STEPS_BIT (0)
#define SILENCER_CTL_FLAG_STRICT_MODE_BIT (8)
#define SILENCER_CTL_FLAG_FIXED_COMPLETION_STEPS \
  (1 << SILENCER_CTL_FLAG_FIXED_COMPLETION_STEPS_BIT)
#define SILENCER_CTL_FLAG_STRICT_MODE (1 << SILENCER_CTL_FLAG_STRICT_MODE_BIT)

#define TAG_CLEAR (0x01)
#define TAG_SYNC (0x02)
#define TAG_FIRM_INFO (0x03)
#define TAG_UPDATE_FLAGS (0x04)
#define TAG_MODULATION (0x10)
#define TAG_MODULATION_DELAY (0x11)
#define TAG_SILENCER (0x20)
#define TAG_GAIN (0x30)
#define TAG_FOCUS_STM (0x40)
#define TAG_GAIN_STM (0x50)
#define TAG_FORCE_FAN (0x60)
#define TAG_READS_FPGA_STATE (0x61)
#define TAG_DEBUG (0xF0)

#define INFO_TYPE_CPU_VERSION_MAJOR (0x01)
#define INFO_TYPE_CPU_VERSION_MINOR (0x02)
#define INFO_TYPE_FPGA_VERSION_MAJOR (0x03)
#define INFO_TYPE_FPGA_VERSION_MINOR (0x04)
#define INFO_TYPE_FPGA_FUNCTIONS (0x05)
#define INFO_TYPE_CLEAR (0x06)

#define MOD_BUF_PAGE_SIZE_WIDTH (15)
#define MOD_BUF_PAGE_SIZE (1 << MOD_BUF_PAGE_SIZE_WIDTH)
#define MOD_BUF_PAGE_SIZE_MASK (MOD_BUF_PAGE_SIZE - 1)
#define MODULATION_FLAG_BEGIN (1 << 0)
#define MODULATION_FLAG_END (1 << 1)

#define FOCUS_STM_FLAG_BEGIN (1 << 0)
#define FOCUS_STM_FLAG_END (1 << 1)
#define FOCUS_STM_FLAG_USE_START_IDX (1 << 2)
#define FOCUS_STM_FLAG_USE_FINISH_IDX (1 << 3)

#define GAIN_STM_FLAG_BEGIN (1 << 2)
#define GAIN_STM_FLAG_END (1 << 3)
#define GAIN_STM_FLAG_USE_START_IDX (1 << 4)
#define GAIN_STM_FLAG_USE_FINISH_IDX (1 << 5)

#define GAIN_STM_MODE_INTENSITY_PHASE_FULL (0)
#define GAIN_STM_MODE_PHASE_FULL (1)
#define GAIN_STM_MODE_PHASE_HALF (2)

#define ERR_NONE (0x00)
#define ERR_NOT_SUPPORTED_TAG (0x80)
#define ERR_INVALID_MSG_ID (0x81)
#define ERR_FREQ_DIV_TOO_SMALL (0x82)
#define ERR_COMPLETION_STEPS_TOO_LARGE (0x83)
#define ERR_INVALID_INFO_TYPE (0x84)
#define ERR_INVALID_GAIN_STM_MODE (0x85)

#endif  // INC_PARAMS_H_
