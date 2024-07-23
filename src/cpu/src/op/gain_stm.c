#ifdef __cplusplus
extern "C" {
#endif

#include "gain_stm.h"

#include <assert.h>
#include <stddef.h>

#include "app.h"
#include "params.h"
#include "silencer.h"
#include "stm.h"
#include "utils.h"
#include "validate.h"

#define GAIN_STM_BUF_PAGE_SIZE_WIDTH (6)
#define GAIN_STM_BUF_PAGE_SIZE (1 << GAIN_STM_BUF_PAGE_SIZE_WIDTH)
#define GAIN_STM_BUF_PAGE_SIZE_MASK (GAIN_STM_BUF_PAGE_SIZE - 1)

volatile uint8_t _stm_segment;
volatile uint8_t _stm_transition_mode;
volatile uint64_t _stm_transition_value;
volatile uint8_t _stm_mode[2];
volatile uint16_t _stm_cycle[2];
volatile uint16_t _stm_freq_div[2];
volatile uint16_t _stm_rep[2];
volatile uint8_t _gain_stm_mode;

extern volatile uint8_t _mod_segment;
extern volatile uint16_t _mod_freq_div[2];

uint8_t write_gain_stm(const volatile uint8_t* p_data) {
  static_assert(sizeof(GainSTMHead) == 16, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMHead, tag) == 0, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMHead, flag) == 1, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMHead, mode) == 2, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMHead, transition_mode) == 3,
                "GainSTM is not valid.");
  static_assert(offsetof(GainSTMHead, freq_div) == 4, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMHead, rep) == 6, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMHead, transition_value) == 8,
                "GainSTM is not valid.");
  static_assert(sizeof(GainSTMSubseq) == 2, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMSubseq, tag) == 0, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMSubseq, flag) == 1, "GainSTM is not valid.");
  static_assert(offsetof(GainSTM, head) == 0, "GainSTM is not valid.");
  static_assert(offsetof(GainSTM, subseq) == 0, "GainSTM is not valid.");

  const GainSTM* p = (const GainSTM*)p_data;

  const uint8_t send = (p->subseq.flag >> 6) + 1;
  const uint8_t segment = (p->head.flag & GAIN_STM_FLAG_SEGMENT) != 0 ? 1 : 0;

  const volatile uint16_t *src, *src_base;

  if ((p->subseq.flag & GAIN_STM_FLAG_BEGIN) == GAIN_STM_FLAG_BEGIN) {
    if (validate_transition_mode(_stm_segment, segment, p->head.rep,
                                 p->head.transition_mode))
      return ERR_INVALID_TRANSITION_MODE;

    if (validate_silencer_settings(p->head.freq_div,
                                   _mod_freq_div[_mod_segment]))
      return ERR_INVALID_SILENCER_SETTING;

    if (p->head.transition_mode != TRANSITION_MODE_NONE) _stm_segment = segment;
    _stm_cycle[segment] = 0;
    _gain_stm_mode = p->head.mode;
    _stm_transition_mode = p->head.transition_mode;
    _stm_transition_value = p->head.transition_value;
    _stm_freq_div[segment] = p->head.freq_div;
    _stm_rep[segment] = p->head.rep;

    switch (segment) {
      case 0:
        bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_FREQ_DIV0,
                   _stm_freq_div[segment]);
        bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_MODE0, STM_MODE_GAIN);
        bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_REP0, p->head.rep);
        break;
      case 1:
        bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_FREQ_DIV1,
                   _stm_freq_div[segment]);
        bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_MODE1, STM_MODE_GAIN);
        bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_REP1, p->head.rep);
        break;
      default:  // LCOV_EXCL_LINE
        break;  // LCOV_EXCL_LINE
    }

    change_stm_wr_segment(segment);
    change_stm_wr_page(0);

    src_base = (const uint16_t*)(&p_data[sizeof(GainSTMHead)]);
  } else {
    src_base = (const uint16_t*)(&p_data[sizeof(GainSTMSubseq)]);
  }

  src = src_base;

  switch (_gain_stm_mode) {
    case GAIN_STM_MODE_INTENSITY_PHASE_FULL:
      bram_cpy_volatile(
          BRAM_SELECT_STM,
          (_stm_cycle[segment] & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src,
          NUM_TRANSDUCERS);
      _stm_cycle[segment] = _stm_cycle[segment] + 1;
      break;
    case GAIN_STM_MODE_PHASE_FULL:
      bram_cpy_gain_stm_phase_full(
          (_stm_cycle[segment] & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src, 0,
          NUM_TRANSDUCERS);
      _stm_cycle[segment] = _stm_cycle[segment] + 1;

      if (send > 1) {
        src = src_base;
        bram_cpy_gain_stm_phase_full(
            (_stm_cycle[segment] & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src, 8,
            NUM_TRANSDUCERS);
        _stm_cycle[segment] = _stm_cycle[segment] + 1;
      }
      break;
    case GAIN_STM_MODE_PHASE_HALF:
      bram_cpy_gain_stm_phase_half(
          (_stm_cycle[segment] & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src, 0,
          NUM_TRANSDUCERS);
      _stm_cycle[segment] = _stm_cycle[segment] + 1;

      if (send > 1) {
        src = src_base;
        bram_cpy_gain_stm_phase_half(
            (_stm_cycle[segment] & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src, 4,
            NUM_TRANSDUCERS);
        _stm_cycle[segment] = _stm_cycle[segment] + 1;
      }

      if (send > 2) {
        src = src_base;
        bram_cpy_gain_stm_phase_half(
            (_stm_cycle[segment] & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src, 8,
            NUM_TRANSDUCERS);
        _stm_cycle[segment] = _stm_cycle[segment] + 1;
      }

      if (send > 3) {
        src = src_base;
        bram_cpy_gain_stm_phase_half(
            (_stm_cycle[segment] & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src, 12,
            NUM_TRANSDUCERS);
        _stm_cycle[segment] = _stm_cycle[segment] + 1;
      }
      break;
    default:
      return ERR_INVALID_GAIN_STM_MODE;
  }

  if ((_stm_cycle[segment] & GAIN_STM_BUF_PAGE_SIZE_MASK) == 0)
    change_stm_wr_page((_stm_cycle[segment] & ~GAIN_STM_BUF_PAGE_SIZE_MASK) >>
                       GAIN_STM_BUF_PAGE_SIZE_WIDTH);

  if ((p->subseq.flag & GAIN_STM_FLAG_END) == GAIN_STM_FLAG_END) {
    _stm_mode[segment] = STM_MODE_GAIN;
    switch (segment) {
      case 0:
        bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_CYCLE0,
                   max(1, _stm_cycle[segment]) - 1);
        break;
      case 1:
        bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_CYCLE1,
                   max(1, _stm_cycle[segment]) - 1);
        break;
      default:  // LCOV_EXCL_LINE
        break;  // LCOV_EXCL_LINE
    }

    if ((p->subseq.flag & GAIN_STM_FLAG_UPDATE) != 0)
      return stm_segment_update(segment, _stm_transition_mode,
                                _stm_transition_value);
  }

  return NO_ERR;
}

uint8_t change_gain_stm_segment(const volatile uint8_t* p_data) {
  static_assert(sizeof(GainSTMUpdate) == 16, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMUpdate, tag) == 0, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMUpdate, segment) == 1, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMUpdate, transition_mode) == 2,
                "GainSTM is not valid.");
  static_assert(offsetof(GainSTMUpdate, transition_value) == 8,
                "GainSTM is not valid.");

  const GainSTMUpdate* p = (const GainSTMUpdate*)p_data;

  if (_stm_mode[p->segment] != STM_MODE_GAIN || _stm_cycle[p->segment] == 1)
    return ERR_INVALID_SEGMENT_TRANSITION;

  if (validate_transition_mode(_stm_segment, p->segment, _stm_rep[p->segment],
                               p->transition_mode))
    return ERR_INVALID_TRANSITION_MODE;

  if (validate_silencer_settings(_stm_freq_div[p->segment],
                                 _mod_freq_div[_mod_segment]))
    return ERR_INVALID_SILENCER_SETTING;

  _stm_segment = p->segment;
  return stm_segment_update(p->segment, p->transition_mode,
                            p->transition_value);
}

#ifdef __cplusplus
}
#endif
