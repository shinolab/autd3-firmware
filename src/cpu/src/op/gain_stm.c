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
volatile uint32_t _stm_cycle;
volatile uint32_t _stm_freq_div;
volatile uint8_t _gain_stm_mode;

extern volatile bool_t _silencer_strict_mode;
extern volatile uint32_t _min_freq_div_intensity;
extern volatile uint32_t _min_freq_div_phase;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
  uint8_t mode;
  uint8_t segment;
  uint32_t freq_div;
  uint32_t rep;
} GainSTMHead;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
} GainSTMSubseq;

typedef union {
  GainSTMHead head;
  GainSTMSubseq subseq;
} GainSTM;

uint8_t write_gain_stm(const volatile uint8_t* p_data) {
  static_assert(sizeof(GainSTMHead) == 12, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMHead, tag) == 0, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMHead, flag) == 1, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMHead, mode) == 2, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMHead, segment) == 3, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMHead, freq_div) == 4, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMHead, rep) == 8, "GainSTM is not valid.");
  static_assert(sizeof(GainSTMSubseq) == 2, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMSubseq, tag) == 0, "GainSTM is not valid.");
  static_assert(offsetof(GainSTMSubseq, flag) == 1, "GainSTM is not valid.");
  static_assert(offsetof(GainSTM, head) == 0, "GainSTM is not valid.");
  static_assert(offsetof(GainSTM, subseq) == 0, "GainSTM is not valid.");

  const GainSTM* p = (const GainSTM*)p_data;

  uint8_t send = (p->subseq.flag >> 6) + 1;

  const volatile uint16_t *src, *src_base;
  uint32_t freq_div;
  uint32_t rep;
  uint8_t segment;
  uint8_t ret = NO_ERR;

  if ((p->subseq.flag & GAIN_STM_FLAG_BEGIN) == GAIN_STM_FLAG_BEGIN) {
    _stm_cycle = 0;

    _gain_stm_mode = p->head.mode;
    rep = p->head.rep;
    segment = p->head.segment;

    freq_div = p->head.freq_div;
    if (_silencer_strict_mode) {
      if ((freq_div < _min_freq_div_intensity) ||
          (freq_div < _min_freq_div_phase))
        return ERR_FREQ_DIV_TOO_SMALL;
    }
    _stm_freq_div = freq_div;

    switch (segment) {
      case 0:
        bram_cpy(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FREQ_DIV_0_0,
                 (uint16_t*)&freq_div, sizeof(uint32_t) >> 1);
        break;
      case 1:
        bram_cpy(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FREQ_DIV_1_0,
                 (uint16_t*)&freq_div, sizeof(uint32_t) >> 1);
        break;
      default:
        return ERR_INVALID_SEGMENT;
    }
    _stm_segment = segment;

    bram_cpy(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_REP_0, (uint16_t*)&rep,
             sizeof(uint32_t) >> 1);

    change_stm_segment(segment);
    change_stm_page(0);

    src_base = (const uint16_t*)(&p_data[sizeof(GainSTMHead)]);
  } else {
    src_base = (const uint16_t*)(&p_data[sizeof(GainSTMSubseq)]);
  }

  src = src_base;

  switch (_gain_stm_mode) {
    case GAIN_STM_MODE_INTENSITY_PHASE_FULL:
      bram_cpy_volatile(BRAM_SELECT_STM,
                        (_stm_cycle & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src,
                        TRANS_NUM);
      _stm_cycle = _stm_cycle + 1;
      break;
    case GAIN_STM_MODE_PHASE_FULL:
      bram_cpy_gain_stm_phase_full(
          (_stm_cycle & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src, 0, TRANS_NUM);
      _stm_cycle = _stm_cycle + 1;

      if (send > 1) {
        src = src_base;
        bram_cpy_gain_stm_phase_full(
            (_stm_cycle & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src, 8, TRANS_NUM);
        _stm_cycle = _stm_cycle + 1;
      }
      break;
    case GAIN_STM_MODE_PHASE_HALF:
      bram_cpy_gain_stm_phase_half(
          (_stm_cycle & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src, 0, TRANS_NUM);
      _stm_cycle = _stm_cycle + 1;

      if (send > 1) {
        src = src_base;
        bram_cpy_gain_stm_phase_half(
            (_stm_cycle & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src, 4, TRANS_NUM);
        _stm_cycle = _stm_cycle + 1;
      }

      if (send > 2) {
        src = src_base;
        bram_cpy_gain_stm_phase_half(
            (_stm_cycle & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src, 8, TRANS_NUM);
        _stm_cycle = _stm_cycle + 1;
      }

      if (send > 3) {
        src = src_base;
        bram_cpy_gain_stm_phase_half(
            (_stm_cycle & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src, 12,
            TRANS_NUM);
        _stm_cycle = _stm_cycle + 1;
      }
      break;
    default:
      return ERR_INVALID_GAIN_STM_MODE;
  }

  if ((_stm_cycle & GAIN_STM_BUF_PAGE_SIZE_MASK) == 0)
    change_stm_page((_stm_cycle & ~GAIN_STM_BUF_PAGE_SIZE_MASK) >>
                    GAIN_STM_BUF_PAGE_SIZE_WIDTH);

  if ((p->subseq.flag & GAIN_STM_FLAG_END) == GAIN_STM_FLAG_END) {
    bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_MODE, STM_MODE_GAIN);
    bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_REQ_RD_SEGMENT,
               _stm_segment);
    switch (_stm_segment) {
      case 0:
        bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_CYCLE_0,
                   max(1, _stm_cycle) - 1);
        break;
      case 1:
        bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_CYCLE_1,
                   max(1, _stm_cycle) - 1);
        break;
      default:
        break;
    }

    ret |= REQ_UPDATE_SETTINGS;
  }

  return ret;
}

#ifdef __cplusplus
}
#endif
