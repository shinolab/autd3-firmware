#ifdef __cplusplus
extern "C" {
#endif

#include <assert.h>
#include <stddef.h>

#include "app.h"
#include "params.h"
#include "utils.h"

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t _pad;
} PhaseCorrection;

uint8_t phase_correction(const volatile uint8_t* p_data) {
  static_assert(sizeof(PhaseCorrection) == 2, "PhaseCorrection is not valid.");
  static_assert(offsetof(PhaseCorrection, tag) == 0, "PhaseCorrection is not valid.");

  const uint16_t* data = (const uint16_t*)(&p_data[sizeof(PhaseCorrection)]);

  bram_cpy(BRAM_SELECT_CONTROLLER, BRAM_CNT_SELECT_PHASE_CORR << 8, data, ((NUM_TRANSDUCERS + 1) >> 1));

  return NO_ERR;
}

#ifdef __cplusplus
}
#endif
