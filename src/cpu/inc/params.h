#ifndef PARAMS_H
#define PARAMS_H

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

#define GAIN_STM_FLAG_BEGIN (1 << 0)
#define GAIN_STM_FLAG_END (1 << 1)
#define GAIN_STM_FLAG_UPDATE (1 << 2)

#define GAIN_STM_MODE_INTENSITY_PHASE_FULL (0)
#define GAIN_STM_MODE_PHASE_FULL (1)
#define GAIN_STM_MODE_PHASE_HALF (2)

#define PULSE_WIDTH_ENCODER_FLAG_BEGIN (1 << 0)
#define PULSE_WIDTH_ENCODER_FLAG_END (1 << 1)

#define SILENCER_FLAG_MODE (1 << 0)
#define SILENCER_FLAG_STRICT_MODE (1 << 1)

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

// Following are the parameters of FPGA

#define NUM_TRANSDUCERS (249)
#define NUM_SEGMENT (2)
#define ULTRASOUND_FREQUENCY (40000.0)
#define GAIN_STM_SIZE (1024)
#define VERSION_NUM_MAJOR (0x91)
#define VERSION_NUM_MINOR (0x00)

#define CTL_FLAG_BIT_MOD_SET (0)
#define CTL_FLAG_MOD_SET (1 << CTL_FLAG_BIT_MOD_SET)
#define CTL_FLAG_BIT_STM_SET (1)
#define CTL_FLAG_STM_SET (1 << CTL_FLAG_BIT_STM_SET)
#define CTL_FLAG_BIT_SILENCER_SET (2)
#define CTL_FLAG_SILENCER_SET (1 << CTL_FLAG_BIT_SILENCER_SET)
#define CTL_FLAG_BIT_PULSE_WIDTH_ENCODER_SET (3)
#define CTL_FLAG_PULSE_WIDTH_ENCODER_SET (1 << CTL_FLAG_BIT_PULSE_WIDTH_ENCODER_SET)
#define CTL_FLAG_BIT_DEBUG_SET (4)
#define CTL_FLAG_DEBUG_SET (1 << CTL_FLAG_BIT_DEBUG_SET)
#define CTL_FLAG_BIT_SYNC_SET (5)
#define CTL_FLAG_SYNC_SET (1 << CTL_FLAG_BIT_SYNC_SET)
#define CTL_FLAG_BIT_FORCE_FAN (13)
#define CTL_FLAG_FORCE_FAN (1 << CTL_FLAG_BIT_FORCE_FAN)

#define FPGA_STATE_BIT_READS_FPGA_STATE_ENABLED (7)
#define FPGA_STATE_READS_FPGA_STATE_ENABLED (1 << FPGA_STATE_BIT_READS_FPGA_STATE_ENABLED)

#define BRAM_SELECT_CONTROLLER (0x0)
#define BRAM_SELECT_MOD (0x1)
#define BRAM_SELECT_DUTY_TABLE (0x2)
#define BRAM_SELECT_STM (0x3)

#define BRAM_CNT_SELECT_MAIN (0x00)
#define BRAM_CNT_SELECT_FILTER (0x01)

#define TRANSITION_MODE_SYNC_IDX (0x00)
#define TRANSITION_MODE_SYS_TIME (0x01)
#define TRANSITION_MODE_GPIO (0x02)
#define TRANSITION_MODE_EXT (0xF0)

#define STM_MODE_FOCUS (0x0)
#define STM_MODE_GAIN (0x1)

#define SILENCER_MODE_FIXED_COMPLETION_STEPS (0x0)
#define SILENCER_MODE_FIXED_UPDATE_RATE (0x1)

#define DBG_NONE (0x00)
#define DBG_BASE_SIG (0x01)
#define DBG_THERMO (0x02)
#define DBG_FORCE_FAN (0x03)
#define DBG_SYNC (0x10)
#define DBG_MOD_SEGMENT (0x20)
#define DBG_MOD_IDX (0x21)
#define DBG_STM_SEGMENT (0x50)
#define DBG_STM_IDX (0x51)
#define DBG_IS_STM_MODE (0x52)
#define DBG_PWM_OUT (0xE0)
#define DBG_DIRECT (0xF0)

