// File: stm.h
// Project: op
// Created Date: 31/12/2023
// Author: Shun Suzuki
// -----
// Last Modified: 31/12/2023
// Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
// -----
// Copyright (c) 2023 Shun Suzuki. All rights reserved.
//

#ifndef OP_STM_H_
#define OP_STM_H_

#include "app.h"
#include "params.h"

inline static void change_stm_page(uint16_t page) {
  asm("dmb");
  bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_MEM_PAGE, page);
  asm("dmb");
}

#endif  // OP_STM_H_