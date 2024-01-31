#ifdef __cplusplus
extern "C" {
#endif

#include <assert.h>
#include <stddef.h>

#include "app.h"
#include "params.h"

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t idx;
} DebugOutIdx;

uint8_t configure_debug(const volatile uint8_t* p_data) {
  static_assert(sizeof(DebugOutIdx) == 2, "DebugOutIdx is not valid.");
  static_assert(offsetof(DebugOutIdx, tag) == 0, "DebugOutIdx is not valid.");
  static_assert(offsetof(DebugOutIdx, idx) == 1, "DebugOutIdx is not valid.");

  const DebugOutIdx* p = (const DebugOutIdx*)p_data;
  uint8_t idx = p->idx;
  bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_DEBUG_OUT_IDX, idx);
  return ERR_NONE;
}

#ifdef __cplusplus
}
#endif
