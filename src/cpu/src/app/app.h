#ifndef APP_H_
#define APP_H_

#include "params.h"

#define ALIGN2 __attribute__((aligned(2)))

#ifndef true
#define true 1
#endif
#ifndef false
#define false 0
#endif
#ifndef uint8_t
typedef unsigned char uint8_t;
#endif
#ifndef uint16_t
typedef unsigned short uint16_t;
#endif
#ifndef uint32_t
typedef unsigned long uint32_t;
#endif
#ifndef uint64_t
typedef long long unsigned int uint64_t;
#endif
#ifndef bool_t
typedef int bool_t;
#endif

#define FPGA_BASE (0x44000000) /* CS1 FPGA address */

inline static uint16_t get_addr(uint8_t bram_select, uint16_t bram_addr) {
  return (((uint16_t)bram_select & 0x0003) << 14) | (bram_addr & 0x3FFF);
}

inline static void bram_write(uint8_t bram_select, uint16_t bram_addr,
                              uint16_t value) {
  volatile uint16_t *base = (volatile uint16_t *)FPGA_BASE;
  uint16_t addr = get_addr(bram_select, bram_addr);
  base[addr] = value;
}

inline static uint16_t bram_read(uint8_t bram_select, uint16_t bram_addr) {
  volatile uint16_t *base = (volatile uint16_t *)FPGA_BASE;
  uint16_t addr = get_addr(bram_select, bram_addr);
  return base[addr];
}

inline static void bram_cpy(uint8_t bram_select, uint16_t base_bram_addr,
                            const uint16_t *values, uint32_t cnt) {
  uint16_t base_addr = get_addr(bram_select, base_bram_addr);
  volatile uint16_t *base = (volatile uint16_t *)FPGA_BASE;
  volatile uint16_t *dst = &base[base_addr];
  while (cnt-- > 0) *dst++ = *values++;
}

inline static void bram_cpy_volatile(uint8_t bram_select,
                                     uint16_t base_bram_addr,
                                     const volatile uint16_t *values,
                                     uint32_t cnt) {
  uint16_t base_addr = get_addr(bram_select, base_bram_addr);
  volatile uint16_t *base = (volatile uint16_t *)FPGA_BASE;
  volatile uint16_t *dst = &base[base_addr];
  while (cnt-- > 0) *dst++ = *values++;
}

inline static void bram_cpy_focus_stm(uint16_t base_bram_addr,
                                      const volatile uint16_t *values,
                                      uint32_t cnt) {
  uint16_t base_addr = get_addr(BRAM_SELECT_STM, base_bram_addr);
  volatile uint16_t *base = (volatile uint16_t *)FPGA_BASE;
  volatile uint16_t *dst = &base[base_addr];
  while (cnt--) {
    *dst++ = *values++;
    *dst++ = *values++;
    *dst++ = *values++;
    *dst++ = *values++;
  }
}

inline static void bram_cpy_gain_stm_phase_full(uint16_t base_bram_addr,
                                                const volatile uint16_t *values,
                                                const int shift, uint32_t cnt) {
  uint16_t base_addr = get_addr(BRAM_SELECT_STM, base_bram_addr);
  volatile uint16_t *base = (volatile uint16_t *)FPGA_BASE;
  volatile uint16_t *dst = &base[base_addr];
  while (cnt--) *dst++ = 0xFF00 | (((*values++) >> shift) & 0x00FF);
}

inline static void bram_cpy_gain_stm_phase_half(uint16_t base_bram_addr,
                                                const volatile uint16_t *values,
                                                const int shift, uint32_t cnt) {
  uint16_t base_addr = get_addr(BRAM_SELECT_STM, base_bram_addr);
  volatile uint16_t *base = (volatile uint16_t *)FPGA_BASE;
  volatile uint16_t *dst = &base[base_addr];
  uint16_t phase;
  while (cnt--) {
    phase = ((*values++) >> shift) & 0x000F;
    *dst++ = 0xFF00 | (phase << 4) | phase;
  }
}

inline static void bram_set(uint8_t bram_select, uint16_t base_bram_addr,
                            uint16_t value, uint32_t cnt) {
  uint16_t base_addr = get_addr(bram_select, base_bram_addr);
  volatile uint16_t *base = (volatile uint16_t *)FPGA_BASE;
  volatile uint16_t *dst = &base[base_addr];
  while (cnt-- > 0) *dst++ = value;
}

void set_and_wait_update(uint16_t flag);

#endif /* APP_H_ */
