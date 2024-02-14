#ifndef OP_MOD_H_
#define OP_MOD_H_

#include "app.h"
#include "params.h"

inline static void change_mod_wr_segment(uint16_t segment) {
  asm("dmb");
  bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_MOD_MEM_WR_SEGMENT, segment);
  asm("dmb");
}

#endif  // OP_MOD_H_
