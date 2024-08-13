#ifndef PARAMS_CPU_H
#define PARAMS_CPU_H

#define NANOSECONDS (1)
#define MICROSECONDS (NANOSECONDS * 1000)
#define MILLISECONDS (MICROSECONDS * 1000)
#define SYS_TIME_TRANSITION_MARGIN (10 * MILLISECONDS)

#define TAG_CLEAR (0x01)
#define TAG_SYNC (0x02)
#define TAG_FIRM_INFO (0x03)
#define TAG_MODULATION (0x10)
#define TAG_MODULATION_CHANGE_SEGMENT (0x11)
#define TAG_SILENCER (0x20)
#define TAG_GAIN (0x30)
#define TAG_GAIN_CHANGE_SEGMENT (0x31)
#define TAG_GAIN_STM (0x41)
#define TAG_FOCI_STM (0x42)
#define TAG_GAIN_STM_CHANGE_SEGMENT (0x43)
#define TAG_FOCI_STM_CHANGE_SEGMENT (0x44)
#define TAG_FORCE_FAN (0x60)
#define TAG_READS_FPGA_STATE (0x61)
#define TAG_CONFIG_PULSE_WIDTH_ENCODER (0x71)
#define TAG_DEBUG (0xF0)
#define TAG_EMULATE_GPIO_IN (0xF1)
#define TAG_CPU_GPIO_OUT (0xF2)

#define TRANSITION_MODE_NONE (0xFE)
#define TRANSITION_MODE_IMMIDIATE (0xFF)

#define INFO_TYPE_CPU_VERSION_MAJOR (0x01)
#define INFO_TYPE_CPU_VERSION_MINOR (0x02)
#define INFO_TYPE_FPGA_VERSION_MAJOR (0x03)
#define INFO_TYPE_FPGA_VERSION_MINOR (0x04)
#define INFO_TYPE_FPGA_FUNCTIONS (0x05)
#define INFO_TYPE_CLEAR (0x06)

#define GAIN_FLAG_UPDATE (1 << 0)
#define GAIN_FLAG_SEGMENT (1 << 1)

#define MODULATION_FLAG_BEGIN (1 << 0)
#define MODULATION_FLAG_END (1 << 1)
#define MODULATION_FLAG_UPDATE (1 << 2)
#define MODULATION_FLAG_SEGMENT (1 << 3)

#define FOCUS_STM_FLAG_BEGIN (1 << 0)
#define FOCUS_STM_FLAG_END (1 << 1)
#define FOCUS_STM_FLAG_UPDATE (1 << 2)

#define GAIN_STM_FLAG_BEGIN (1 << 0)
#define GAIN_STM_FLAG_END (1 << 1)
#define GAIN_STM_FLAG_UPDATE (1 << 2)
#define GAIN_STM_FLAG_SEGMENT (1 << 3)

#define GAIN_STM_MODE_INTENSITY_PHASE_FULL (0)
#define GAIN_STM_MODE_PHASE_FULL (1)
#define GAIN_STM_MODE_PHASE_HALF (2)

#define SILENCER_FLAG_STRICT_MODE (1 << 2)

#define GPIO_IN_FLAG_0 (1 << 0)
#define GPIO_IN_FLAG_1 (1 << 1)
#define GPIO_IN_FLAG_2 (1 << 2)
#define GPIO_IN_FLAG_3 (1 << 3)

#define NO_ERR (0x00)
#define ERR_BIT (0x80)
#define ERR_NOT_SUPPORTED_TAG (ERR_BIT | 0x00)
#define ERR_INVALID_MSG_ID (ERR_BIT | 0x01)
#define ERR_INVALID_INFO_TYPE (ERR_BIT | 0x04)
#define ERR_INVALID_GAIN_STM_MODE (ERR_BIT | 0x05)
#define ERR_INVALID_SEGMENT_TRANSITION (ERR_BIT | 0x08)
#define ERR_MISS_TRANSITION_TIME (ERR_BIT | 0x0B)
#define ERR_INVALID_SILENCER_SETTING (ERR_BIT | 0x0E)
#define ERR_INVALID_TRANSITION_MODE (ERR_BIT | 0x0F)

#endif  // PARAMS_CPU_H
