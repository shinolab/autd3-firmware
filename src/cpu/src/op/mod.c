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

volatile uint8_t _mod_transision_mode;
volatile uint64_t _mod_transition_value;
volatile uint32_t _mod_cycle;
volatile uint32_t _mod_freq_div[2];
volatile uint32_t _mod_rep[2];
volatile uint8_t _mod_segment;

extern volatile bool_t _silencer_strict_mode;
extern volatile uint32_t _min_freq_div_intensity;
extern volatile uint32_t _min_freq_div_phase;
extern volatile uint8_t _stm_segment;
extern volatile uint32_t _stm_freq_div[2];

inline static uint8_t mod_segment_update(const uint8_t segment,
                                         const uint8_t mode,
                                         const uint64_t value) {
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_REQ_RD_SEGMENT, segment);
  if (mode == TRANSITION_MODE_SYS_TIME &&
      (value < ECATC.DC_SYS_TIME.LONGLONG + SYS_TIME_TRANSITION_MARGIN))
    return ERR_MISS_TRANSITION_TIME;
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_TRANSITION_MODE, mode);
  bram_cpy(BRAM_SELECT_CONTROLLER, ADDR_MOD_TRANSITION_VALUE_0,
           (uint16_t*)&value, sizeof(uint64_t) >> 1);
  set_and_wait_update(CTL_FLAG_MOD_SET);
  return NO_ERR;
}

uint8_t write_mod(const volatile uint8_t* p_data) {
  static_assert(sizeof(ModulationHead) == 24, "Modulation is not valid.");
  static_assert(offsetof(ModulationHead, tag) == 0, "Modulation is not valid.");
  static_assert(offsetof(ModulationHead, flag) == 1,
                "Modulation is not valid.");
  static_assert(offsetof(ModulationHead, size) == 2,
                "Modulation is not valid.");
  static_assert(offsetof(ModulationHead, transition_mode) == 4,
                "Modulation is not valid.");
  static_assert(offsetof(ModulationHead, freq_div) == 8,
                "Modulation is not valid.");
  static_assert(offsetof(ModulationHead, rep) == 12,
                "Modulation is not valid.");
  static_assert(offsetof(ModulationHead, transition_value) == 16,
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

  const Modulation* p = (const Modulation*)p_data;

  volatile uint16_t write = p->subseq.size;
  const uint8_t segment = (p->head.flag & MODULATION_FLAG_SEGMENT) != 0 ? 1 : 0;

  const uint16_t* data;
  if ((p->subseq.flag & MODULATION_FLAG_BEGIN) == MODULATION_FLAG_BEGIN) {
    if (validate_transition_mode(_mod_segment, segment, p->head.rep,
                                 p->head.transition_mode))
      return ERR_INVALID_TRANSITION_MODE;

    if (validate_silencer_settings(
            _silencer_strict_mode, _min_freq_div_intensity, _min_freq_div_phase,
            _stm_freq_div[_stm_segment], p->head.freq_div))
      return ERR_INVALID_SILENCER_SETTING;

    if (p->head.transition_mode != TRANSITION_MODE_NONE) _mod_segment = segment;
    _mod_cycle = 0;
    _mod_transision_mode = p->head.transition_mode;
    _mod_transition_value = p->head.transition_value;
    _mod_freq_div[segment] = p->head.freq_div;
    _mod_rep[segment] = p->head.rep;

    switch (segment) {
      case 0:
        bram_cpy(BRAM_SELECT_CONTROLLER, ADDR_MOD_FREQ_DIV0_0,
                 (uint16_t*)&_mod_freq_div[segment], sizeof(uint32_t) >> 1);
        bram_cpy(BRAM_SELECT_CONTROLLER, ADDR_MOD_REP0_0,
                 (uint16_t*)&p->head.rep, sizeof(uint32_t) >> 1);
        break;
      case 1:
        bram_cpy(BRAM_SELECT_CONTROLLER, ADDR_MOD_FREQ_DIV1_0,
                 (uint16_t*)&_mod_freq_div[segment], sizeof(uint32_t) >> 1);
        bram_cpy(BRAM_SELECT_CONTROLLER, ADDR_MOD_REP1_0,
                 (uint16_t*)&p->head.rep, sizeof(uint32_t) >> 1);
        break;
      default:  // LCOV_EXCL_LINE
        break;  // LCOV_EXCL_LINE
    }

    change_mod_wr_segment(segment);

    data = (const uint16_t*)(&p_data[sizeof(ModulationHead)]);
  } else {
    data = (const uint16_t*)(&p_data[sizeof(ModulationSubseq)]);
  }

  bram_cpy(BRAM_SELECT_MOD, _mod_cycle >> 1, data, (write + 1) >> 1);
  _mod_cycle = _mod_cycle + write;

  if ((p->subseq.flag & MODULATION_FLAG_END) == MODULATION_FLAG_END) {
    switch (segment) {
      case 0:
        bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_CYCLE0,
                   max(1, _mod_cycle) - 1);
        break;
      case 1:
        bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_CYCLE1,
                   max(1, _mod_cycle) - 1);
        break;
      default:  // LCOV_EXCL_LINE
        break;  // LCOV_EXCL_LINE
    }

    if ((p->subseq.flag & MODULATION_FLAG_UPDATE) != 0)
      return mod_segment_update(segment, _mod_transision_mode,
                                _mod_transition_value);
  }

  return NO_ERR;
}

uint8_t change_mod_segment(const volatile uint8_t* p_data) {
  static_assert(sizeof(ModulationUpdate) == 16, "Modulation is not valid.");
  static_assert(offsetof(ModulationUpdate, tag) == 0,
                "Modulation is not valid.");
  static_assert(offsetof(ModulationUpdate, segment) == 1,
                "Modulation is not valid.");
  static_assert(offsetof(ModulationUpdate, transition_mode) == 2,
                "Modulation is not valid.");
  static_assert(offsetof(ModulationUpdate, transition_value) == 8,
                "Modulation is not valid.");

  const ModulationUpdate* p = (const ModulationUpdate*)p_data;
  if (validate_transition_mode(_mod_segment, p->segment, _mod_rep[p->segment],
                               p->transition_mode))
    return ERR_INVALID_TRANSITION_MODE;

  if (validate_silencer_settings(
          _silencer_strict_mode, _min_freq_div_intensity, _min_freq_div_phase,
          _stm_freq_div[_stm_segment], _mod_freq_div[p->segment]))
    return ERR_INVALID_SILENCER_SETTING;

  _mod_segment = p->segment;
  return mod_segment_update(p->segment, p->transition_mode,
                            p->transition_value);
}

#ifdef __cplusplus
}
#endif
