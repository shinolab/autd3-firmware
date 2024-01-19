// File: reads_fpga_state.h
// Project: op
// Created Date: 31/12/2023
// Author: Shun Suzuki
// -----
// Last Modified: 17/01/2024
// Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
// -----
// Copyright (c) 2023 Shun Suzuki. All rights reserved.
//

#ifdef __cplusplus
extern "C" {
#endif

#include <assert.h>
#include <stddef.h>

#include "app.h"
#include "params.h"

static volatile bool_t _read_fpga_state;
extern volatile uint8_t _rx_data;
volatile bool_t _is_rx_data_used = false;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t value;
} ConfigureReadsFPGAState;

uint8_t configure_reads_fpga_state(const volatile uint8_t* p_data) {
  static_assert(sizeof(ConfigureReadsFPGAState) == 2, "ConfigureReadsFPGAState is not valid.");
  static_assert(offsetof(ConfigureReadsFPGAState, tag) == 0, "ConfigureReadsFPGAState is not valid.");
  static_assert(offsetof(ConfigureReadsFPGAState, value) == 1, "ConfigureReadsFPGAState is not valid.");

  const ConfigureReadsFPGAState* p = (const ConfigureReadsFPGAState*)p_data;
  _read_fpga_state = p->value != 0;
  return ERR_NONE;
}

void read_fpga_state(void) {
  if (_is_rx_data_used) return;
  if (_read_fpga_state)
    _rx_data = READS_FPGA_STATE_ENABLED | (uint8_t)bram_read(BRAM_SELECT_CONTROLLER, BRAM_ADDR_FPGA_STATE);
  else
    _rx_data &= ~READS_FPGA_STATE_ENABLED;
}

#ifdef __cplusplus
}
#endif
