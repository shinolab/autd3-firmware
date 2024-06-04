#ifdef __cplusplus
extern "C" {
#endif

#include "foci_stm.h"

#include <assert.h>
#include <stddef.h>

#include "app.h"
#include "params.h"
#include "silencer.h"
#include "stm.h"
#include "utils.h"
#include "validate.h"

#define FOCUS_STM_BUF_PAGE_SIZE_WIDTH (9)
#define FOCUS_STM_BUF_PAGE_SIZE (1 << FOCUS_STM_BUF_PAGE_SIZE_WIDTH)
#define FOCUS_STM_BUF_PAGE_SIZE_MASK (FOCUS_STM_BUF_PAGE_SIZE - 1)

extern volatile uint8_t _stm_segment;
extern volatile uint8_t _stm_transition_mode;
extern volatile uint64_t _stm_transition_value;
extern volatile uint8_t _stm_mode[2];
extern volatile uint32_t _stm_cycle[2];
extern volatile uint32_t _stm_rep[2];
extern volatile uint32_t _stm_freq_div[2];

extern volatile bool_t _silencer_strict_mode;
extern volatile uint32_t _min_freq_div_intensity;
extern volatile uint32_t _min_freq_div_phase;
extern volatile uint8_t _mod_segment;
extern volatile uint32_t _mod_freq_div[2];

volatile static uint8_t _num_foci;

uint8_t write_foci_stm(const volatile uint8_t* p_data) {
  static_assert(sizeof(FocusSTMHead) == 24, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMHead, tag) == 0, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMHead, flag) == 1, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMHead, send_num) == 2, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMHead, segment) == 3, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMHead, transition_mode) == 4, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMHead, num_foci) == 5, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMHead, sound_speed) == 6, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMHead, freq_div) == 8, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMHead, rep) == 12, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMHead, transition_value) == 16, "FocusSTM is not valid.");
  static_assert(sizeof(FocusSTMSubseq) == 4, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMSubseq, tag) == 0, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMSubseq, flag) == 1, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMSubseq, send_num) == 2, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTM, head) == 0, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTM, subseq) == 0, "FocusSTM is not valid.");

  const FocusSTM* p = (const FocusSTM*)p_data;

  volatile uint16_t size = p->subseq.send_num;

  const uint16_t* src;
  volatile uint32_t page_capacity;
  const uint8_t segment = p->head.segment;

  if ((p->subseq.flag & FOCUS_STM_FLAG_BEGIN) == FOCUS_STM_FLAG_BEGIN) {
    if (validate_transition_mode(_stm_segment, segment, p->head.rep, p->head.transition_mode)) return ERR_INVALID_TRANSITION_MODE;
    if (validate_silencer_settings(_silencer_strict_mode, _min_freq_div_intensity, _min_freq_div_phase, p->head.freq_div,
                                   _mod_freq_div[_mod_segment]))
      return ERR_INVALID_SILENCER_SETTING;

    if (p->head.transition_mode != TRANSITION_MODE_NONE) _stm_segment = segment;
    _stm_cycle[segment] = 0;
    _stm_rep[segment] = p->head.rep;
    _stm_transition_mode = p->head.transition_mode;
    _stm_transition_value = p->head.transition_value;
    _stm_freq_div[segment] = p->head.freq_div;
    _num_foci = p->head.num_foci;

    switch (segment) {
      case 0:
        bram_cpy(BRAM_SELECT_CONTROLLER, ADDR_STM_FREQ_DIV0_0, (uint16_t*)&_stm_freq_div[segment], sizeof(uint32_t) >> 1);
        bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_MODE0, STM_MODE_FOCUS);
        bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_SOUND_SPEED0, p->head.sound_speed);
        bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_NUM_FOCI0, _num_foci);
        bram_cpy(BRAM_SELECT_CONTROLLER, ADDR_STM_REP0_0, (uint16_t*)&p->head.rep, sizeof(uint32_t) >> 1);
        break;
      case 1:
        bram_cpy(BRAM_SELECT_CONTROLLER, ADDR_STM_FREQ_DIV1_0, (uint16_t*)&_stm_freq_div[segment], sizeof(uint32_t) >> 1);
        bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_MODE1, STM_MODE_FOCUS);
        bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_SOUND_SPEED1, p->head.sound_speed);
        bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_NUM_FOCI1, _num_foci);
        bram_cpy(BRAM_SELECT_CONTROLLER, ADDR_STM_REP1_0, (uint16_t*)&p->head.rep, sizeof(uint32_t) >> 1);
        break;
      default:  // LCOV_EXCL_LINE
        break;  // LCOV_EXCL_LINE
    }

    change_stm_wr_segment(segment);
    change_stm_wr_page(0);

    src = (const uint16_t*)(&p_data[sizeof(FocusSTMHead)]);
  } else {
    src = (const uint16_t*)(&p_data[sizeof(FocusSTMSubseq)]);
  }

  page_capacity = (_stm_cycle[segment] & ~FOCUS_STM_BUF_PAGE_SIZE_MASK) + FOCUS_STM_BUF_PAGE_SIZE - _stm_cycle[segment];
  if (size <= page_capacity) {
    bram_cpy_focus_stm((_stm_cycle[segment] & FOCUS_STM_BUF_PAGE_SIZE_MASK) << 5, src, size, _num_foci);
    _stm_cycle[segment] = _stm_cycle[segment] + size;
  } else {
    bram_cpy_focus_stm((_stm_cycle[segment] & FOCUS_STM_BUF_PAGE_SIZE_MASK) << 5, src, page_capacity, _num_foci);
    _stm_cycle[segment] = _stm_cycle[segment] + page_capacity;

    change_stm_wr_page((_stm_cycle[segment] & ~FOCUS_STM_BUF_PAGE_SIZE_MASK) >> FOCUS_STM_BUF_PAGE_SIZE_WIDTH);

    bram_cpy_focus_stm((_stm_cycle[segment] & FOCUS_STM_BUF_PAGE_SIZE_MASK) << 5, src + 4 * page_capacity * _num_foci, size - page_capacity,
                       _num_foci);
    _stm_cycle[segment] = _stm_cycle[segment] + size - page_capacity;
  }

  if ((p->subseq.flag & FOCUS_STM_FLAG_END) == FOCUS_STM_FLAG_END) {
    _stm_mode[segment] = STM_MODE_FOCUS;
    switch (segment) {
      case 0:
        bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_CYCLE0, max(1, _stm_cycle[segment]) - 1);
        break;
      case 1:
        bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_CYCLE1, max(1, _stm_cycle[segment]) - 1);
        break;
      default:  // LCOV_EXCL_LINE
        break;  // LCOV_EXCL_LINE
    }

    if ((p->subseq.flag & FOCUS_STM_FLAG_UPDATE) != 0) return stm_segment_update(segment, _stm_transition_mode, _stm_transition_value);
  }

  return NO_ERR;
}

uint8_t change_foci_stm_segment(const volatile uint8_t* p_data) {
  static_assert(sizeof(FocusSTMUpdate) == 16, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMUpdate, tag) == 0, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMUpdate, segment) == 1, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMUpdate, transition_mode) == 2, "FocusSTM is not valid.");
  static_assert(offsetof(FocusSTMUpdate, transition_value) == 8, "FocusSTM is not valid.");

  const FocusSTMUpdate* p = (const FocusSTMUpdate*)p_data;

  if (_stm_mode[p->segment] != STM_MODE_FOCUS) return ERR_INVALID_SEGMENT_TRANSITION;

  if (validate_transition_mode(_stm_segment, p->segment, _stm_rep[p->segment], p->transition_mode)) return ERR_INVALID_TRANSITION_MODE;

  if (validate_silencer_settings(_silencer_strict_mode, _min_freq_div_intensity, _min_freq_div_phase, _stm_freq_div[p->segment],
                                 _mod_freq_div[_mod_segment]))
    return ERR_INVALID_SILENCER_SETTING;

  _stm_segment = p->segment;
  return stm_segment_update(p->segment, p->transition_mode, p->transition_value);
}

#ifdef __cplusplus
}
#endif
