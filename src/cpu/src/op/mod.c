#ifdef __cplusplus
extern "C" {
#endif

#include "mod.h"

#include <assert.h>
#include <stddef.h>

#include "app.h"
#include "params.h"
#include "utils.h"

volatile uint32_t _mod_cycle;
volatile uint32_t _mod_freq_div;
volatile uint32_t _mod_segment;

extern volatile bool_t _silencer_strict_mode;
extern volatile uint32_t _min_freq_div_intensity;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
  uint16_t size;
  uint32_t freq_div;
  uint32_t rep;
  uint32_t segment;
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
} ModulationUpdate;

uint8_t write_mod(const volatile uint8_t* p_data) {
  static_assert(sizeof(ModulationHead) == 16, "Modulation is not valid.");
  static_assert(offsetof(ModulationHead, tag) == 0, "Modulation is not valid.");
  static_assert(offsetof(ModulationHead, flag) == 1,
                "Modulation is not valid.");
  static_assert(offsetof(ModulationHead, size) == 2,
                "Modulation is not valid.");
  static_assert(offsetof(ModulationHead, freq_div) == 4,
                "Modulation is not valid.");
  static_assert(offsetof(ModulationHead, rep) == 8, "Modulation is not valid.");
  static_assert(offsetof(ModulationHead, segment) == 12,
                "Modulation is not valid.");
  static_assert(sizeof(ModulationSubseq) == 4, "Modulation is not valid.");
  static_assert(offsetof(ModulationSubseq, tag) == 0,
                "Modulation is not valid.");
  static_assert(offsetof(ModulationSubseq, flag) == 1,
                "Modulation is not valid.");
  static_assert(offsetof(ModulationSubseq, size) == 2,
                "Modulation is not valid.");
  static_assert(offsetof(Modulation, head) == 0, "Modulation is not valid.");
  static_assert(offsetof(Modulation, subseq) == 0, "Modulation is not valid.");
  static_assert(sizeof(ModulationUpdate) == 2, "Modulation is not valid.");

  const Modulation* p = (const Modulation*)p_data;

  uint32_t freq_div;
  uint8_t segment;
  uint32_t rep;

  volatile uint16_t write = p->subseq.size;

  const uint16_t* data;
  if ((p->subseq.flag & MODULATION_FLAG_BEGIN) == MODULATION_FLAG_BEGIN) {
    _mod_cycle = 0;

    freq_div = p->head.freq_div;
    segment = p->head.segment;
    rep = p->head.rep;

    if (_silencer_strict_mode & (freq_div < _min_freq_div_intensity))
      return ERR_FREQ_DIV_TOO_SMALL;
    _mod_freq_div = freq_div;

    switch (segment) {
      case 0:
        bram_cpy(BRAM_SELECT_CONTROLLER, BRAM_ADDR_MOD_FREQ_DIV_0_0,
                 (uint16_t*)&freq_div, sizeof(uint32_t) >> 1);
        bram_cpy(BRAM_SELECT_CONTROLLER, BRAM_ADDR_MOD_REP_0_0, (uint16_t*)&rep,
                 sizeof(uint32_t) >> 1);
        break;
      case 1:
        bram_cpy(BRAM_SELECT_CONTROLLER, BRAM_ADDR_MOD_FREQ_DIV_1_0,
                 (uint16_t*)&freq_div, sizeof(uint32_t) >> 1);
        bram_cpy(BRAM_SELECT_CONTROLLER, BRAM_ADDR_MOD_REP_1_0, (uint16_t*)&rep,
                 sizeof(uint32_t) >> 1);
        break;
      default:
        return ERR_INVALID_SEGMENT;
    }
    _mod_segment = segment;

    change_mod_wr_segment(segment);

    data = (const uint16_t*)(&p_data[sizeof(ModulationHead)]);
  } else {
    data = (const uint16_t*)(&p_data[sizeof(ModulationSubseq)]);
  }

  bram_cpy(BRAM_SELECT_MOD, _mod_cycle >> 1, data, (write + 1) >> 1);
  _mod_cycle = _mod_cycle + write;

  if ((p->subseq.flag & MODULATION_FLAG_END) == MODULATION_FLAG_END) {
    switch (_mod_segment) {
      case 0:
        bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_MOD_CYCLE_0,
                   max(1, _mod_cycle) - 1);
        break;
      case 1:
        bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_MOD_CYCLE_1,
                   max(1, _mod_cycle) - 1);
        break;
      default:  // LCOV_EXCL_LINE
        break;  // LCOV_EXCL_LINE
    }

    if ((p->subseq.flag & MODULATION_FLAG_UPDATE) != 0) {
      bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_MOD_REQ_RD_SEGMENT,
                 _mod_segment);
      set_and_wait_update(CTL_FLAG_MOD_SET);
    }
  }

  return NO_ERR;
}

uint8_t change_mod_segment(const volatile uint8_t* p_data) {
  static_assert(sizeof(ModulationUpdate) == 2, "Modulation is not valid.");
  static_assert(offsetof(ModulationUpdate, tag) == 0,
                "Modulation is not valid.");
  static_assert(offsetof(ModulationUpdate, segment) == 1,
                "Modulation is not valid.");

  const ModulationUpdate* p = (const ModulationUpdate*)p_data;

  bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_MOD_REQ_RD_SEGMENT, p->segment);
  set_and_wait_update(CTL_FLAG_MOD_SET);

  return NO_ERR;
}

#ifdef __cplusplus
}
#endif
