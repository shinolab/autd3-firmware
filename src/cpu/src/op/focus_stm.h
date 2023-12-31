// File: focus_stm.h
// Project: op
// Created Date: 31/12/2023
// Author: Shun Suzuki
// -----
// Last Modified: 31/12/2023
// Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
// -----
// Copyright (c) 2023 Shun Suzuki. All rights reserved.
//

#ifndef OP_FOCUS_STM_H_
#define OP_FOCUS_STM_H_

#include "app.h"
#include "params.h"
#include "stm.h"
#include "utils.h"

#define FOCUS_STM_BUF_PAGE_SIZE_WIDTH (11)
#define FOCUS_STM_BUF_PAGE_SIZE (1 << FOCUS_STM_BUF_PAGE_SIZE_WIDTH)
#define FOCUS_STM_BUF_PAGE_SIZE_MASK (FOCUS_STM_BUF_PAGE_SIZE - 1)

extern volatile uint16_t _fpga_flags_internal;

extern volatile uint32_t _stm_cycle;
extern volatile uint32_t _stm_freq_div;

extern volatile bool_t _silencer_strict_mode;
extern volatile uint32_t _min_freq_div_intensity;
extern volatile uint32_t _min_freq_div_phase;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
  uint16_t send_num;
  uint32_t freq_div;
  uint32_t sound_speed;
  uint16_t start_idx;
  uint16_t finish_idx;
} FocusSTMHead;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
  uint16_t send_num;
} FocusSTMSubseq;

typedef union {
  FocusSTMHead head;
  FocusSTMSubseq subseq;
} FocusSTM;

static uint8_t write_focus_stm(const volatile uint8_t* p_data) {
  const FocusSTM* p = (const FocusSTM*)p_data;

  volatile uint16_t size = p->subseq.send_num;

  const uint16_t* src;
  uint32_t freq_div;
  uint32_t sound_speed;
  uint16_t start_idx;
  uint16_t finish_idx;
  uint32_t cnt;
  volatile uint32_t page_capacity;

  if ((p->subseq.flag & FOCUS_STM_FLAG_BEGIN) == FOCUS_STM_FLAG_BEGIN) {
    _stm_cycle = 0;
    change_stm_page(0);

    freq_div = p->head.freq_div;
    sound_speed = p->head.sound_speed;
    start_idx = p->head.start_idx;
    finish_idx = p->head.finish_idx;

    if (_silencer_strict_mode) {
      if ((freq_div < _min_freq_div_intensity) || (freq_div < _min_freq_div_phase)) return ERR_FREQ_DIV_TOO_SMALL;
    }
    _stm_freq_div = freq_div;

    bram_cpy(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FREQ_DIV_0, (uint16_t*)&freq_div, sizeof(uint32_t) >> 1);
    bram_cpy(BRAM_SELECT_CONTROLLER, BRAM_ADDR_SOUND_SPEED_0, (uint16_t*)&sound_speed, sizeof(uint32_t) >> 1);
    bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_START_IDX, start_idx);
    bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FINISH_IDX, finish_idx);

    if ((p->head.flag & FOCUS_STM_FLAG_USE_START_IDX) == FOCUS_STM_FLAG_USE_START_IDX) {
      _fpga_flags_internal |= CTL_FLAG_USE_STM_START_IDX;
    } else {
      _fpga_flags_internal &= ~CTL_FLAG_USE_STM_START_IDX;
    }
    if ((p->head.flag & FOCUS_STM_FLAG_USE_FINISH_IDX) == FOCUS_STM_FLAG_USE_FINISH_IDX) {
      _fpga_flags_internal |= CTL_FLAG_USE_STM_FINISH_IDX;
    } else {
      _fpga_flags_internal &= ~CTL_FLAG_USE_STM_FINISH_IDX;
    }

    src = (const uint16_t*)(&p_data[sizeof(FocusSTMHead)]);
  } else {
    src = (const uint16_t*)(&p_data[sizeof(FocusSTMSubseq)]);
  }

  page_capacity = (_stm_cycle & ~FOCUS_STM_BUF_PAGE_SIZE_MASK) + FOCUS_STM_BUF_PAGE_SIZE - _stm_cycle;
  if (size < page_capacity) {
    bram_cpy_focus_stm((_stm_cycle & FOCUS_STM_BUF_PAGE_SIZE_MASK) << 3, src, size);
    _stm_cycle = _stm_cycle + size;
  } else {
    bram_cpy_focus_stm((_stm_cycle & FOCUS_STM_BUF_PAGE_SIZE_MASK) << 3, src, page_capacity);
    _stm_cycle = _stm_cycle + page_capacity;

    change_stm_page((_stm_cycle & ~FOCUS_STM_BUF_PAGE_SIZE_MASK) >> FOCUS_STM_BUF_PAGE_SIZE_WIDTH);

    bram_cpy_focus_stm((_stm_cycle & FOCUS_STM_BUF_PAGE_SIZE_MASK) << 3, src + 4 * page_capacity, size - page_capacity);
    _stm_cycle = _stm_cycle + size - page_capacity;
  }

  if ((p->subseq.flag & FOCUS_STM_FLAG_END) == FOCUS_STM_FLAG_END) {
    _fpga_flags_internal |= CTL_FLAG_OP_MODE;
    _fpga_flags_internal &= ~CTL_FLAG_STM_GAIN_MODE;
    bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_CYCLE, max(1, _stm_cycle) - 1);
  }

  return ERR_NONE;
}

#endif  // OP_FOCUS_STM_H_
