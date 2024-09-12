#ifndef OP_MOD_H_
#define OP_MOD_H_

#include "app.h"
#include "params.h"

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
  uint16_t size;
  uint16_t freq_div;
  uint16_t rep;
  Transition transition;
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
  uint8_t _pad[6];
  Transition transition;
} ModulationUpdate;

inline static void change_mod_wr_segment(uint16_t segment) {
  asm("dmb");
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_MEM_WR_SEGMENT, segment);
  asm("dmb");
}

#endif  // OP_MOD_H_
