// File: gain_stm.cpp
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

TEST(Op, GainSTMPhaseIntensityFull) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  std::vector<std::vector<uint16_t>> buf;
  for (uint16_t i = 0; i < 2048; i++) {
    std::vector<uint16_t> tmp;
    tmp.reserve(TRANS_NUM);
    for (uint16_t j = 0; j < TRANS_NUM; j++) tmp.emplace_back(i + j);
    buf.emplace_back(std::move(tmp));
  }

  Header* header = reinterpret_cast<Header*>(data.data);
  header->slot_2_offset = 0;

  const uint16_t mode = GAIN_STM_MODE_INTENSITY_PHASE_FULL;
  const uint32_t freq_div = 0x12345678;
  const uint16_t start_idx = 0x0123;
  const uint16_t finish_idx = 0x4567;

  size_t cnt = 0;
  while (cnt < 2048) {
    header->msg_id = get_msg_id();

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_GAIN_STM;
    auto offset = 2;
    if (cnt == 0) {
      data_body[1] = GAIN_STM_FLAG_BEGIN | GAIN_STM_FLAG_USE_START_IDX | GAIN_STM_FLAG_USE_FINISH_IDX;
      *reinterpret_cast<uint16_t*>(data_body + 2) = mode;
      *reinterpret_cast<uint32_t*>(data_body + 4) = freq_div;
      *reinterpret_cast<uint16_t*>(data_body + 8) = start_idx;
      *reinterpret_cast<uint16_t*>(data_body + 10) = finish_idx;
      offset += 10;
    } else {
      data_body[1] = 0;
    }

    for (size_t i = 0; i < TRANS_NUM; i++) {
      *reinterpret_cast<uint16_t*>(data_body + offset + 2 * i) = buf[cnt][i];
    }
    cnt++;

    if (cnt == 2048) {
      data_body[1] = GAIN_STM_FLAG_END;
    }

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }

  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_CTL_FLAG) & CTL_FLAG_OP_MODE, CTL_FLAG_OP_MODE);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_CTL_FLAG) & CTL_FLAG_STM_GAIN_MODE, CTL_FLAG_STM_GAIN_MODE);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_CTL_FLAG) & CTL_FLAG_USE_STM_FINISH_IDX, CTL_FLAG_USE_STM_FINISH_IDX);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_CTL_FLAG) & CTL_FLAG_USE_STM_START_IDX, CTL_FLAG_USE_STM_START_IDX);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_CYCLE), 2047);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FREQ_DIV_0), 0x5678);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FREQ_DIV_1), 0x1234);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_START_IDX), 0x0123);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FINISH_IDX), 0x4567);
  for (uint16_t i = 0; i < 2048; i++) {
    for (uint16_t j = 0; j < TRANS_NUM; j++) {
      ASSERT_EQ(bram_read_raw(BRAM_SELECT_STM, 256 * i + j), i + j);
    }
  }
}

TEST(Op, GainSTMPhaseFull) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  std::vector<std::vector<uint8_t>> buf;
  for (uint16_t i = 0; i < 2048; i++) {
    std::vector<uint8_t> tmp;
    tmp.reserve(TRANS_NUM);
    for (uint16_t j = 0; j < TRANS_NUM; j++) tmp.emplace_back(static_cast<uint8_t>(i + j));
    buf.emplace_back(std::move(tmp));
  }

  Header* header = reinterpret_cast<Header*>(data.data);
  header->slot_2_offset = 0;

  const uint16_t mode = GAIN_STM_MODE_PHASE_FULL;
  const uint32_t freq_div = 0x12345678;
  const uint16_t start_idx = 0x0123;
  const uint16_t finish_idx = 0x4567;

  size_t cnt = 0;
  while (cnt < 2048) {
    header->msg_id = get_msg_id();

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_GAIN_STM;
    auto offset = 2;
    if (cnt == 0) {
      data_body[1] = GAIN_STM_FLAG_BEGIN | GAIN_STM_FLAG_USE_START_IDX | GAIN_STM_FLAG_USE_FINISH_IDX;
      *reinterpret_cast<uint16_t*>(data_body + 2) = mode;
      *reinterpret_cast<uint32_t*>(data_body + 4) = freq_div;
      *reinterpret_cast<uint16_t*>(data_body + 8) = start_idx;
      *reinterpret_cast<uint16_t*>(data_body + 10) = finish_idx;
      offset += 10;
    } else {
      data_body[1] = 0;
    }

    for (size_t i = 0; i < TRANS_NUM; i++) {
      *reinterpret_cast<uint16_t*>(data_body + offset + 2 * i) = (buf[cnt + 1][i] << 8) | buf[cnt][i];
    }
    cnt += 2;

    if (cnt == 2048) {
      data_body[1] = GAIN_STM_FLAG_END;
    }

    data_body[1] |= (2 - 1) << 6;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }

  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_CTL_FLAG) & CTL_FLAG_OP_MODE, CTL_FLAG_OP_MODE);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_CTL_FLAG) & CTL_FLAG_STM_GAIN_MODE, CTL_FLAG_STM_GAIN_MODE);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_CTL_FLAG) & CTL_FLAG_USE_STM_FINISH_IDX, CTL_FLAG_USE_STM_FINISH_IDX);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_CTL_FLAG) & CTL_FLAG_USE_STM_START_IDX, CTL_FLAG_USE_STM_START_IDX);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_CYCLE), 2047);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FREQ_DIV_0), 0x5678);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FREQ_DIV_1), 0x1234);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_START_IDX), 0x0123);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FINISH_IDX), 0x4567);
  for (uint16_t i = 0; i < 2048; i++) {
    for (uint16_t j = 0; j < TRANS_NUM; j++) {
      ASSERT_EQ(bram_read_raw(BRAM_SELECT_STM, 256 * i + j), 0xFF00 | static_cast<uint8_t>(i + j));
    }
  }
}

