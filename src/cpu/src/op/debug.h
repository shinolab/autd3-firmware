// File: debug.h
// Project: op
// Created Date: 31/12/2023
// Author: Shun Suzuki
// -----
// Last Modified: 31/12/2023
// Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
// -----
// Copyright (c) 2023 Shun Suzuki. All rights reserved.
//

#ifndef OP_DEBUG_H_
#define OP_DEBUG_H_

#include "app.h"
#include "params.h"

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t idx;
} DebugOutIdx;

uint8_t configure_debug(const volatile uint8_t* p_data) {
  const DebugOutIdx* p = (const DebugOutIdx*)p_data;
  uint8_t idx = p->idx;
  bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_DEBUG_OUT_IDX, idx);
  return ERR_NONE;
}

#endif  // OP_DEBUG_H_
