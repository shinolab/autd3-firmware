#ifndef INC_PARAMS_H_
#define INC_PARAMS_H_

#define CPU_VERSION_MAJOR (0x8F) /* v6.0 */
#define CPU_VERSION_MINOR (0x01)

#define TRANS_NUM (249)

#define BRAM_SELECT_CONTROLLER (0x0)
#define BRAM_SELECT_MOD (0x1)
#define BRAM_SELECT_DUTY_TABLE (0x2)
#define BRAM_SELECT_STM (0x3)

#define BRAM_CNT_SEL_MAIN (0x00)
#define BRAM_CNT_SEL_FILTER (0x01)

#define BRAM_ADDR_CTL_FLAG (0x00)
#define BRAM_ADDR_FPGA_STATE (0x01)
#define BRAM_ADDR_ECAT_SYNC_TIME_0 (0x11)
#define BRAM_ADDR_ECAT_SYNC_TIME_1 (BRAM_ADDR_ECAT_SYNC_TIME_0 + 1)
#define BRAM_ADDR_ECAT_SYNC_TIME_2 (BRAM_ADDR_ECAT_SYNC_TIME_0 + 2)
#define BRAM_ADDR_ECAT_SYNC_TIME_3 (BRAM_ADDR_ECAT_SYNC_TIME_0 + 3)
#define BRAM_ADDR_MOD_MEM_WR_SEGMENT (0x20)
#define BRAM_ADDR_MOD_REQ_RD_SEGMENT (0x21)
#define BRAM_ADDR_MOD_CYCLE_0 (0x22)
#define BRAM_ADDR_MOD_FREQ_DIV_0_0 (0x23)
#define BRAM_ADDR_MOD_FREQ_DIV_0_1 (0x24)
#define BRAM_ADDR_MOD_CYCLE_1 (0x25)
#define BRAM_ADDR_MOD_FREQ_DIV_1_0 (0x26)
#define BRAM_ADDR_MOD_FREQ_DIV_1_1 (0x27)
#define BRAM_ADDR_MOD_REP_0_0 (0x28)
#define BRAM_ADDR_MOD_REP_0_1 (0x29)
#define BRAM_ADDR_MOD_REP_1_0 (0x2A)
#define BRAM_ADDR_MOD_REP_1_1 (0x2B)
#define BRAM_ADDR_VERSION_NUM_MAJOR (0x30)
#define BRAM_ADDR_VERSION_NUM_MINOR (0x31)
#define BRAM_ADDR_SILENCER_MODE (0x40)
#define BRAM_ADDR_SILENCER_UPDATE_RATE_INTENSITY (0x41)
#define BRAM_ADDR_SILENCER_UPDATE_RATE_PHASE (0x42)
#define BRAM_ADDR_SILENCER_COMPLETION_STEPS_INTENSITY (0x43)
#define BRAM_ADDR_SILENCER_COMPLETION_STEPS_PHASE (0x44)
#define BRAM_ADDR_STM_MEM_WR_SEGMENT (0x50)
#define BRAM_ADDR_STM_MEM_WR_PAGE (0x51)
#define BRAM_ADDR_STM_REQ_RD_SEGMENT (0x52)
#define BRAM_ADDR_STM_CYCLE_0 (0x54)
#define BRAM_ADDR_STM_FREQ_DIV_0_0 (0x55)
#define BRAM_ADDR_STM_FREQ_DIV_0_1 (0x56)
#define BRAM_ADDR_STM_CYCLE_1 (0x57)
#define BRAM_ADDR_STM_FREQ_DIV_1_0 (0x58)
#define BRAM_ADDR_STM_FREQ_DIV_1_1 (0x59)
#define BRAM_ADDR_STM_REP_0_0 (0x5A)
#define BRAM_ADDR_STM_REP_0_1 (0x5B)
#define BRAM_ADDR_STM_REP_1_0 (0x5C)
#define BRAM_ADDR_STM_REP_1_1 (0x5D)
#define BRAM_ADDR_STM_MODE_0 (0x5E)
#define BRAM_ADDR_STM_MODE_1 (0x5F)
#define BRAM_ADDR_STM_SOUND_SPEED_0_0 (0x60)
#define BRAM_ADDR_STM_SOUND_SPEED_0_1 (0x61)
#define BRAM_ADDR_STM_SOUND_SPEED_1_0 (0x62)
#define BRAM_ADDR_STM_SOUND_SPEED_1_1 (0x63)
#define BRAM_ADDR_PULSE_WIDTH_ENCODER_TABLE_WR_PAGE (0xE0)
#define BRAM_ADDR_PULSE_WIDTH_ENCODER_FULL_WIDTH_START (0xE1)
#define BRAM_ADDR_DEBUG_OUT_IDX (0xF0)

#define CTL_FLAG_MOD_SET_BIT (0)
#define CTL_FLAG_STM_SET_BIT (1)
#define CTL_FLAG_SILENCER_SET_BIT (2)
#define CTL_FLAG_PULSE_WIDTH_ENCODER_SET_BIT (3)
#define CTL_FLAG_DEBUG_SET_BIT (4)
#define CTL_FLAG_SYNC_SET_BIT (5)
#define CTL_FLAG_FORCE_FAN_BIT (13)

