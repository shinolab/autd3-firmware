// File: silencer.cpp
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

TEST(Op, SilencerFixedUpdateRate) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  Header* header = reinterpret_cast<Header*>(data.data);
  header->msg_id = get_msg_id();
  header->slot_2_offset = 0;

  const auto intensity = 0x1234;
  const auto phase = 0x5678;
  const auto flag = 0;

  const auto data_body = reinterpret_cast<uint8_t*>(data.data);
  data_body[sizeof(Header)] = TAG_SILENCER;
  *reinterpret_cast<uint16_t*>(data_body + sizeof(Header) + 2) = intensity;
  *reinterpret_cast<uint16_t*>(data_body + sizeof(Header) + 4) = phase;
  *reinterpret_cast<uint16_t*>(data_body + sizeof(Header) + 6) = flag;

  auto frame = to_frame_data(data);

  recv_ethercat(&frame[0]);
  update();

  const auto ack = _sTx.ack >> 8;
  ASSERT_EQ(ack, header->msg_id);

  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_SILENCER_UPDATE_RATE_INTENSITY), intensity);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_SILENCER_UPDATE_RATE_PHASE), phase);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_SILENCER_CTL_FLAG), flag);
}

TEST(Op, SilencerFixedCompletionSteps) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  Header* header = reinterpret_cast<Header*>(data.data);
  header->msg_id = get_msg_id();
  header->slot_2_offset = 0;

  const auto intensity = 0x0001;
  const auto phase = 0x0002;
  const auto flag = SILENCER_CTL_FLAG_FIXED_COMPLETION_STEPS | SILENCER_CTL_FLAG_STRICT_MODE;

  auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
  data_body[0] = TAG_SILENCER;
  *reinterpret_cast<uint16_t*>(data_body + 2) = intensity;
  *reinterpret_cast<uint16_t*>(data_body + 4) = phase;
  *reinterpret_cast<uint16_t*>(data_body + 6) = flag;

  auto frame = to_frame_data(data);

  recv_ethercat(&frame[0]);
  update();

  const auto ack = _sTx.ack >> 8;
  ASSERT_EQ(ack, header->msg_id);

  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_SILENCER_COMPLETION_STEPS_INTENSITY), intensity);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_SILENCER_COMPLETION_STEPS_PHASE), phase);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_SILENCER_CTL_FLAG), flag);
}
