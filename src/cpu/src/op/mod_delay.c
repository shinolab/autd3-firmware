// File: mod_delay.h
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

#include <assert.h>
#include <stddef.h>

#include "app.h"
#include "params.h"

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t _pad;
} ModDelay;

uint8_t write_mod_delay(const volatile uint8_t* p_data) {
  static_assert(sizeof(ModDelay) == 2, "ModDelay is not valid.");
  static_assert(offsetof(ModDelay, tag) == 0, "ModDelay is not valid.");

  const uint16_t* delay = (const uint16_t*)(&p_data[sizeof(ModDelay)]);
  bram_cpy_volatile(BRAM_SELECT_CONTROLLER, BRAM_ADDR_MOD_DELAY_BASE, delay, TRANS_NUM);
  return ERR_NONE;
}

#ifdef __cplusplus
}
#endif
