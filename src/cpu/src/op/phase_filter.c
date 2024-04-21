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
} PhaseFilter;

uint8_t write_phase_filter(const volatile uint8_t* p_data) {
  static_assert(sizeof(PhaseFilter) == 2, "PhaseFilter is not valid.");
  static_assert(offsetof(PhaseFilter, tag) == 0, "PhaseFilter is not valid.");

  bram_cpy_volatile(BRAM_SELECT_CONTROLLER, BRAM_CNT_SELECT_FILTER << 8,
                    (volatile const uint16_t*)(&p_data[sizeof(PhaseFilter)]),
                    ((NUM_TRANSDUCERS + 1) >> 1));

  return NO_ERR;
}

#ifdef __cplusplus
}
#endif
