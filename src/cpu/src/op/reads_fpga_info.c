// File: reads_fpga_info.h
// Project: op
// Created Date: 31/12/2023
// Author: Shun Suzuki
// -----
// Last Modified: 17/01/2024
// Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
// -----
// Copyright (c) 2023 Shun Suzuki. All rights reserved.
//

#include <assert.h>
#include <stddef.h>

#include "app.h"
#include "params.h"

static volatile bool_t _read_fpga_info;
extern volatile uint8_t _rx_data;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t value;
} ConfigureReadsFPGAInfo;

uint8_t configure_reads_fpga_info(const volatile uint8_t* p_data) {
  static_assert(sizeof(ConfigureReadsFPGAInfo) == 2, "ConfigureReadsFPGAInfo is not valid.");
  static_assert(offsetof(ConfigureReadsFPGAInfo, tag) == 0, "ConfigureReadsFPGAInfo is not valid.");
  static_assert(offsetof(ConfigureReadsFPGAInfo, value) == 1, "ConfigureReadsFPGAInfo is not valid.");

  const ConfigureReadsFPGAInfo* p = (const ConfigureReadsFPGAInfo*)p_data;
  _read_fpga_info = p->value != 0;
  return ERR_NONE;
}

void read_fpga_info(void) {
  if (_read_fpga_info)
    _rx_data = READS_FPGA_INFO_ENABLED | (uint8_t)bram_read(BRAM_SELECT_CONTROLLER, BRAM_ADDR_FPGA_INFO);
  else
    _rx_data &= ~READS_FPGA_INFO_ENABLED;
}
