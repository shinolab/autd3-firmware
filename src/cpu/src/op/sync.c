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
  uint16_t ufreq_mult;
  uint16_t base_cnt;
} Sync;

uint8_t synchronize(const volatile uint8_t* p_data) {
  static_assert(sizeof(Sync) == 6, "Sync is not valid.");
  static_assert(offsetof(Sync, tag) == 0, "Sync is not valid.");
  static_assert(offsetof(Sync, ufreq_mult) == 2, "Sync is not valid.");
  static_assert(offsetof(Sync, base_cnt) == 4, "Sync is not valid.");

  volatile uint64_t next_sync0;
  const Sync* p = (const Sync*)p_data;

  bram_write(BRAM_SELECT_CONTROLLER, ADDR_UFREQ_MULT, p->ufreq_mult);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_BASE_CNT, p->base_cnt);

  next_sync0 = get_next_sync0();
  bram_cpy_volatile(BRAM_SELECT_CONTROLLER, ADDR_ECAT_SYNC_TIME_0, (volatile uint16_t*)&next_sync0, sizeof(uint64_t) >> 1);
  set_and_wait_update(CTL_FLAG_SYNC_SET);

  return NO_ERR;
}

#ifdef __cplusplus
}
#endif
