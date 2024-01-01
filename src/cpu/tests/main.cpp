// File: main.cpp
// Project: tests
// Created Date: 31/12/2023
// Author: Shun Suzuki
// -----
// Last Modified: 01/01/2024
// Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
// -----
// Copyright (c) 2023 Shun Suzuki. All rights reserved.
//

#include <gtest/gtest.h>

#include <cstring>

extern "C" {

#include "app.h"
#include "ecat.h"
#include "iodefine.h"
#include "params.h"

TX_STR _sTx = TX_STR{};
st_ecatc_t ECATC = st_ecatc_t{
    .AL_STATUS_CODE = {.WORD = 0x0000},
};

uint8_t get_msg_id(void) {
  static uint8_t msg_id = 0;
  const auto id = msg_id++;
  if (msg_id == 0x80) msg_id = 0;
  return id;
}

uint16_t* controller_bram = new uint16_t[1280];
uint16_t* modulator_bram = new uint16_t[32768];
uint16_t* normal_op_bram = new uint16_t[512];
uint16_t* stm_op_bram = new uint16_t[524288];

uint16_t bram_read_raw(uint8_t bram_select, uint32_t bram_addr) {
  switch (bram_select) {
    case BRAM_SELECT_CONTROLLER:
      return controller_bram[bram_addr];
    case BRAM_SELECT_MOD:
      return modulator_bram[bram_addr];
    case BRAM_SELECT_NORMAL:
      return normal_op_bram[bram_addr];
    case BRAM_SELECT_STM:
      return stm_op_bram[bram_addr];
    default:
      return 0x0000;
  }
}

uint16_t fpga_read(uint16_t bram_addr) {
  const auto select = (bram_addr >> 14) & 0x0003;
  const auto addr = bram_addr & 0x3FFF;
  switch (select) {
    case BRAM_SELECT_CONTROLLER:
      return controller_bram[addr];
    default:
      return 0x0000;
  }
}

void fpga_write(uint16_t bram_addr, uint16_t value) {
  const auto select = (bram_addr >> 14) & 0x0003;
  auto addr = bram_addr & 0x3FFF;
  switch (select) {
    case BRAM_SELECT_CONTROLLER:
      controller_bram[addr] = value;
      break;
    case BRAM_SELECT_MOD:
      addr = controller_bram[BRAM_ADDR_MOD_MEM_PAGE] << 14 | addr;
      modulator_bram[addr] = value;
      break;
    case BRAM_SELECT_NORMAL:
      normal_op_bram[addr] = value;
      break;
    case BRAM_SELECT_STM:
      addr = controller_bram[BRAM_ADDR_STM_MEM_PAGE] << 14 | addr;
      stm_op_bram[addr] = value;
      break;
    default:
      break;
  }
}
}

int main(int argc, char** argv) {
  std::memset(controller_bram, 0, sizeof(uint16_t) * 1280);
  std::memset(modulator_bram, 0, sizeof(uint16_t) * 32768);
  std::memset(normal_op_bram, 0, sizeof(uint16_t) * 512);
  std::memset(stm_op_bram, 0, sizeof(uint16_t) * 524288);

  controller_bram[BRAM_ADDR_VERSION_NUM] = 0x008D;
  controller_bram[BRAM_ADDR_VERSION_NUM_MINOR] = 0x0001;

  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}