#define CTL_FLAG_MOD_SET (1 << CTL_FLAG_MOD_SET_BIT)
#define CTL_FLAG_STM_SET (1 << CTL_FLAG_STM_SET_BIT)
#define CTL_FLAG_SILENCER_SET (1 << CTL_FLAG_SILENCER_SET_BIT)
#define CTL_FLAG_PULSE_WIDTH_ENCODER_SET (1 << CTL_FLAG_PULSE_WIDTH_ENCODER_SET_BIT)
#define CTL_FLAG_DEBUG_SET (1 << CTL_FLAG_DEBUG_SET_BIT)
#define CTL_FLAG_SYNC_SET (1 << CTL_FLAG_SYNC_SET_BIT)
#define CTL_FLAG_FORCE_FAN (1 << CTL_FLAG_FORCE_FAN_BIT)

#define READS_FPGA_STATE_ENABLED_BIT (7)
#define READS_FPGA_STATE_ENABLED (1 << READS_FPGA_STATE_ENABLED_BIT)

#define STM_MODE_FOCUS (0)
#define STM_MODE_GAIN (1)

#define SILNCER_MODE_FIXED_COMPLETION_STEPS (0)
#define SILNCER_MODE_FIXED_UPDATE_RATE (1)
#define SILNCER_FLAG_MODE (1 << 0)
#define SILNCER_FLAG_STRICT_MODE (1 << 1)

#define TAG_CLEAR (0x01)
#define TAG_SYNC (0x02)
#define TAG_FIRM_INFO (0x03)
#define TAG_MODULATION (0x10)
#define TAG_MODULATION_CHANGE_SEGMENT (0x11)
#define TAG_SILENCER (0x20)
#define TAG_GAIN (0x30)
#define TAG_GAIN_CHANGE_SEGMENT (0x31)
#define TAG_FOCUS_STM (0x40)
#define TAG_GAIN_STM (0x41)
#define TAG_FOCUS_STM_CHANGE_SEGMENT (0x42)
#define TAG_GAIN_STM_CHANGE_SEGMENT (0x43)
#define TAG_FORCE_FAN (0x60)
#define TAG_READS_FPGA_STATE (0x61)
#define TAG_CONFIG_PULSE_WIDTH_ENCODER (0x70)
#define TAG_PHASE_FILTER (0x80)
#define TAG_DEBUG (0xF0)

#define INFO_TYPE_CPU_VERSION_MAJOR (0x01)
#define INFO_TYPE_CPU_VERSION_MINOR (0x02)
#define INFO_TYPE_FPGA_VERSION_MAJOR (0x03)
#define INFO_TYPE_FPGA_VERSION_MINOR (0x04)
#define INFO_TYPE_FPGA_FUNCTIONS (0x05)
#define INFO_TYPE_CLEAR (0x06)

#define GAIN_FLAG_UPDATE (1 << 0)

#define MODULATION_FLAG_BEGIN (1 << 0)
#define MODULATION_FLAG_END (1 << 1)
#define MODULATION_FLAG_UPDATE (1 << 2)

#define FOCUS_STM_FLAG_BEGIN (1 << 0)
#define FOCUS_STM_FLAG_END (1 << 1)
#define FOCUS_STM_FLAG_UPDATE (1 << 2)

#define GAIN_STM_FLAG_BEGIN (1 << 2)
#define GAIN_STM_FLAG_END (1 << 3)
#define GAIN_STM_FLAG_UPDATE (1 << 4)

#define GAIN_STM_MODE_INTENSITY_PHASE_FULL (0)
#define GAIN_STM_MODE_PHASE_FULL (1)
#define GAIN_STM_MODE_PHASE_HALF (2)

#define PULSE_WIDTH_ENCODER_FLAG_BEGIN (1 << 0)
#define PULSE_WIDTH_ENCODER_FLAG_END (1 << 1)

#define NO_ERR (0x00)
#define ERR_BIT (0x80)
#define ERR_NOT_SUPPORTED_TAG (ERR_BIT | 0x00)
#define ERR_INVALID_MSG_ID (ERR_BIT | 0x01)
#define ERR_FREQ_DIV_TOO_SMALL (ERR_BIT | 0x02)
#define ERR_COMPLETION_STEPS_TOO_LARGE (ERR_BIT | 0x03)
#define ERR_INVALID_INFO_TYPE (ERR_BIT | 0x04)
#define ERR_INVALID_GAIN_STM_MODE (ERR_BIT | 0x05)
#define ERR_INVALID_SEGMENT (ERR_BIT | 0x06)
#define ERR_INVALID_MODE (ERR_BIT | 0x07)
#define ERR_INVALID_SEGMENT_TRANSITION (ERR_BIT | 0x08)
#define ERR_INVALID_PWE_DATA_SIZE (ERR_BIT | 0x09)
#define ERR_PWE_INCOMPLETE_DATA (ERR_BIT | 0x0A)

#endif  // INC_PARAMS_H_
