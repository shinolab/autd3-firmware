#ifndef OP_STM_H_
#define OP_STM_H_

#include "app.h"
#include "iodefine.h"
#include "params.h"

inline static void change_stm_wr_segment(uint16_t segment) {
  asm("dmb");
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_MEM_WR_SEGMENT, segment);
  asm("dmb");
}

inline static void change_stm_wr_page(uint16_t page) {
  asm("dmb");
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_MEM_WR_PAGE, page);
  asm("dmb");
}

inline static uint8_t stm_segment_update(const uint8_t segment, const uint8_t mode, const uint64_t value) {
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_REQ_RD_SEGMENT, segment);
  if (mode == TRANSITION_MODE_SYS_TIME && (value < ECATC.DC_SYS_TIME.LONGLONG + SYS_TIME_TRANSITION_MARGIN)) return ERR_MISS_TRANSITION_TIME;
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_TRANSITION_MODE, mode);
  bram_cpy(BRAM_SELECT_CONTROLLER, ADDR_STM_TRANSITION_VALUE_0, (uint16_t*)&value, sizeof(uint64_t) >> 1);
  set_and_wait_update(CTL_FLAG_STM_SET);
  return NO_ERR;
}

#endif  // OP_STM_H_
