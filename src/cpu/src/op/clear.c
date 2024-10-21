#ifdef __cplusplus
extern "C" {
#endif

#include <assert.h>
#include <stddef.h>

#include "app.h"
#include "iodefine.h"
#include "mod.h"
#include "params.h"
#include "stm.h"

static const unsigned char asin_table[] = {
    0x00, 0x00, 0x01, 0x01, 0x01, 0x02, 0x02, 0x02, 0x03, 0x03, 0x03, 0x04, 0x04, 0x04, 0x04, 0x05, 0x05, 0x05, 0x06, 0x06, 0x06, 0x07, 0x07, 0x07,
    0x08, 0x08, 0x08, 0x09, 0x09, 0x09, 0x0a, 0x0a, 0x0a, 0x0b, 0x0b, 0x0b, 0x0c, 0x0c, 0x0c, 0x0d, 0x0d, 0x0d, 0x0d, 0x0e, 0x0e, 0x0e, 0x0f, 0x0f,
    0x0f, 0x10, 0x10, 0x10, 0x11, 0x11, 0x11, 0x12, 0x12, 0x12, 0x13, 0x13, 0x13, 0x14, 0x14, 0x14, 0x15, 0x15, 0x15, 0x16, 0x16, 0x16, 0x17, 0x17,
    0x17, 0x18, 0x18, 0x18, 0x19, 0x19, 0x19, 0x1a, 0x1a, 0x1a, 0x1b, 0x1b, 0x1b, 0x1c, 0x1c, 0x1c, 0x1d, 0x1d, 0x1d, 0x1e, 0x1e, 0x1e, 0x1f, 0x1f,
    0x1f, 0x20, 0x20, 0x20, 0x21, 0x21, 0x22, 0x22, 0x22, 0x23, 0x23, 0x23, 0x24, 0x24, 0x24, 0x25, 0x25, 0x25, 0x26, 0x26, 0x26, 0x27, 0x27, 0x28,
    0x28, 0x28, 0x29, 0x29, 0x29, 0x2a, 0x2a, 0x2a, 0x2b, 0x2b, 0x2c, 0x2c, 0x2c, 0x2d, 0x2d, 0x2d, 0x2e, 0x2e, 0x2f, 0x2f, 0x2f, 0x30, 0x30, 0x31,
    0x31, 0x31, 0x32, 0x32, 0x32, 0x33, 0x33, 0x34, 0x34, 0x34, 0x35, 0x35, 0x36, 0x36, 0x36, 0x37, 0x37, 0x38, 0x38, 0x39, 0x39, 0x39, 0x3a, 0x3a,
    0x3b, 0x3b, 0x3b, 0x3c, 0x3c, 0x3d, 0x3d, 0x3e, 0x3e, 0x3f, 0x3f, 0x3f, 0x40, 0x40, 0x41, 0x41, 0x42, 0x42, 0x43, 0x43, 0x44, 0x44, 0x45, 0x45,
    0x45, 0x46, 0x46, 0x47, 0x47, 0x48, 0x48, 0x49, 0x49, 0x4a, 0x4b, 0x4b, 0x4c, 0x4c, 0x4d, 0x4d, 0x4e, 0x4e, 0x4f, 0x4f, 0x50, 0x51, 0x51, 0x52,
    0x52, 0x53, 0x54, 0x54, 0x55, 0x55, 0x56, 0x57, 0x57, 0x58, 0x59, 0x59, 0x5a, 0x5b, 0x5c, 0x5c, 0x5d, 0x5e, 0x5f, 0x60, 0x60, 0x61, 0x62, 0x63,
    0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6c, 0x6d, 0x6e, 0x70, 0x72, 0x73, 0x76, 0x79, 0x80};

extern volatile bool_t _read_fpga_state;
extern volatile uint16_t _fpga_flags_internal;

extern volatile uint8_t _mod_segment;
extern volatile uint16_t _mod_cycle;
extern volatile uint16_t _mod_freq_div[2];
extern volatile uint16_t _mod_rep[2];

extern volatile uint8_t _stm_segment;
extern volatile uint8_t _stm_mode[2];
extern volatile uint16_t _stm_cycle[2];
extern volatile uint16_t _stm_rep[2];
extern volatile uint16_t _stm_freq_div[2];

extern volatile bool_t _silencer_strict_mode;
extern volatile uint16_t _min_freq_div_intensity;
extern volatile uint16_t _min_freq_div_phase;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t _pad;
} Clear;

