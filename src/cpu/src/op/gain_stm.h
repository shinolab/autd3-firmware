// File: gain_stm.h
// Project: op
// Created Date: 31/12/2023
// Author: Shun Suzuki
// -----
// Last Modified: 31/12/2023
// Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
// -----
// Copyright (c) 2023 Shun Suzuki. All rights reserved.
//

#ifndef OP_GAIN_STM_H_
#define OP_GAIN_STM_H_

#include "app.h"
#include "params.h"
#include "stm.h"
#include "utils.h"

#define GAIN_STM_BUF_PAGE_SIZE_WIDTH (6)
#define GAIN_STM_BUF_PAGE_SIZE (1 << GAIN_STM_BUF_PAGE_SIZE_WIDTH)
#define GAIN_STM_BUF_PAGE_SIZE_MASK (GAIN_STM_BUF_PAGE_SIZE - 1)

extern volatile uint16_t _fpga_flags_internal;

extern volatile uint32_t _stm_cycle;
extern volatile uint32_t _stm_freq_div;
extern volatile uint16_t _gain_stm_mode;

extern volatile bool_t _silencer_strict_mode;
extern volatile uint32_t _min_freq_div_intensity;
extern volatile uint32_t _min_freq_div_phase;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
  uint16_t mode;
  uint32_t freq_div;
  uint16_t start_idx;
  uint16_t finish_idx;
} GainSTMHead;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
} GainSTMSubseq;

typedef union {
  GainSTMHead head;
  GainSTMSubseq subseq;
} GainSTM;

static uint8_t write_gain_stm(const volatile uint8_t* p_data) {
  const GainSTM* p = (const GainSTM*)p_data;

  uint8_t send = (p->subseq.flag >> 6) + 1;

  const volatile uint16_t *src, *src_base;
  uint32_t freq_div;
  uint16_t start_idx;
  uint16_t finish_idx;

  if ((p->subseq.flag & GAIN_STM_FLAG_BEGIN) == GAIN_STM_FLAG_BEGIN) {
    _stm_cycle = 0;
    change_stm_page(0);

    _gain_stm_mode = p->head.mode;

    freq_div = p->head.freq_div;
    if (_silencer_strict_mode) {
      if ((freq_div < _min_freq_div_intensity) || (freq_div < _min_freq_div_phase)) return ERR_FREQ_DIV_TOO_SMALL;
    }
    _stm_freq_div = freq_div;
    bram_cpy(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FREQ_DIV_0, (uint16_t*)&freq_div, sizeof(uint32_t) >> 1);

    start_idx = p->head.start_idx;
    finish_idx = p->head.finish_idx;
    bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_START_IDX, start_idx);
    bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FINISH_IDX, finish_idx);

    if ((p->head.flag & GAIN_STM_FLAG_USE_START_IDX) == GAIN_STM_FLAG_USE_START_IDX) {
      _fpga_flags_internal |= CTL_FLAG_USE_STM_START_IDX;
    } else {
      _fpga_flags_internal &= ~CTL_FLAG_USE_STM_START_IDX;
    }
    if ((p->head.flag & GAIN_STM_FLAG_USE_FINISH_IDX) == GAIN_STM_FLAG_USE_FINISH_IDX) {
      _fpga_flags_internal |= CTL_FLAG_USE_STM_FINISH_IDX;
    } else {
      _fpga_flags_internal &= ~CTL_FLAG_USE_STM_FINISH_IDX;
    }

    src_base = (const uint16_t*)(&p_data[sizeof(GainSTMHead)]);
  } else {
    src_base = (const uint16_t*)(&p_data[sizeof(GainSTMSubseq)]);
  }

  src = src_base;

  switch (_gain_stm_mode) {
    case GAIN_STM_MODE_INTENSITY_PHASE_FULL:
      bram_cpy_volatile(BRAM_SELECT_STM, (_stm_cycle & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src, TRANS_NUM);
      _stm_cycle = _stm_cycle + 1;
      break;
    case GAIN_STM_MODE_PHASE_FULL:
      bram_cpy_gain_stm_phase_full((_stm_cycle & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src, 0, TRANS_NUM);
      _stm_cycle = _stm_cycle + 1;

      if (send > 1) {
        src = src_base;
        bram_cpy_gain_stm_phase_full((_stm_cycle & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src, 8, TRANS_NUM);
        _stm_cycle = _stm_cycle + 1;
      }
      break;
    case GAIN_STM_MODE_PHASE_HALF:
      bram_cpy_gain_stm_phase_half((_stm_cycle & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src, 0, TRANS_NUM);
      _stm_cycle = _stm_cycle + 1;

      if (send > 1) {
        src = src_base;
        bram_cpy_gain_stm_phase_half((_stm_cycle & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src, 4, TRANS_NUM);
        _stm_cycle = _stm_cycle + 1;
      }

      if (send > 2) {
        src = src_base;
        bram_cpy_gain_stm_phase_half((_stm_cycle & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src, 8, TRANS_NUM);
        _stm_cycle = _stm_cycle + 1;
      }

      if (send > 3) {
        src = src_base;
        bram_cpy_gain_stm_phase_half((_stm_cycle & GAIN_STM_BUF_PAGE_SIZE_MASK) << 8, src, 12, TRANS_NUM);
        _stm_cycle = _stm_cycle + 1;
      }
      break;
    default:
      break;
  }

  if ((_stm_cycle & GAIN_STM_BUF_PAGE_SIZE_MASK) == 0) change_stm_page((_stm_cycle & ~GAIN_STM_BUF_PAGE_SIZE_MASK) >> GAIN_STM_BUF_PAGE_SIZE_WIDTH);

  if ((p->subseq.flag & GAIN_STM_FLAG_END) == GAIN_STM_FLAG_END) {
    _fpga_flags_internal |= CTL_FLAG_OP_MODE;
    _fpga_flags_internal |= CTL_FLAG_STM_GAIN_MODE;
    bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_CYCLE, max(1, _stm_cycle) - 1);
  }

  return ERR_NONE;
}

#endif  // OP_GAIN_STM_H_
