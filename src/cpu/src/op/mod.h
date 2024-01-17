// File: mod.h
// Project: op
// Created Date: 17/01/2024
// Author: Shun Suzuki
// -----
// Last Modified: 17/01/2024
// Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
// -----
// Copyright (c) 2024 Shun Suzuki. All rights reserved.
//

#ifndef OP_MOD_H_
#define OP_MOD_H_

#include "app.h"
#include "params.h"

inline static void change_mod_page(uint16_t page) {
  asm("dmb");
  bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_MOD_MEM_PAGE, page);
  asm("dmb");
}

#endif  // OP_MOD_H_
