// File: mod_delay.h
// Project: op
// Created Date: 31/12/2023
// Author: Shun Suzuki
// -----
// Last Modified: 31/12/2023
// Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
// -----
// Copyright (c) 2023 Shun Suzuki. All rights reserved.
//

#ifndef OP_MOD_DELAY_H_
#define OP_MOD_DELAY_H_

#include "app.h"
#include "params.h"

typedef ALIGN2 struct {
  uint8_t tag;
} ModDelay;

uint8_t write_mod_delay(const volatile uint8_t* p_data) {
  const uint16_t* delay = (const uint16_t*)(&p_data[sizeof(ModDelay)]);
  bram_cpy_volatile(BRAM_SELECT_CONTROLLER, BRAM_ADDR_MOD_DELAY_BASE, delay, TRANS_NUM);
  return ERR_NONE;
}

#endif  // OP_MOD_DELAY_H_
