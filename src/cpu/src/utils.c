#ifdef __cplusplus
extern "C" {
#endif

#include <stddef.h>

#include "app.h"
#include "params.h"

extern volatile uint16_t _fpga_flags_internal;

void set_and_wait_update(uint16_t flag) {
  volatile uint16_t fpga_flag;
  bram_write(BRAM_SELECT_CONTROLLER, ADDR_CTL_FLAG,
             _fpga_flags_internal | flag);
  asm("dmb");
  while (true) {
    fpga_flag = bram_read(BRAM_SELECT_CONTROLLER, ADDR_CTL_FLAG);
    if ((fpga_flag & flag) == 0) break;
  }
}

#ifdef __cplusplus
}
#endif
