#ifdef __cplusplus
extern "C" {
#endif

#include <assert.h>
#include <stddef.h>

#include "app.h"
#include "params.h"

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t _pad;
  uint8_t ty[4];
  uint16_t value[4];
} DebugSetting;

uint8_t configure_debug(const volatile uint8_t* p_data) {
  static_assert(sizeof(DebugSetting) == 14, "DebugSetting is not valid.");
  static_assert(offsetof(DebugSetting, tag) == 0, "DebugSetting is not valid.");
  static_assert(offsetof(DebugSetting, ty) == 2, "DebugSetting is not valid.");
  static_assert(offsetof(DebugSetting, value) == 6,
                "DebugSetting is not valid.");

  const DebugSetting* p = (const DebugSetting*)p_data;
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_TYPE0, p->ty[0]);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_TYPE1, p->ty[1]);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_TYPE2, p->ty[2]);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_TYPE3, p->ty[3]);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_VALUE0, p->value[0]);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_VALUE1, p->value[1]);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_VALUE2, p->value[2]);
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_DEBUG_VALUE3, p->value[3]);

  set_and_wait_update(CTL_FLAG_DEBUG_SET);

  return NO_ERR;
}

#ifdef __cplusplus
}
#endif
