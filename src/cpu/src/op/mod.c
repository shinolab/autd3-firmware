// File: mod.h
// Project: op
// Created Date: 31/12/2023
// Author: Shun Suzuki
// -----
// Last Modified: 01/01/2024
// Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
// -----
// Copyright (c) 2023 Shun Suzuki. All rights reserved.
//

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

extern volatile bool_t _silencer_strict_mode;
extern volatile uint32_t _min_freq_div_intensity;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
  uint16_t size;
  uint32_t freq_div;
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

uint8_t write_mod(const volatile uint8_t* p_data) {
  static_assert(sizeof(ModulationHead) == 8, "Modulation is not valid.");
  static_assert(offsetof(ModulationHead, tag) == 0, "Modulation is not valid.");
  static_assert(offsetof(ModulationHead, flag) == 1, "Modulation is not valid.");
  static_assert(offsetof(ModulationHead, size) == 2, "Modulation is not valid.");
  static_assert(offsetof(ModulationHead, freq_div) == 4, "Modulation is not valid.");
  static_assert(sizeof(ModulationSubseq) == 4, "Modulation is not valid.");
  static_assert(offsetof(ModulationSubseq, tag) == 0, "Modulation is not valid.");
  static_assert(offsetof(ModulationSubseq, flag) == 1, "Modulation is not valid.");
  static_assert(offsetof(ModulationSubseq, size) == 2, "Modulation is not valid.");
  static_assert(offsetof(Modulation, head) == 0, "Modulation is not valid.");
  static_assert(offsetof(Modulation, subseq) == 0, "Modulation is not valid.");

  const Modulation* p = (const Modulation*)p_data;

  volatile uint32_t page_capacity;
  uint32_t freq_div;

  volatile uint16_t write = p->subseq.size;

  const uint16_t* data;
  if ((p->subseq.flag & MODULATION_FLAG_BEGIN) == MODULATION_FLAG_BEGIN) {
    _mod_cycle = 0;
    change_mod_page(0);
    freq_div = p->head.freq_div;
    if (_silencer_strict_mode & (freq_div < _min_freq_div_intensity)) return ERR_FREQ_DIV_TOO_SMALL;
    _mod_freq_div = freq_div;

    bram_cpy(BRAM_SELECT_CONTROLLER, BRAM_ADDR_MOD_FREQ_DIV_0, (uint16_t*)&freq_div, sizeof(uint32_t) >> 1);
    data = (const uint16_t*)(&p_data[sizeof(ModulationHead)]);
  } else {
    data = (const uint16_t*)(&p_data[sizeof(ModulationSubseq)]);
  }

  page_capacity = (_mod_cycle & ~MOD_BUF_PAGE_SIZE_MASK) + MOD_BUF_PAGE_SIZE - _mod_cycle;
  if (write < page_capacity) {
    bram_cpy(BRAM_SELECT_MOD, (_mod_cycle & MOD_BUF_PAGE_SIZE_MASK) >> 1, data, (write + 1) >> 1);
    _mod_cycle = _mod_cycle + write;
  } else {
    bram_cpy(BRAM_SELECT_MOD, (_mod_cycle & MOD_BUF_PAGE_SIZE_MASK) >> 1, data, page_capacity >> 1);
    _mod_cycle = _mod_cycle + page_capacity;
    data += (page_capacity >> 1);
    change_mod_page((_mod_cycle & ~MOD_BUF_PAGE_SIZE_MASK) >> MOD_BUF_PAGE_SIZE_WIDTH);
    bram_cpy(BRAM_SELECT_MOD, (_mod_cycle & MOD_BUF_PAGE_SIZE_MASK) >> 1, data, (write - page_capacity + 1) >> 1);
    _mod_cycle = _mod_cycle + write - page_capacity;
  }

  if ((p->subseq.flag & MODULATION_FLAG_END) == MODULATION_FLAG_END) {
    bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_MOD_CYCLE, max(1, _mod_cycle) - 1);
  }

  return ERR_NONE;
}

#ifdef __cplusplus
}
#endif
