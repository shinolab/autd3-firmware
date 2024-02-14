#ifndef OP_STM_H_
#define OP_STM_H_

#include "app.h"
#include "params.h"

inline static void change_stm_wr_segment(uint16_t segment) {
  asm("dmb");
  bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_MEM_WR_SEGMENT, segment);
  asm("dmb");
}

inline static void change_stm_wr_page(uint16_t page) {
  asm("dmb");
  bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_MEM_WR_PAGE, page);
  asm("dmb");
}

#endif  // OP_STM_H_
