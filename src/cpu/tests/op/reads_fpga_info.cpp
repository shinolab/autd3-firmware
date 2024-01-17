// File: reads_fpga_info.cpp
// Project: op
// Created Date: 31/12/2023
// Author: Shun Suzuki
// -----
// Last Modified: 17/01/2024
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

TEST(Op, ReadsFPGAInfo) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  Header* header = reinterpret_cast<Header*>(data.data);
  {
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_READS_FPGA_INFO;
    data_body[1] = 0x01;  // enable

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
    ASSERT_EQ(0x00, _sTx.ack & 0xFF);

    update();
    ASSERT_EQ(READS_FPGA_INFO_ENABLED, _sTx.ack & 0xFF);
  }

  {
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_READS_FPGA_INFO;
    data_body[1] = 0x00;  // disable

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
    ASSERT_EQ(READS_FPGA_INFO_ENABLED, _sTx.ack & 0xFF);

    update();
    ASSERT_EQ(0x00, _sTx.ack & 0xFF);
  }
}