uint8_t clear(void) {
  static_assert(sizeof(Clear) == 2, "Clear is not valid.");
  static_assert(offsetof(Clear, tag) == 0, "Clear is not valid.");

  PORTA.PODR.BYTE = 0x00;

  _read_fpga_state = false;

  _fpga_flags_internal = 0;

  bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_UPDATE_RATE_INTENSITY, 256);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_UPDATE_RATE_PHASE, 256);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_FLAG, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_COMPLETION_STEPS_INTENSITY, 10);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_COMPLETION_STEPS_PHASE, 40);
  _silencer_strict_mode = true;
  _min_freq_div_intensity = 10;
  _min_freq_div_phase = 40;

  _mod_cycle = 2;
  _mod_freq_div[0] = 0xFFFF;
  _mod_freq_div[1] = 0xFFFF;
  _mod_rep[0] = 0xFFFF;
  _mod_rep[1] = 0xFFFF;
  _mod_segment = 0;
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_TRANSITION_MODE, TRANSITION_MODE_SYNC_IDX);
  bram_set(BRAM_SELECT_CONTROLLER, ADDR_MOD_TRANSITION_VALUE_0, 0, 4);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_REQ_RD_SEGMENT, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_CYCLE0, _mod_cycle - 1);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_FREQ_DIV0, _mod_freq_div[0]);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_CYCLE1, _mod_cycle - 1);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_FREQ_DIV1, _mod_freq_div[1]);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_REP0, 0xFFFF);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_REP1, 0xFFFF);
  change_mod_wr_segment(0);
  bram_write(BRAM_SELECT_MOD, 0, 0xFFFF);
  change_mod_wr_segment(1);
  bram_write(BRAM_SELECT_MOD, 0, 0xFFFF);

  _stm_mode[0] = STM_MODE_GAIN;
  _stm_mode[1] = STM_MODE_GAIN;
  _stm_cycle[0] = 1;
  _stm_cycle[1] = 1;
  _stm_freq_div[0] = 0xFFFF;
  _stm_freq_div[1] = 0xFFFF;
  _stm_rep[0] = 0xFFFF;
  _stm_rep[1] = 0xFFFF;
  _stm_segment = 0;
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_TRANSITION_MODE, TRANSITION_MODE_SYNC_IDX);
  bram_set(BRAM_SELECT_CONTROLLER, ADDR_STM_TRANSITION_VALUE_0, 0, 4);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_MODE0, STM_MODE_GAIN);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_MODE1, STM_MODE_GAIN);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_REQ_RD_SEGMENT, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_CYCLE0, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_FREQ_DIV0, 0xFFFF);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_CYCLE1, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_FREQ_DIV1, 0xFFFF);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_REP0, 0xFFFF);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_REP1, 0xFFFF);
  change_stm_wr_segment(0);
  change_stm_wr_page(0);
  bram_set(BRAM_SELECT_STM, 0, 0x0000, NUM_TRANSDUCERS << 1);
  change_stm_wr_segment(1);
  change_stm_wr_page(0);
  bram_set(BRAM_SELECT_STM, 0, 0x0000, NUM_TRANSDUCERS << 1);

  bram_cpy(BRAM_SELECT_PWE_TABLE, 0, (const uint16_t*)asin_table, 256 >> 1);
  bram_set(BRAM_SELECT_CONTROLLER, BRAM_CNT_SELECT_PHASE_CORR << 8, 0x0000, ((NUM_TRANSDUCERS + 1) >> 1));

  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_VALUE0_0, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_VALUE0_1, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_VALUE0_2, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_VALUE0_3, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_VALUE1_0, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_VALUE1_1, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_VALUE1_2, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_VALUE1_3, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_VALUE2_0, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_VALUE2_1, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_VALUE2_2, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_VALUE2_3, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_VALUE3_0, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_VALUE3_1, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_VALUE3_2, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_VALUE3_3, 0);

  set_and_wait_update(CTL_FLAG_MOD_SET);
  set_and_wait_update(CTL_FLAG_STM_SET);
  set_and_wait_update(CTL_FLAG_SILENCER_SET);
  set_and_wait_update(CTL_FLAG_DEBUG_SET);

  return NO_ERR;
}

#ifdef __cplusplus
}
#endif
