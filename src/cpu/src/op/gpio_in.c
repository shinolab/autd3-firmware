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
  uint8_t flag;
} GPIOIN;

uint8_t emulate_gpio_in(const volatile uint8_t* p_data) {
  static_assert(sizeof(GPIOIN) == 2, "GPIOIN is not valid.");
  static_assert(offsetof(GPIOIN, tag) == 0, "GPIOIN is not valid.");
  static_assert(offsetof(GPIOIN, flag) == 1, "GPIOIN is not valid.");

  const GPIOIN* p = (const GPIOIN*)p_data;
  if ((p->flag & GPIO_IN_FLAG_0) == GPIO_IN_FLAG_0)
    _fpga_flags_internal |= CTL_FLAG_GPIO_IN_0;
  else
    _fpga_flags_internal &= ~CTL_FLAG_GPIO_IN_0;

  if ((p->flag & GPIO_IN_FLAG_1) == GPIO_IN_FLAG_1)
    _fpga_flags_internal |= CTL_FLAG_GPIO_IN_1;
  else
    _fpga_flags_internal &= ~CTL_FLAG_GPIO_IN_1;

  if ((p->flag & GPIO_IN_FLAG_2) == GPIO_IN_FLAG_2)
    _fpga_flags_internal |= CTL_FLAG_GPIO_IN_2;
  else
    _fpga_flags_internal &= ~CTL_FLAG_GPIO_IN_2;

  if ((p->flag & GPIO_IN_FLAG_3) == GPIO_IN_FLAG_3)
    _fpga_flags_internal |= CTL_FLAG_GPIO_IN_3;
  else
    _fpga_flags_internal &= ~CTL_FLAG_GPIO_IN_3;

  return NO_ERR;
}

#ifdef __cplusplus
}
#endif
