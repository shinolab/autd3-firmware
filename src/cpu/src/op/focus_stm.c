#ifdef __cplusplus
extern "C" {
#endif

#include <assert.h>
#include <stddef.h>

#include "app.h"
#include "params.h"
#include "stm.h"
#include "utils.h"

#define FOCUS_STM_BUF_PAGE_SIZE_WIDTH (12)
#define FOCUS_STM_BUF_PAGE_SIZE (1 << FOCUS_STM_BUF_PAGE_SIZE_WIDTH)
#define FOCUS_STM_BUF_PAGE_SIZE_MASK (FOCUS_STM_BUF_PAGE_SIZE - 1)

extern volatile uint8_t _stm_segment;
extern volatile uint8_t _stm_mode[2];
extern volatile uint32_t _stm_cycle[2];
extern volatile uint32_t _stm_freq_div[2];

extern volatile bool_t _silencer_strict_mode;
extern volatile uint32_t _min_freq_div_intensity;
extern volatile uint32_t _min_freq_div_phase;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
  uint8_t send_num;
  uint8_t segment;
  uint32_t freq_div;
  uint32_t sound_speed;
  uint32_t rep;
} FocusSTMHead;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
  uint8_t send_num;
  uint8_t _pad;
} FocusSTMSubseq;

typedef union {
  FocusSTMHead head;
  FocusSTMSubseq subseq;
} FocusSTM;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t segment;
} FocusSTMUpdate;

uint8_t write_focus_stm(const volatile uint8_t* p_data) {
  static_assert(sizeof(FocusSTMHead) == 16, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMHead, tag) == 0, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMHead, flag) == 1, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMHead, send_num) == 2,
                "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMHead, segment) == 3, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMHead, freq_div) == 4,
                "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMHead, sound_speed) == 8,
                "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMHead, rep) == 12, "FocusSTM is not valid.");
  static_assert(sizeof(FocusSTMSubseq) == 4, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMSubseq, tag) == 0, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMSubseq, flag) == 1, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMSubseq, send_num) == 2,
                "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTM, head) == 0, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTM, subseq) == 0, "FocusSTM is not valid.");

  const FocusSTM* p = (const FocusSTM*)p_data;

  volatile uint16_t size = p->subseq.send_num;

  const uint16_t* src;
  uint32_t freq_div;
  uint32_t sound_speed;
  uint32_t rep;
  uint8_t segment;
  volatile uint32_t page_capacity;

  if ((p->subseq.flag & FOCUS_STM_FLAG_BEGIN) == FOCUS_STM_FLAG_BEGIN) {
    freq_div = p->head.freq_div;
    sound_speed = p->head.sound_speed;
    rep = p->head.rep;
    segment = p->head.segment;

    _stm_cycle[segment] = 0;

    if (_silencer_strict_mode) {
      if ((freq_div < _min_freq_div_intensity) ||
          (freq_div < _min_freq_div_phase))
        return ERR_FREQ_DIV_TOO_SMALL;
    }
    _stm_freq_div[segment] = freq_div;

    switch (segment) {
      case 0:
        bram_cpy(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FREQ_DIV_0_0,
                 (uint16_t*)&freq_div, sizeof(uint32_t) >> 1);
        bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_MODE_0,
                   STM_MODE_FOCUS);
        bram_cpy(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_SOUND_SPEED_0_0,
                 (uint16_t*)&sound_speed, sizeof(uint32_t) >> 1);
        bram_cpy(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_REP_0_0, (uint16_t*)&rep,
                 sizeof(uint32_t) >> 1);
        break;
      case 1:
        bram_cpy(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FREQ_DIV_1_0,
                 (uint16_t*)&freq_div, sizeof(uint32_t) >> 1);
        bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_MODE_1,
                   STM_MODE_FOCUS);
        bram_cpy(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_SOUND_SPEED_1_0,
                 (uint16_t*)&sound_speed, sizeof(uint32_t) >> 1);
        bram_cpy(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_REP_1_0, (uint16_t*)&rep,
                 sizeof(uint32_t) >> 1);
        break;
      default:
        return ERR_INVALID_SEGMENT;
    }
    _stm_segment = segment;

    change_stm_wr_segment(segment);
    change_stm_wr_page(0);

    src = (const uint16_t*)(&p_data[sizeof(FocusSTMHead)]);
  } else {
    src = (const uint16_t*)(&p_data[sizeof(FocusSTMSubseq)]);
  }

  page_capacity = (_stm_cycle[_stm_segment] & ~FOCUS_STM_BUF_PAGE_SIZE_MASK) +
                  FOCUS_STM_BUF_PAGE_SIZE - _stm_cycle[_stm_segment];
  if (size < page_capacity) {
    bram_cpy_focus_stm(
        (_stm_cycle[_stm_segment] & FOCUS_STM_BUF_PAGE_SIZE_MASK) << 2, src,
        size);
    _stm_cycle[_stm_segment] = _stm_cycle[_stm_segment] + size;
  } else {
    bram_cpy_focus_stm(
        (_stm_cycle[_stm_segment] & FOCUS_STM_BUF_PAGE_SIZE_MASK) << 2, src,
        page_capacity);
    _stm_cycle[_stm_segment] = _stm_cycle[_stm_segment] + page_capacity;

    change_stm_wr_page(
        (_stm_cycle[_stm_segment] & ~FOCUS_STM_BUF_PAGE_SIZE_MASK) >>
        FOCUS_STM_BUF_PAGE_SIZE_WIDTH);

    bram_cpy_focus_stm((_stm_cycle[_stm_segment] & FOCUS_STM_BUF_PAGE_SIZE_MASK)
                           << 2,
                       src + 4 * page_capacity, size - page_capacity);
    _stm_cycle[_stm_segment] = _stm_cycle[_stm_segment] + size - page_capacity;
  }

  if ((p->subseq.flag & FOCUS_STM_FLAG_END) == FOCUS_STM_FLAG_END) {
    _stm_mode[_stm_segment] = STM_MODE_FOCUS;
    switch (_stm_segment) {
      case 0:
        bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_CYCLE_0,
                   max(1, _stm_cycle[_stm_segment]) - 1);
        break;
      case 1:
        bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_CYCLE_1,
                   max(1, _stm_cycle[_stm_segment]) - 1);
        break;
      default:  // LCOV_EXCL_LINE
        break;  // LCOV_EXCL_LINE
    }

    if ((p->subseq.flag & FOCUS_STM_FLAG_UPDATE) != 0) {
      bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_REQ_RD_SEGMENT,
                 _stm_segment);
      set_and_wait_update(CTL_FLAG_STM_SET);
    }
  }

  return NO_ERR;
}

uint8_t change_focus_stm_segment(const volatile uint8_t* p_data) {
  static_assert(sizeof(FocusSTMUpdate) == 2, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMUpdate, tag) == 0, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMUpdate, segment) == 1,
                "FocusSTM is not valid.");

  const FocusSTMUpdate* p = (const FocusSTMUpdate*)p_data;

  if (_stm_mode[p->segment] != STM_MODE_FOCUS || _stm_cycle[p->segment] == 1)
    return ERR_INVALID_SEGMENT_TRANSITION;

  bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_REQ_RD_SEGMENT, p->segment);
  set_and_wait_update(CTL_FLAG_STM_SET);

  return NO_ERR;
}

#ifdef __cplusplus
}
#endif
