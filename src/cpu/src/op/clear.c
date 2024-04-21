#ifdef __cplusplus
extern "C" {
#endif

#include <assert.h>
#include <stddef.h>

#include "app.h"
#include "mod.h"
#include "params.h"
#include "stm.h"

extern volatile bool_t _read_fpga_state;
extern volatile uint16_t _fpga_flags_internal;

extern volatile uint32_t _mod_cycle;
extern volatile uint32_t _mod_freq_div[2];

extern volatile uint8_t _stm_mode[2];
extern volatile uint32_t _stm_cycle[2];
extern volatile uint32_t _stm_freq_div[2];

extern volatile bool_t _silencer_strict_mode;
extern volatile uint32_t _min_freq_div_intensity;
extern volatile uint32_t _min_freq_div_phase;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t _pad;
} Clear;

uint8_t clear(void) {
  static_assert(sizeof(Clear) == 2, "Clear is not valid.");
  static_assert(offsetof(Clear, tag) == 0, "Clear is not valid.");

  _read_fpga_state = false;

  _fpga_flags_internal = 0;

  bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_UPDATE_RATE_INTENSITY, 256);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_UPDATE_RATE_PHASE, 256);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_MODE,
             SILENCER_MODE_FIXED_COMPLETION_STEPS);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_COMPLETION_STEPS_INTENSITY,
             10);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_COMPLETION_STEPS_PHASE, 40);
  _silencer_strict_mode = true;
  _min_freq_div_intensity = 10 << 9;
  _min_freq_div_phase = 40 << 9;

  _mod_cycle = 2;
  _mod_freq_div[0] = 5120;
  _mod_freq_div[1] = 5120;
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_REQ_RD_SEGMENT, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_CYCLE0, _mod_cycle - 1);
  bram_cpy(BRAM_SELECT_CONTROLLER, ADDR_MOD_FREQ_DIV0_0,
           (uint16_t*)&_mod_freq_div, sizeof(uint32_t) >> 1);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_CYCLE1, _mod_cycle - 1);
  bram_cpy(BRAM_SELECT_CONTROLLER, ADDR_MOD_FREQ_DIV1_0,
           (uint16_t*)&_mod_freq_div, sizeof(uint32_t) >> 1);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_REP0_0, 0xFFFF);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_REP0_1, 0xFFFF);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_REP1_0, 0xFFFF);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_REP1_1, 0xFFFF);
  change_mod_wr_segment(0);
  bram_write(BRAM_SELECT_MOD, 0, 0xFFFF);
  change_mod_wr_segment(1);
  bram_write(BRAM_SELECT_MOD, 0, 0xFFFF);

  _stm_mode[0] = STM_MODE_GAIN;
  _stm_mode[1] = STM_MODE_GAIN;
  _stm_cycle[0] = 1;
  _stm_cycle[1] = 1;
  _stm_freq_div[0] = 0xFFFFFFFF;
  _stm_freq_div[1] = 0xFFFFFFFF;
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_MODE0, STM_MODE_GAIN);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_MODE1, STM_MODE_GAIN);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_REQ_RD_SEGMENT, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_CYCLE0, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_FREQ_DIV0_0, 0xFFFF);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_FREQ_DIV0_1, 0xFFFF);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_CYCLE1, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_FREQ_DIV1_0, 0xFFFF);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_FREQ_DIV1_1, 0xFFFF);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_REP0_0, 0xFFFF);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_REP0_1, 0xFFFF);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_REP1_0, 0xFFFF);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_REP1_1, 0xFFFF);
  change_stm_wr_segment(0);
  change_stm_wr_page(0);
  bram_set(BRAM_SELECT_STM, 0, 0x0000, NUM_TRANSDUCERS << 1);
  change_stm_wr_segment(1);
  change_stm_wr_page(0);
  bram_set(BRAM_SELECT_STM, 0, 0x0000, NUM_TRANSDUCERS << 1);

  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_TYPE0, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_TYPE1, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_TYPE2, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_TYPE3, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_VALUE0, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_VALUE1, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_VALUE2, 0);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_VALUE3, 0);

  set_and_wait_update(CTL_FLAG_MOD_SET);
  set_and_wait_update(CTL_FLAG_STM_SET);
  set_and_wait_update(CTL_FLAG_SILENCER_SET);
  set_and_wait_update(CTL_FLAG_DEBUG_SET);

  return NO_ERR;
}

#ifdef __cplusplus
}
#endif