#define ADDR_CTL_FLAG (0x00)
#define ADDR_FPGA_STATE (0x01)
#define ADDR_VERSION_NUM_MAJOR (0x02)
#define ADDR_VERSION_NUM_MINOR (0x03)
#define ADDR_ECAT_SYNC_TIME_0 (0x10)
#define ADDR_ECAT_SYNC_TIME_1 (0x11)
#define ADDR_ECAT_SYNC_TIME_2 (0x12)
#define ADDR_ECAT_SYNC_TIME_3 (0x13)
#define ADDR_MOD_MEM_WR_SEGMENT (0x20)
#define ADDR_MOD_REQ_RD_SEGMENT (0x21)
#define ADDR_MOD_CYCLE0 (0x22)
#define ADDR_MOD_FREQ_DIV0_0 (0x23)
#define ADDR_MOD_FREQ_DIV0_1 (0x24)
#define ADDR_MOD_CYCLE1 (0x25)
#define ADDR_MOD_FREQ_DIV1_0 (0x26)
#define ADDR_MOD_FREQ_DIV1_1 (0x27)
#define ADDR_MOD_REP0_0 (0x28)
#define ADDR_MOD_REP0_1 (0x29)
#define ADDR_MOD_REP1_0 (0x2A)
#define ADDR_MOD_REP1_1 (0x2B)
#define ADDR_MOD_TRANSITION_MODE (0x2C)
#define ADDR_MOD_TRANSITION_VALUE_0 (0x2D)
#define ADDR_MOD_TRANSITION_VALUE_1 (0x2E)
#define ADDR_MOD_TRANSITION_VALUE_2 (0x2F)
#define ADDR_MOD_TRANSITION_VALUE_3 (0x30)
#define ADDR_SILENCER_MODE (0x40)
#define ADDR_SILENCER_UPDATE_RATE_INTENSITY (0x41)
#define ADDR_SILENCER_UPDATE_RATE_PHASE (0x42)
#define ADDR_SILENCER_COMPLETION_STEPS_INTENSITY (0x43)
#define ADDR_SILENCER_COMPLETION_STEPS_PHASE (0x44)
#define ADDR_STM_MEM_WR_SEGMENT (0x50)
#define ADDR_STM_MEM_WR_PAGE (0x51)
#define ADDR_STM_REQ_RD_SEGMENT (0x52)
#define ADDR_STM_CYCLE0 (0x54)
#define ADDR_STM_FREQ_DIV0_0 (0x55)
#define ADDR_STM_FREQ_DIV0_1 (0x56)
#define ADDR_STM_CYCLE1 (0x57)
#define ADDR_STM_FREQ_DIV1_0 (0x58)
#define ADDR_STM_FREQ_DIV1_1 (0x59)
#define ADDR_STM_REP0_0 (0x5A)
#define ADDR_STM_REP0_1 (0x5B)
#define ADDR_STM_REP1_0 (0x5C)
#define ADDR_STM_REP1_1 (0x5D)
#define ADDR_STM_MODE0 (0x5E)
#define ADDR_STM_MODE1 (0x5F)
#define ADDR_STM_SOUND_SPEED0_0 (0x60)
#define ADDR_STM_SOUND_SPEED0_1 (0x61)
#define ADDR_STM_SOUND_SPEED1_0 (0x62)
#define ADDR_STM_SOUND_SPEED1_1 (0x63)
#define ADDR_STM_TRANSITION_MODE (0x64)
#define ADDR_STM_TRANSITION_VALUE_0 (0x65)
#define ADDR_STM_TRANSITION_VALUE_1 (0x66)
#define ADDR_STM_TRANSITION_VALUE_2 (0x67)
#define ADDR_STM_TRANSITION_VALUE_3 (0x68)
#define ADDR_PULSE_WIDTH_ENCODER_TABLE_WR_PAGE (0xE0)
#define ADDR_PULSE_WIDTH_ENCODER_FULL_WIDTH_START (0xE1)
#define ADDR_DEBUG_TYPE0 (0xF0)
#define ADDR_DEBUG_VALUE0 (0xF1)
#define ADDR_DEBUG_TYPE1 (0xF2)
#define ADDR_DEBUG_VALUE1 (0xF3)
#define ADDR_DEBUG_TYPE2 (0xF4)
#define ADDR_DEBUG_VALUE2 (0xF5)
#define ADDR_DEBUG_TYPE3 (0xF6)
#define ADDR_DEBUG_VALUE3 (0xF7)

#endif  // INC_PARAMS_H_
