#ifdef __cplusplus
extern "C" {
#endif

#include <assert.h>
#include <stddef.h>

#include "app.h"
#include "params.h"
#include "stm.h"
#include "utils.h"

#define GAIN_STM_BUF_PAGE_SIZE_WIDTH (6)
#define GAIN_STM_BUF_PAGE_SIZE (1 << GAIN_STM_BUF_PAGE_SIZE_WIDTH)
#define GAIN_STM_BUF_PAGE_SIZE_MASK (GAIN_STM_BUF_PAGE_SIZE - 1)

volatile uint8_t _stm_segment;
volatile uint8_t _stm_transition_mode;
volatile uint64_t _stm_transition_value;
volatile uint8_t _stm_mode[2];
volatile uint32_t _stm_cycle[2];
volatile uint32_t _stm_freq_div[2];
volatile uint8_t _gain_stm_mode;

extern bool_t validate_silencer_settings(void);

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
  uint8_t mode;
  uint8_t transition_mode;
  uint8_t _pad[4];
  uint32_t freq_div;
  uint32_t rep;
  uint64_t transition_value;
} GainSTMHead;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
} GainSTMSubseq;

typedef union {
  GainSTMHead head;
  GainSTMSubseq subseq;
} GainSTM;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t segment;
  uint8_t transition_mode;
  uint8_t _pad[5];
  uint64_t transition_value;
} GainSTMUpdate;

uint8_t write_gain_stm(const volatile uint8_t* p_data) {
  static_assert(sizeof(GainSTMHead) == 24, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMHead, tag) == 0, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMHead, flag) == 1, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMHead, mode) == 2, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMHead, transition_mode) == 3,
                "GainSTM is not valid.");
  static_assert(offsetof(GainSTMHead, freq_div) == 8, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMHead, rep) == 12, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMHead, transition_value) == 16,
                "GainSTM is not valid.");
  static_assert(sizeof(GainSTMSubseq) == 2, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMSubseq, tag) == 0, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMSubseq, flag) == 1, "GainSTM is not valid.");
  static_assert(offsetof(GainSTM, head) == 0, "GainSTM is not valid.");
  static_assert(offsetof(GainSTM, subseq) == 0, "GainSTM is not valid.");

  const GainSTM* p = (const GainSTM*)p_data;

  uint8_t send = (p->subseq.flag >> 6) + 1;

  const volatile uint16_t *src, *src_base;

  if ((p->subseq.flag & GAIN_STM_FLAG_BEGIN) == GAIN_STM_FLAG_BEGIN) {
    _gain_stm_mode = p->head.mode;
    _stm_segment = (p->head.flag & GAIN_STM_FLAG_SEGMENT) != 0 ? 1 : 0;

    _stm_cycle[_stm_segment] = 0;
    _stm_transition_mode = p->head.transition_mode;
    _stm_transition_value = p->head.transition_value;
    _stm_freq_div[_stm_segment] = p->head.freq_div;
    if (validate_silencer_settings()) return ERR_INVALID_SILENCER_SETTING;

    switch (_stm_segment) {
      case 0:
        bram_cpy(BRAM_SELECT_CONTROLLER, ADDR_STM_FREQ_DIV0_0,
                 (uint16_t*)&_stm_freq_div[_stm_segment],
                 sizeof(uint32_t) >> 1);
        bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_MODE0, STM_MODE_GAIN);
        bram_cpy(BRAM_SELECT_CONTROLLER, ADDR_STM_REP0_0,
                 (uint16_t*)&p->head.rep, sizeof(uint32_t) >> 1);
        break;
      case 1:
        bram_cpy(BRAM_SELECT_CONTROLLER, ADDR_STM_FREQ_DIV1_0,
                 (uint16_t*)&_stm_freq_div[_stm_segment],
                 sizeof(uint32_t) >> 1);
        bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_MODE1, STM_MODE_GAIN);
        bram_cpy(BRAM_SELECT_CONTROLLER, ADDR_STM_REP1_0,
                 (uint16_t*)&p->head.rep, sizeof(uint32_t) >> 1);
        break;
      default:  // LCOV_EXCL_LINE
        break;  // LCOV_EXCL_LINE
    }

    change_stm_wr_segment(_stm_segment);
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
          (_stm_cycle[_stm_segment] & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src,
          NUM_TRANSDUCERS);
      _stm_cycle[_stm_segment] = _stm_cycle[_stm_segment] + 1;
      break;
    case GAIN_STM_MODE_PHASE_FULL:
      bram_cpy_gain_stm_phase_full(
          (_stm_cycle[_stm_segment] & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src, 0,
          NUM_TRANSDUCERS);
      _stm_cycle[_stm_segment] = _stm_cycle[_stm_segment] + 1;

      if (send > 1) {
        src = src_base;
        bram_cpy_gain_stm_phase_full(
            (_stm_cycle[_stm_segment] & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src,
            8, NUM_TRANSDUCERS);
        _stm_cycle[_stm_segment] = _stm_cycle[_stm_segment] + 1;
      }
      break;
    case GAIN_STM_MODE_PHASE_HALF:
      bram_cpy_gain_stm_phase_half(
          (_stm_cycle[_stm_segment] & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src, 0,
          NUM_TRANSDUCERS);
      _stm_cycle[_stm_segment] = _stm_cycle[_stm_segment] + 1;

      if (send > 1) {
        src = src_base;
        bram_cpy_gain_stm_phase_half(
            (_stm_cycle[_stm_segment] & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src,
            4, NUM_TRANSDUCERS);
        _stm_cycle[_stm_segment] = _stm_cycle[_stm_segment] + 1;
      }

      if (send > 2) {
        src = src_base;
        bram_cpy_gain_stm_phase_half(
            (_stm_cycle[_stm_segment] & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src,
            8, NUM_TRANSDUCERS);
        _stm_cycle[_stm_segment] = _stm_cycle[_stm_segment] + 1;
      }

      if (send > 3) {
        src = src_base;
        bram_cpy_gain_stm_phase_half(
            (_stm_cycle[_stm_segment] & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src,
            12, NUM_TRANSDUCERS);
        _stm_cycle[_stm_segment] = _stm_cycle[_stm_segment] + 1;
      }
      break;
    default:
      return ERR_INVALID_GAIN_STM_MODE;
  }

  if ((_stm_cycle[_stm_segment] & GAIN_STM_BUF_PAGE_SIZE_MASK) == 0)
    change_stm_wr_page(
        (_stm_cycle[_stm_segment] & ~GAIN_STM_BUF_PAGE_SIZE_MASK) >>
        GAIN_STM_BUF_PAGE_SIZE_WIDTH);

  if ((p->subseq.flag & GAIN_STM_FLAG_END) == GAIN_STM_FLAG_END) {
    _stm_mode[_stm_segment] = STM_MODE_GAIN;
    switch (_stm_segment) {
      case 0:
        bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_CYCLE0,
                   max(1, _stm_cycle[_stm_segment]) - 1);
        break;
      case 1:
        bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_CYCLE1,
                   max(1, _stm_cycle[_stm_segment]) - 1);
        break;
      default:  // LCOV_EXCL_LINE
        break;  // LCOV_EXCL_LINE
    }

    if ((p->subseq.flag & GAIN_STM_FLAG_UPDATE) != 0)
      return stm_segment_update(_stm_segment, _stm_transition_mode,
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
  _stm_segment = p->segment;
  if (validate_silencer_settings()) return ERR_INVALID_SILENCER_SETTING;
  return stm_segment_update(p->segment, p->transition_mode,
                            p->transition_value);
}

#ifdef __cplusplus
}
#endif
