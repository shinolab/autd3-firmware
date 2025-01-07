#ifdef __cplusplus
extern "C" {
#endif

#include <assert.h>
#include <stddef.h>

#include "app.h"
#include "iodefine.h"
#include "params.h"

volatile uint16_t _clk_write;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
  uint16_t size;
} Clk;

uint8_t configure_clk(const volatile uint8_t* p_data) {
  static_assert(sizeof(Clk) == 4, "Clk is not valid.");
  static_assert(offsetof(Clk, tag) == 0, "Clk is not valid.");
  static_assert(offsetof(Clk, flag) == 1, "Clk is not valid.");
  static_assert(offsetof(Clk, size) == 2, "Clk is not valid.");

  const Clk* p = (const Clk*)p_data;
  uint16_t size = p->size;

  if ((p->flag & CLK_FLAG_BEGIN) == CLK_FLAG_BEGIN) _clk_write = 0;

  bram_cpy_volatile(BRAM_SELECT_CONTROLLER, BRAM_CNT_SELECT_CLOCK << 8, (volatile const uint16_t*)(&p_data[sizeof(Clk)]), size << 2);
  _clk_write = _clk_write + size;

  if ((p->flag & CLK_FLAG_END) == CLK_FLAG_END)
    if (_clk_write != 32) return ERR_CLK_INCOMPLETE_DATA;

  return NO_ERR;
}

#ifdef __cplusplus
}
#endif
