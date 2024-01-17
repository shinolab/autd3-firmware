// File: clear.h
// Project: op
// Created Date: 31/12/2023
// Author: Shun Suzuki
// -----
// Last Modified: 01/01/2024
// Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
// -----
// Copyright (c) 2023 Shun Suzuki. All rights reserved.
//

#include <assert.h>
#include <stddef.h>

#include "app.h"
#include "mod.h"
#include "params.h"

extern volatile bool_t _read_fpga_info;
extern volatile uint16_t _fpga_flags_internal;

extern volatile uint32_t _mod_cycle;
extern volatile uint32_t _mod_freq_div;

extern volatile uint32_t _stm_cycle;
extern volatile uint32_t _stm_freq_div;

extern volatile bool_t _silencer_strict_mode;
extern volatile uint32_t _min_freq_div_intensity;
extern volatile uint32_t _min_freq_div_phase;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t _pad;
} Clear;

uint8_t clear(void) {
  static_assert(sizeof(Clear) == 2, "Clear is not valid.");
  static_assert(offsetof(Clear, tag) == 0, "Clear is not valid.");

  _mod_freq_div = 5120;
  _stm_freq_div = 0xFFFFFFFF;

  _read_fpga_info = false;

  _fpga_flags_internal = 0;
  bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_CTL_FLAG, _fpga_flags_internal);

  bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_SILENCER_UPDATE_RATE_INTENSITY, 256);
  bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_SILENCER_UPDATE_RATE_PHASE, 256);
  bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_SILENCER_CTL_FLAG, SILENCER_CTL_FLAG_FIXED_COMPLETION_STEPS);
  bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_SILENCER_COMPLETION_STEPS_INTENSITY, 10);
  bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_SILENCER_COMPLETION_STEPS_PHASE, 40);
  _silencer_strict_mode = true;
  _min_freq_div_intensity = 10 << 9;
  _min_freq_div_phase = 40 << 9;

  _stm_cycle = 0;

  _mod_cycle = 2;
  bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_MOD_CYCLE, _mod_cycle - 1);
  bram_cpy(BRAM_SELECT_CONTROLLER, BRAM_ADDR_MOD_FREQ_DIV_0, (uint16_t*)&_mod_freq_div, sizeof(uint32_t) >> 1);
  change_mod_page(0);
  bram_write(BRAM_SELECT_MOD, 0, 0xFFFF);

  bram_set(BRAM_SELECT_NORMAL, 0, 0x0000, TRANS_NUM << 1);

  bram_set(BRAM_SELECT_CONTROLLER, BRAM_ADDR_MOD_DELAY_BASE, 0x0000, TRANS_NUM);

  bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_DEBUG_OUT_IDX, 0xFF);

  return ERR_NONE;
}
