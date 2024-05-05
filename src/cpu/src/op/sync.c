#ifdef __cplusplus
extern "C" {
#endif

#include "sync.h"

#include "app.h"

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t __pad[3];
  uint32_t ecat_sync_base_cnt;
} Sync;

uint8_t synchronize(const volatile uint8_t* p_data) {
  volatile uint64_t next_sync0;

  const uint32_t ecat_sync_base_cnt = ((const Sync*)p_data)->ecat_sync_base_cnt;

  next_sync0 = get_next_sync0();
  bram_cpy_volatile(BRAM_SELECT_CONTROLLER, ADDR_ECAT_SYNC_TIME_0,
                    (volatile uint16_t*)&next_sync0, sizeof(uint64_t) >> 1);
  bram_cpy_volatile(BRAM_SELECT_CONTROLLER, ADDR_ECAT_SYNC_BASE_CNT_0,
                    (volatile uint16_t*)&ecat_sync_base_cnt,
                    sizeof(uint32_t) >> 1);
  set_and_wait_update(CTL_FLAG_SYNC_SET);

  return NO_ERR;
}

#ifdef __cplusplus
}
#endif
