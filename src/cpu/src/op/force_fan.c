#ifdef __cplusplus
extern "C" {
#endif

#include <assert.h>
#include <stddef.h>

#include "app.h"
#include "params.h"

extern volatile uint16_t _fpga_flags_internal;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t value;
} ForceFan;

uint8_t configure_force_fan(const volatile uint8_t* p_data) {
  static_assert(sizeof(ForceFan) == 2, "ForceFan is not valid.");
  static_assert(offsetof(ForceFan, tag) == 0, "ForceFan is not valid.");
  static_assert(offsetof(ForceFan, value) == 1, "ForceFan is not valid.");

  const ForceFan* p = (const ForceFan*)p_data;
  if (p->value != 0)
    _fpga_flags_internal |= CTL_FLAG_FORCE_FAN;
  else
    _fpga_flags_internal &= ~CTL_FLAG_FORCE_FAN;

  return NO_ERR | REQ_UPDATE_SETTINGS;
}

#ifdef __cplusplus
}
#endif
