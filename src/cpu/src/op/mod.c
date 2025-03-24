#ifdef __cplusplus
extern "C" {
#endif

#include "mod.h"

#include <assert.h>
#include <stddef.h>

#include "app.h"
#include "iodefine.h"
#include "params.h"
#include "silencer.h"
#include "utils.h"
#include "validate.h"

#define MOD_BUF_PAGE_SIZE_WIDTH (15)
#define MOD_BUF_PAGE_SIZE (1 << MOD_BUF_PAGE_SIZE_WIDTH)
#define MOD_BUF_PAGE_SIZE_MASK (MOD_BUF_PAGE_SIZE - 1)

volatile uint8_t _mod_transision_mode;
volatile uint64_t _mod_transition_value;
volatile uint32_t _mod_cycle;
volatile uint16_t _mod_freq_div[2];
volatile uint16_t _mod_rep[2];
volatile uint8_t _mod_segment;

extern volatile uint8_t _stm_segment;
extern volatile uint16_t _stm_freq_div[2];

inline static uint8_t mod_segment_update(const uint8_t segment, const uint8_t mode, const uint64_t value) {
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_REQ_RD_SEGMENT, segment);
  if (mode == TRANSITION_MODE_SYS_TIME && (value < ECATC.DC_SYS_TIME.LONGLONG + SYS_TIME_TRANSITION_MARGIN)) return ERR_MISS_TRANSITION_TIME;
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_TRANSITION_MODE, mode);
  bram_cpy(BRAM_SELECT_CONTROLLER, ADDR_MOD_TRANSITION_VALUE_0, (uint16_t*)&value, sizeof(uint64_t) >> 1);
  set_and_wait_update(CTL_FLAG_MOD_SET);
  return NO_ERR;
}

uint8_t write_mod(const volatile uint8_t* p_data) {
  static_assert(sizeof(ModulationHead) == 16, "Modulation is not valid.");
  static_assert(offsetof(ModulationHead, tag) == 0, "Modulation is not valid.");
  static_assert(offsetof(ModulationHead, flag) == 1, "Modulation is not valid.");
  static_assert(offsetof(ModulationHead, size) == 2, "Modulation is not valid.");
  static_assert(offsetof(ModulationHead, transition_mode) == 3, "Modulation is not valid.");
  static_assert(offsetof(ModulationHead, freq_div) == 4, "Modulation is not valid.");
  static_assert(offsetof(ModulationHead, rep) == 6, "Modulation is not valid.");
  static_assert(offsetof(ModulationHead, transition_value) == 8, "Modulation is not valid.");
  static_assert(sizeof(ModulationSubseq) == 4, "Modulation is not valid.");
  static_assert(offsetof(ModulationSubseq, tag) == 0, "Modulation is not valid.");
  static_assert(offsetof(ModulationSubseq, flag) == 1, "Modulation is not valid.");
  static_assert(offsetof(ModulationSubseq, size) == 2, "Modulation is not valid.");
  static_assert(offsetof(Modulation, head) == 0, "Modulation is not valid.");
  static_assert(offsetof(Modulation, subseq) == 0, "Modulation is not valid.");

  uint16_t write;
  volatile uint32_t page_capacity;
  const Modulation* p = (const Modulation*)p_data;

  const uint8_t segment = (p->head.flag & MODULATION_FLAG_SEGMENT) != 0 ? 1 : 0;

  const uint16_t* data;
  if ((p->subseq.flag & MODULATION_FLAG_BEGIN) == MODULATION_FLAG_BEGIN) {
    if (validate_transition_mode(_mod_segment, segment, p->head.rep, p->head.transition_mode)) return ERR_INVALID_TRANSITION_MODE;

    if (validate_silencer_settings(_stm_freq_div[_stm_segment], p->head.freq_div)) return ERR_INVALID_SILENCER_SETTING;

    if (p->head.transition_mode != TRANSITION_MODE_NONE) _mod_segment = segment;
    _mod_cycle = 0;
    _mod_transision_mode = p->head.transition_mode;
    _mod_transition_value = p->head.transition_value;
    _mod_freq_div[segment] = p->head.freq_div;
    _mod_rep[segment] = p->head.rep;

    bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_FREQ_DIV0 + segment, p->head.freq_div);
    bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_REP0 + segment, p->head.rep);

    change_mod_wr_segment(segment);
    change_mod_wr_page(0);

    write = p->head.size;
    data = (const uint16_t*)(&p_data[sizeof(ModulationHead)]);
  } else {
    write = p->subseq.size;
    data = (const uint16_t*)(&p_data[sizeof(ModulationSubseq)]);
  }

  page_capacity = MOD_BUF_PAGE_SIZE - (_mod_cycle & MOD_BUF_PAGE_SIZE_MASK);

  if (write < page_capacity) {
    bram_cpy(BRAM_SELECT_MOD, (_mod_cycle & MOD_BUF_PAGE_SIZE_MASK) >> 1, data, (write + 1) >> 1);
    _mod_cycle = _mod_cycle + write;
  } else {
    bram_cpy(BRAM_SELECT_MOD, (_mod_cycle & MOD_BUF_PAGE_SIZE_MASK) >> 1, data, page_capacity >> 1);
    _mod_cycle = _mod_cycle + page_capacity;

    change_mod_wr_page((_mod_cycle & ~MOD_BUF_PAGE_SIZE_MASK) >> MOD_BUF_PAGE_SIZE_WIDTH);

    bram_cpy(BRAM_SELECT_MOD, 0, data + (page_capacity >> 1), (write - page_capacity + 1) >> 1);
    _mod_cycle = _mod_cycle + (write - page_capacity);
  }

  if ((p->subseq.flag & MODULATION_FLAG_END) == MODULATION_FLAG_END) {
    bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_CYCLE0 + segment, max(1, _mod_cycle) - 1);
    if ((p->subseq.flag & MODULATION_FLAG_UPDATE) != 0) return mod_segment_update(segment, _mod_transision_mode, _mod_transition_value);
  }

  return NO_ERR;
}

uint8_t change_mod_segment(const volatile uint8_t* p_data) {
  static_assert(sizeof(ModulationUpdate) == 16, "Modulation is not valid.");
  static_assert(offsetof(ModulationUpdate, tag) == 0, "Modulation is not valid.");
  static_assert(offsetof(ModulationUpdate, segment) == 1, "Modulation is not valid.");
  static_assert(offsetof(ModulationUpdate, transition_mode) == 2, "Modulation is not valid.");
  static_assert(offsetof(ModulationUpdate, transition_value) == 8, "Modulation is not valid.");

  const ModulationUpdate* p = (const ModulationUpdate*)p_data;
  if (validate_transition_mode(_mod_segment, p->segment, _mod_rep[p->segment], p->transition_mode)) return ERR_INVALID_TRANSITION_MODE;

  if (validate_silencer_settings(_stm_freq_div[_stm_segment], _mod_freq_div[p->segment])) return ERR_INVALID_SILENCER_SETTING;

  _mod_segment = p->segment;
  return mod_segment_update(p->segment, p->transition_mode, p->transition_value);
}

#ifdef __cplusplus
}
#endif
