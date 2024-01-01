// File: reads_fpga_info.h
// Project: op
// Created Date: 31/12/2023
// Author: Shun Suzuki
// -----
// Last Modified: 31/12/2023
// Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
// -----
// Copyright (c) 2023 Shun Suzuki. All rights reserved.
//

#ifndef OP_READS_FPGA_INFO_H_
#define OP_READS_FPGA_INFO_H_

#include "app.h"
#include "params.h"

extern volatile bool_t _read_fpga_info;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t value;
} ConfigureReadsFPGAInfo;

uint8_t configure_reads_fpga_info(const volatile uint8_t* p_data) {
  const ConfigureReadsFPGAInfo* p = (const ConfigureReadsFPGAInfo*)p_data;
  _read_fpga_info = p->value != 0;
  return ERR_NONE;
}

uint16_t read_fpga_info(void) { return bram_read(BRAM_SELECT_CONTROLLER, BRAM_ADDR_FPGA_INFO); }

#endif  // OP_READS_FPGA_INFO_H_
