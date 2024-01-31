#ifndef OP_MOD_H_
#define OP_MOD_H_

#include "app.h"
#include "params.h"

inline static void change_mod_page(uint16_t page) {
  asm("dmb");
  bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_MOD_MEM_PAGE, page);
  asm("dmb");
}

#endif  // OP_MOD_H_
