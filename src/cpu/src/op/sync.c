/*
 * File: sync.c
 * Project: op
 * Created Date: 17/01/2024
 * Author: Shun Suzuki
 * -----
 * Last Modified: 17/01/2024
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2024 Shun Suzuki. All rights reserved.
 *
 */

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
