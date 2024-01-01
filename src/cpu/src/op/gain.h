// File: gain.h
// Project: op
// Created Date: 31/12/2023
// Author: Shun Suzuki
// -----
// Last Modified: 01/01/2024
// Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
// -----
// Copyright (c) 2023 Shun Suzuki. All rights reserved.
//

#ifndef OP_GAIN_H_
#define OP_GAIN_H_

#include <assert.h>
#include <stddef.h>

#include "app.h"
#include "params.h"

extern volatile uint16_t _fpga_flags_internal;
extern volatile uint32_t _stm_freq_div;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t _pad;
} Gain;

uint8_t write_gain(const volatile uint8_t* p_data) {
  static_assert(sizeof(Gain) == 2, "Gain is not valid.");
  static_assert(offsetof(Gain, tag) == 0, "Gain is not valid.");

  _fpga_flags_internal &= ~CTL_FLAG_OP_MODE;
  bram_cpy_volatile(BRAM_SELECT_NORMAL, 0, (volatile const uint16_t*)(&p_data[sizeof(Gain)]), TRANS_NUM);

  _stm_freq_div = 0xFFFFFFFF;

  return ERR_NONE;
}

#endif  // OP_GAIN_H_
