#ifndef OP_MOD_H_
#define OP_MOD_H_

#include "app.h"
#include "params.h"

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
  uint8_t size;
  uint8_t transition_mode;
  uint16_t freq_div;
  uint16_t rep;
  uint64_t transition_value;
} ModulationHead;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
  uint16_t size;
} ModulationSubseq;

typedef ALIGN2 union {
  ModulationHead head;
  ModulationSubseq subseq;
} Modulation;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t segment;
  uint8_t transition_mode;
  uint8_t _pad[5];
  uint64_t transition_value;
} ModulationUpdate;

inline static void change_mod_wr_segment(uint16_t segment) {
  asm("dmb");
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_MEM_WR_SEGMENT, segment);
  asm("dmb");
}

inline static void change_mod_wr_page(uint16_t page) {
  asm("dmb");
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_MEM_WR_PAGE, page);
  asm("dmb");
}

#endif  // OP_MOD_H_
