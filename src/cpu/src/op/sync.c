#include "app.h"
#include "iodefine.h"
#include "params.h"

extern volatile uint16_t _fpga_flags_internal;

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
  bram_cpy_volatile(BRAM_SELECT_CONTROLLER, BRAM_ADDR_ECAT_SYNC_TIME_0,
                    (volatile uint16_t*)&next_sync0, sizeof(uint64_t) >> 1);
  set_and_wait_update(CTL_FLAG_SYNC_SET);

  return NO_ERR;
}
