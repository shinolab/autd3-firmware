#ifdef __cplusplus
extern "C" {
#endif

#include <assert.h>
#include <stddef.h>
#include <stdio.h>

#include "app.h"
#include "params.h"
#include "utils.h"

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t _pad;
} PWE;

uint8_t config_pwe(const volatile uint8_t* p_data) {
  static_assert(sizeof(PWE) == 2, "PWE is not valid.");
  static_assert(offsetof(PWE, tag) == 0, "PWE is not valid.");

  const uint16_t* data = (const uint16_t*)(&p_data[sizeof(PWE)]);

  bram_cpy(BRAM_SELECT_PWE_TABLE, 0, data, (256 >> 1));

  return NO_ERR;
}

#ifdef __cplusplus
}
#endif
