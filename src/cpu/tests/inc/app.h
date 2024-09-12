#pragma once

#include <stdint.h>

#include "params.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __clang__
#define ALIGN2 __attribute__((aligned(2)))
#elif __GNUC__
#define ALIGN2 __attribute__((aligned(2)))
#elif _MSC_VER
#define ALIGN2 __declspec(align(2))
#else
#error "Unknown compiler"
#endif

#ifndef true
#define true 1
#endif
#ifndef false
#define false 0
#endif
#ifndef bool_t
typedef int bool_t;
#endif

typedef union {
  uint64_t value;
  struct {
    uint8_t _pad[7];
    uint8_t mode;
  } MODE;
} Transition;

#define dly_tsk(time)
#define asm(str)

void recv_ethercat(uint16_t *p_data);
void init_app(void);
void update(void);

uint8_t get_msg_id(void);

uint16_t fpga_read(uint16_t bram_addr);
void fpga_write(uint16_t bram_addr, uint16_t value);
uint16_t bram_read_controller(uint32_t bram_addr);
uint16_t bram_read_mod(uint32_t segment, uint32_t bram_addr);
uint16_t bram_read_pwe_table(uint32_t bram_addr);
uint16_t bram_read_clk(uint32_t bram_addr);
uint16_t bram_read_stm(uint32_t segment, uint32_t bram_addr);

inline static uint16_t get_addr(uint8_t bram_select, uint16_t bram_addr) { return (((uint16_t)bram_select & 0x0003) << 14) | (bram_addr & 0x3FFF); }

inline static void bram_write(uint8_t bram_select, uint16_t bram_addr, uint16_t value) {
  const auto addr = get_addr(bram_select, bram_addr);
  fpga_write(addr, value);
}

inline static uint16_t bram_read(uint8_t bram_select, uint16_t bram_addr) {
  const auto addr = get_addr(bram_select, bram_addr);
  return fpga_read(addr);
}

inline static void bram_cpy(uint8_t bram_select, uint16_t base_bram_addr, const uint16_t *values, uint32_t cnt) {
  uint16_t addr = get_addr(bram_select, base_bram_addr);
  for (auto i = 0; i < cnt; i++) fpga_write(addr++, *(values + i));
}

inline static void bram_cpy_volatile(uint8_t bram_select, uint16_t base_bram_addr, const volatile uint16_t *values, uint32_t cnt) {
  uint16_t addr = get_addr(bram_select, base_bram_addr);
  for (auto i = 0; i < cnt; i++) fpga_write(addr++, *(values + i));
}

inline static void bram_cpy_focus_stm(uint16_t base_bram_addr, const volatile uint16_t *values, uint32_t cnt, uint8_t num_foci) {
  uint16_t base_addr = get_addr(BRAM_SELECT_STM, base_bram_addr);
  while (cnt--) {
    fpga_write(base_addr++, *values++);
    fpga_write(base_addr++, *values++);
    fpga_write(base_addr++, *values++);
    fpga_write(base_addr++, *values++);
    base_addr += (8 - num_foci) * 4;
  }
}

inline static void bram_cpy_gain_stm_phase_full(uint16_t base_bram_addr, const volatile uint16_t *values, const int shift, uint32_t cnt) {
  uint16_t base_addr = get_addr(BRAM_SELECT_STM, base_bram_addr);
  while (cnt--) fpga_write(base_addr++, 0xFF00 | (((*values++) >> shift) & 0x00FF));
}

inline static void bram_cpy_gain_stm_phase_half(uint16_t base_bram_addr, const volatile uint16_t *values, const int shift, uint32_t cnt) {
  uint16_t base_addr = get_addr(BRAM_SELECT_STM, base_bram_addr);
  uint16_t phase;
  while (cnt--) {
    phase = ((*values++) >> shift) & 0x000F;
    fpga_write(base_addr++, 0xFF00 | (phase << 4) | phase);
  }
}

inline static void bram_set(uint8_t bram_select, uint16_t base_bram_addr, uint16_t value, uint32_t cnt) {
  auto addr = get_addr(bram_select, base_bram_addr);
  for (auto i = 0; i < cnt; i++) fpga_write(addr++, value);
}

void set_and_wait_update(uint16_t flag);

#ifdef __cplusplus
}
#endif
