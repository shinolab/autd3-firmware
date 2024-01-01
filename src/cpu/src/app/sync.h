// File: sync.h
// Project: app
// Created Date: 31/12/2023
// Author: Shun Suzuki
// -----
// Last Modified: 31/12/2023
// Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
// -----
// Copyright (c) 2023 Shun Suzuki. All rights reserved.
//

#ifndef OP_SYNC_H_
#define OP_SYNC_H_

#include "app.h"
#include "params.h"

inline static uint64_t get_next_sync0() {
  volatile uint64_t next_sync0 = ECATC.DC_CYC_START_TIME.LONGLONG;
  volatile uint64_t sys_time = ECATC.DC_SYS_TIME.LONGLONG;
  while (next_sync0 < sys_time + 250000) {
    sys_time = ECATC.DC_SYS_TIME.LONGLONG;
    if (sys_time > next_sync0) next_sync0 = ECATC.DC_CYC_START_TIME.LONGLONG;
  }
  return next_sync0;
}

uint8_t synchronize(void) {
  volatile uint64_t next_sync0;
  volatile uint16_t flag;

  next_sync0 = get_next_sync0();
  bram_cpy_volatile(BRAM_SELECT_CONTROLLER, BRAM_ADDR_EC_SYNC_TIME_0, (volatile uint16_t*)&next_sync0, sizeof(uint64_t) >> 1);
  bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_CTL_FLAG, _fpga_flags_internal | CTL_FLAG_SYNC);

  while (true) {
    flag = bram_read(BRAM_SELECT_CONTROLLER, BRAM_ADDR_CTL_FLAG);
    if ((flag & CTL_FLAG_SYNC) == 0) break;
  }

  return ERR_NONE;
}

#endif  // OP_SYNC_H_
