// File: force_fan.h
// Project: op
// Created Date: 31/12/2023
// Author: Shun Suzuki
// -----
// Last Modified: 31/12/2023
// Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
// -----
// Copyright (c) 2023 Shun Suzuki. All rights reserved.
//

#ifndef OP_FORCE_FAN_H_
#define OP_FORCE_FAN_H_

#include "app.h"
#include "params.h"

extern volatile uint16_t _fpga_flags_internal;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t value;
} ForceFan;

uint8_t configure_force_fan(const volatile uint8_t* p_data) {
  const ForceFan* p = (const ForceFan*)p_data;
  if (p->value != 0)
    _fpga_flags_internal |= CTL_FLAG_FORCE_FAN_EX;
  else
    _fpga_flags_internal &= ~CTL_FLAG_FORCE_FAN_EX;
  return ERR_NONE;
}

#endif  // OP_FORCE_FAN_H_
