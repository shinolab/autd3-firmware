// File: app.h
// Project: inc
// Created Date: 31/12/2023
// Author: Shun Suzuki
// -----
// Last Modified: 31/12/2023
// Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
// -----
// Copyright (c) 2023 Shun Suzuki. All rights reserved.
//

#pragma once

#include <stdint.h>

#ifndef true
#define true 1
#endif
#ifndef false
#define false 0
#endif
#ifndef bool_t
typedef int bool_t;
#endif

#define dly_tsk(time)
#define asm(str)

inline static uint16_t get_addr(uint8_t bram_select, uint16_t bram_addr) { return (((uint16_t)bram_select & 0x0003) << 14) | (bram_addr & 0x3FFF); }

inline static void bram_write(uint8_t bram_select, uint16_t bram_addr, uint16_t value) {}

inline static uint16_t bram_read(uint8_t bram_select, uint16_t bram_addr) { return 0; }

inline static void bram_cpy(uint8_t bram_select, uint16_t base_bram_addr, const uint16_t *values, uint32_t cnt) {}

inline static void bram_cpy_volatile(uint8_t bram_select, uint16_t base_bram_addr, const volatile uint16_t *values, uint32_t cnt) {}

inline static void bram_cpy_focus_stm(uint16_t base_bram_addr, const volatile uint16_t *values, uint32_t cnt) {}

inline static void bram_cpy_gain_stm_phase_full(uint16_t base_bram_addr, const volatile uint16_t *values, const int shift, uint32_t cnt) {}

inline static void bram_cpy_gain_stm_phase_half(uint16_t base_bram_addr, const volatile uint16_t *values, const int shift, uint32_t cnt) {}

inline static void bram_set(uint8_t bram_select, uint16_t base_bram_addr, uint16_t value, uint32_t cnt) {}
