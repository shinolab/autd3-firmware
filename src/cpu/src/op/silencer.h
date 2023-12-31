// File: silencer.h
// Project: op
// Created Date: 31/12/2023
// Author: Shun Suzuki
// -----
// Last Modified: 31/12/2023
// Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
// -----
// Copyright (c) 2023 Shun Suzuki. All rights reserved.
//

#ifndef OP_SILENCER_H_
#define OP_SILENCER_H_

#include "app.h"
#include "params.h"

extern volatile uint32_t _mod_freq_div;
extern volatile uint32_t _stm_freq_div;
extern volatile bool_t _silencer_strict_mode;
extern volatile uint32_t _min_freq_div_intensity;
extern volatile uint32_t _min_freq_div_phase;

typedef ALIGN2 struct {
  uint8_t tag;
  uint16_t value_intensity;
  uint16_t value_phase;
  uint16_t flag;
} ConfigSilencer;

uint8_t config_silencer(const volatile uint8_t* p_data) {
  const ConfigSilencer* p = (const ConfigSilencer*)p_data;
  const uint16_t value_intensity = p->value_intensity;
  const uint16_t value_phase = p->value_phase;
  const uint16_t flags = p->flag;

  if ((flags & SILENCER_CTL_FLAG_FIXED_COMPLETION_STEPS) != 0) {
    _silencer_strict_mode = (flags & SILENCER_CTL_FLAG_STRICT_MODE) != 0;
    _min_freq_div_intensity = (uint32_t)value_intensity << 9;
    _min_freq_div_phase = (uint32_t)value_phase << 9;
    if (_silencer_strict_mode) {
      if (_mod_freq_div < _min_freq_div_intensity) return ERR_COMPLETION_STEPS_TOO_LARGE;
      if ((_stm_freq_div < _min_freq_div_intensity) || (_stm_freq_div < _min_freq_div_phase)) return ERR_COMPLETION_STEPS_TOO_LARGE;
    }
    bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_SILENCER_COMPLETION_STEPS_INTENSITY, value_intensity);
    bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_SILENCER_COMPLETION_STEPS_PHASE, value_phase);
  } else {
    bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_SILENCER_UPDATE_RATE_INTENSITY, value_intensity);
    bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_SILENCER_UPDATE_RATE_PHASE, value_phase);
    _silencer_strict_mode = false;
  }
  bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_SILENCER_CTL_FLAG, flags);

  return ERR_NONE;
}

#endif  // OP_SILENCER_H_
