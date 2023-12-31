// File: info.h
// Project: op
// Created Date: 31/12/2023
// Author: Shun Suzuki
// -----
// Last Modified: 31/12/2023
// Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
// -----
// Copyright (c) 2023 Shun Suzuki. All rights reserved.
//

#ifndef OP_INFO_H_
#define OP_INFO_H_

#include "app.h"
#include "params.h"

extern volatile bool_t _read_fpga_info;
extern volatile bool_t _read_fpga_info_store;
extern volatile uint8_t _rx_data;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t ty;
} FirmInfo;

inline static uint16_t get_cpu_version(void) { return CPU_VERSION_MAJOR; }
inline static uint16_t get_cpu_version_minor(void) { return CPU_VERSION_MINOR; }
inline static uint16_t get_fpga_version(void) { return bram_read(BRAM_SELECT_CONTROLLER, BRAM_ADDR_VERSION_NUM); }
inline static uint16_t get_fpga_version_minor(void) { return bram_read(BRAM_SELECT_CONTROLLER, BRAM_ADDR_VERSION_NUM_MINOR); }

uint8_t firmware_info(const volatile uint8_t* p_data) {
  const FirmInfo* p = (const FirmInfo*)p_data;
  switch (p->ty) {
    case INFO_TYPE_CPU_VERSION_MAJOR:
      _read_fpga_info_store = _read_fpga_info;
      _read_fpga_info = false;
      _rx_data = get_cpu_version() & 0xFF;
      break;
    case INFO_TYPE_CPU_VERSION_MINOR:
      _rx_data = get_cpu_version_minor() & 0xFF;
      break;
    case INFO_TYPE_FPGA_VERSION_MAJOR:
      _rx_data = get_fpga_version() & 0xFF;
      break;
    case INFO_TYPE_FPGA_VERSION_MINOR:
      _rx_data = get_fpga_version_minor() & 0xFF;
      break;
    case INFO_TYPE_CLEAR:
      _read_fpga_info = _read_fpga_info_store;
      _rx_data = 0;
      break;
    default:
      return ERR_INVALID_INFO_TYPE;
  }
  return ERR_NONE;
}

#endif  // OP_INFO_H_
