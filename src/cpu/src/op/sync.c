#ifdef __cplusplus
extern "C" {
#endif

#include "sync.h"

#include <assert.h>
#include <stddef.h>

#include "app.h"

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t __pad;
} Sync;

uint8_t synchronize(const volatile uint8_t* p_data) {
  volatile uint64_t next_sync0;

  (void)p_data;

  next_sync0 = get_next_sync0();
  bram_cpy_volatile(BRAM_SELECT_CONTROLLER, ADDR_ECAT_SYNC_TIME_0, (volatile uint16_t*)&next_sync0, sizeof(uint64_t) >> 1);
  set_and_wait_update(CTL_FLAG_SYNC_SET);

  return NO_ERR;
}

#ifdef __cplusplus
}
#endif