TEST(Op, GainSTMPhaseHalf) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  std::vector<std::vector<uint8_t>> buf;
  for (uint16_t i = 0; i < 2048; i++) {
    std::vector<uint8_t> tmp;
    tmp.reserve(TRANS_NUM);
    for (uint16_t j = 0; j < TRANS_NUM; j++) tmp.emplace_back(static_cast<uint8_t>(i + j));
    buf.emplace_back(std::move(tmp));
  }

  Header* header = reinterpret_cast<Header*>(data.data);
  header->slot_2_offset = 0;

  const uint16_t mode = GAIN_STM_MODE_PHASE_HALF;
  const uint32_t freq_div = 0x12345678;
  const uint16_t start_idx = 0x0123;
  const uint16_t finish_idx = 0x4567;

  size_t cnt = 0;
  while (cnt < 2048) {
    header->msg_id = get_msg_id();

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_GAIN_STM;
    auto offset = 2;
    if (cnt == 0) {
      data_body[1] = GAIN_STM_FLAG_BEGIN | GAIN_STM_FLAG_USE_START_IDX | GAIN_STM_FLAG_USE_FINISH_IDX;
      *reinterpret_cast<uint16_t*>(data_body + 2) = mode;
      *reinterpret_cast<uint32_t*>(data_body + 4) = freq_div;
      *reinterpret_cast<uint16_t*>(data_body + 8) = start_idx;
      *reinterpret_cast<uint16_t*>(data_body + 10) = finish_idx;
      offset += 10;
    } else {
      data_body[1] = 0;
    }

    for (size_t i = 0; i < TRANS_NUM; i++) {
      *reinterpret_cast<uint16_t*>(data_body + offset + 2 * i) =
          ((buf[cnt + 3][i] >> 4) << 12) | ((buf[cnt + 2][i] >> 4) << 8) | ((buf[cnt + 1][i] >> 4) << 4) | (buf[cnt][i] >> 4);
    }
    cnt += 4;

    if (cnt == 2048) {
      data_body[1] = GAIN_STM_FLAG_END;
    }

    data_body[1] |= (4 - 1) << 6;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }

  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_CTL_FLAG) & CTL_FLAG_OP_MODE, CTL_FLAG_OP_MODE);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_CTL_FLAG) & CTL_FLAG_STM_GAIN_MODE, CTL_FLAG_STM_GAIN_MODE);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_CTL_FLAG) & CTL_FLAG_USE_STM_FINISH_IDX, CTL_FLAG_USE_STM_FINISH_IDX);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_CTL_FLAG) & CTL_FLAG_USE_STM_START_IDX, CTL_FLAG_USE_STM_START_IDX);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_CYCLE), 2047);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FREQ_DIV_0), 0x5678);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FREQ_DIV_1), 0x1234);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_START_IDX), 0x0123);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FINISH_IDX), 0x4567);
  for (uint16_t i = 0; i < 2048; i++) {
    for (uint16_t j = 0; j < TRANS_NUM; j++) {
      const auto phase = static_cast<uint8_t>(i + j) >> 4;
      ASSERT_EQ(bram_read_raw(BRAM_SELECT_STM, 256 * i + j), 0xFF00 | phase << 4 | phase);
    }
  }
}
