#ifdef __cplusplus
extern "C" {
#endif

#include <assert.h>
#include <stddef.h>

#include "app.h"
#include "iodefine.h"
#include "params.h"

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t pa_podr;
} CPU_GPIO_OUT;

uint8_t cpu_gpio_out(const volatile uint8_t* p_data) {
  static_assert(sizeof(CPU_GPIO_OUT) == 2, "CPU_GPIO_OUT is not valid.");
  static_assert(offsetof(CPU_GPIO_OUT, tag) == 0, "CPU_GPIO_OUT is not valid.");
  static_assert(offsetof(CPU_GPIO_OUT, pa_podr) == 1, "CPU_GPIO_OUT is not valid.");

  const CPU_GPIO_OUT* p = (const CPU_GPIO_OUT*)p_data;

  PORTA.PODR.BYTE = p->pa_podr;

  return NO_ERR;
}

#ifdef __cplusplus
}
#endif
