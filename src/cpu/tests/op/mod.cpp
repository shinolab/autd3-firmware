// File: mod.cpp
// Project: op
// Created Date: 31/12/2023
// Author: Shun Suzuki
// -----
// Last Modified: 31/12/2023
// Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
// -----
// Copyright (c) 2023 Shun Suzuki. All rights reserved.
//

#include <gtest/gtest.h>

#include "app.h"
#include "ecat.h"
#include "params.h"
#include "utils.hpp"

extern "C" {
extern TX_STR _sTx;
}

TEST(Op, Mod) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  std::vector<uint8_t> m;
  for (auto i = 0; i < 65536; i++) m.push_back(static_cast<uint8_t>(i));

  Header* header = reinterpret_cast<Header*>(data.data);
  header->slot_2_offset = 0;

  const uint32_t freq_div = 0x12345678;

  size_t cnt = 0;
  while (cnt < 65536) {
    header->msg_id = get_msg_id();

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_MODULATION;
    auto offset = 4;
    if (cnt == 0) {
      data_body[1] = MODULATION_FLAG_BEGIN;
      *reinterpret_cast<uint32_t*>(data_body + offset) = freq_div;
      offset += 4;
    } else {
      data_body[1] = 0;
    }
    auto send = std::min(65536 - cnt, sizeof(RX_STR) - sizeof(Header) - offset);
    *reinterpret_cast<uint16_t*>(data_body + 2) = static_cast<uint16_t>(send);

    for (size_t i = 0; i < send; i++) data_body[offset + i] = m[cnt + i];
    cnt += send;

    if (cnt == 65536) {
      data_body[1] = MODULATION_FLAG_END;
    }

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }

  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_MOD_CYCLE), 65535);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_MOD_FREQ_DIV_0), 0x5678);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_MOD_FREQ_DIV_1), 0x1234);
  for (size_t i = 0; i < 65536 >> 1; i++) {
    ASSERT_EQ(bram_read_raw(BRAM_SELECT_MOD, i), ((static_cast<uint8_t>((i << 1) + 1)) << 8) | static_cast<uint8_t>(i << 1));
  }
}
