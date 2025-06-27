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
  uint8_t segment;
} OutputMask;

uint8_t output_mask(const volatile uint8_t* p_data) {
  static_assert(sizeof(OutputMask) == 2, "OutputMask is not valid.");
  static_assert(offsetof(OutputMask, tag) == 0, "OutputMask is not valid.");
  static_assert(offsetof(OutputMask, segment) == 1, "OutputMask is not valid.");

  const uint16_t segment = ((const OutputMask*)p_data)->segment;
  const uint16_t* data = (const uint16_t*)(&p_data[sizeof(OutputMask)]);

  bram_cpy(BRAM_SELECT_CONTROLLER, (BRAM_CNT_SELECT_OUTPUT_MASK << 8) | (segment << 4), data, 16);

  return NO_ERR;
}

#ifdef __cplusplus
}
#endif
