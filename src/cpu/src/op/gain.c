#ifdef __cplusplus
extern "C" {
#endif

#include <assert.h>
#include <stddef.h>

#include "app.h"
#include "params.h"
#include "stm.h"

extern volatile uint8_t _stm_mode[2];
extern volatile uint32_t _stm_cycle[2];
extern volatile uint32_t _stm_freq_div[2];

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t segment;
  uint16_t flag;
} Gain;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t segment;
} GainUpdate;

uint8_t write_gain(const volatile uint8_t* p_data) {
  static_assert(sizeof(Gain) == 4, "Gain is not valid.");
  static_assert(offsetof(Gain, tag) == 0, "Gain is not valid.");
  static_assert(offsetof(Gain, segment) == 1, "Gain is not valid.");
  static_assert(offsetof(Gain, flag) == 2, "Gain is not valid.");

  const Gain* p = (const Gain*)p_data;
  uint8_t segment = p->segment;

  switch (segment) {
    case 0:
      bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_FREQ_DIV0_0, 0xFFFF);
      bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_FREQ_DIV0_1, 0xFFFF);
      bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_REP0_0, 0xFFFF);
      bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_REP0_1, 0xFFFF);
      bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_CYCLE0, 0);
      bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_MODE0, STM_MODE_GAIN);
      break;
    case 1:
      bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_FREQ_DIV1_0, 0xFFFF);
      bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_FREQ_DIV1_1, 0xFFFF);
      bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_REP1_0, 0xFFFF);
      bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_REP1_1, 0xFFFF);
      bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_CYCLE1, 0);
      bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_MODE1, STM_MODE_GAIN);
      break;
    default:  // LCOV_EXCL_LINE
      break;  // LCOV_EXCL_LINE
  }
  _stm_cycle[segment] = 1;
  _stm_freq_div[segment] = 0xFFFFFFFF;

  change_stm_wr_segment(segment);
  change_stm_wr_page(0);
  bram_cpy_volatile(BRAM_SELECT_STM, 0,
                    (volatile const uint16_t*)(&p_data[sizeof(Gain)]),
                    NUM_TRANSDUCERS);

  if ((p->flag & GAIN_FLAG_UPDATE) != 0) {
    bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_REQ_RD_SEGMENT, segment);
    set_and_wait_update(CTL_FLAG_STM_SET);
  }

  return NO_ERR;
}

uint8_t change_gain_segment(const volatile uint8_t* p_data) {
  static_assert(sizeof(GainUpdate) == 2, "GainUpdate is not valid.");
  static_assert(offsetof(GainUpdate, tag) == 0, "GainUpdate is not valid.");
  static_assert(offsetof(GainUpdate, segment) == 1, "GainUpdate is not valid.");

  const GainUpdate* p = (const GainUpdate*)p_data;

  if (_stm_mode[p->segment] != STM_MODE_GAIN || _stm_cycle[p->segment] != 1)
    return ERR_INVALID_SEGMENT_TRANSITION;

  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_REQ_RD_SEGMENT, p->segment);
  set_and_wait_update(CTL_FLAG_STM_SET);

  return NO_ERR;
}

#ifdef __cplusplus
}
#endif
