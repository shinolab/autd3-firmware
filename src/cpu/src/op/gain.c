#ifdef __cplusplus
extern "C" {
#endif

#include <assert.h>
#include <stddef.h>

#include "app.h"
#include "params.h"
#include "stm.h"

extern volatile uint32_t _stm_freq_div;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t segment;
  uint16_t flag;
} Gain;

uint8_t write_gain(const volatile uint8_t* p_data) {
  static_assert(sizeof(Gain) == 4, "Gain is not valid.");
  static_assert(offsetof(Gain, tag) == 0, "Gain is not valid.");
  static_assert(offsetof(Gain, segment) == 1, "Gain is not valid.");
  static_assert(offsetof(Gain, flag) == 2, "Gain is not valid.");

  const Gain* p = (const Gain*)p_data;
  uint8_t segment = p->segment;

  switch (segment) {
    case 0:
      bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FREQ_DIV_0_0, 0xFFFF);
      bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FREQ_DIV_0_1, 0xFFFF);
      bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_CYCLE_0, 0);
      break;
    case 1:
      bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FREQ_DIV_1_0, 0xFFFF);
      bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FREQ_DIV_1_1, 0xFFFF);
      bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_CYCLE_1, 0);
      break;
    default:
      return ERR_INVALID_SEGMENT;
  }
  _stm_freq_div = 0xFFFFFFFF;

  bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_MODE, STM_MODE_GAIN);
  change_stm_segment(segment);
  change_stm_page(0);
  bram_cpy_volatile(BRAM_SELECT_STM, 0,
                    (volatile const uint16_t*)(&p_data[sizeof(Gain)]),
                    TRANS_NUM);
  bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_REQ_RD_SEGMENT, segment);

  if ((p->flag & GAIN_FLAG_UPDATE) != 0) set_and_wait_update(CTL_FLAG_STM_SET);

  return NO_ERR;
}

#ifdef __cplusplus
}
#endif
