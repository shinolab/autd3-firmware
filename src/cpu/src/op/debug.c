#ifdef __cplusplus
extern "C" {
#endif

#include <assert.h>
#include <stddef.h>

#include "app.h"
#include "params.h"

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t _pad[7];
  uint64_t value[4];
} DebugSetting;

uint8_t configure_debug(const volatile uint8_t* p_data) {
  static_assert(sizeof(DebugSetting) == 40, "DebugSetting is not valid.");
  static_assert(offsetof(DebugSetting, tag) == 0, "DebugSetting is not valid.");
  static_assert(offsetof(DebugSetting, value) == 8, "DebugSetting is not valid.");

  const DebugSetting* p = (const DebugSetting*)p_data;
  const uint16_t* vp = (const uint16_t*)(p->value);
  bram_cpy(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_TYPE0, vp, 4 * sizeof(uint64_t) / sizeof(uint16_t));

  set_and_wait_update(CTL_FLAG_DEBUG_SET);

  return NO_ERR;
}

#ifdef __cplusplus
}
#endif
