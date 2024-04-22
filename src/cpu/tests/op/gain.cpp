#include <gtest/gtest.h>

#include "app.h"
#include "ecat.h"
#include "params.h"
#include "utils.hpp"

extern "C" {
extern TX_STR _sTx;
}

TEST(Op, Gain) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  // segment 0
  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_GAIN;
    data_body[1] = 0;
    *reinterpret_cast<uint16_t*>((data_body + 2)) = GAIN_FLAG_UPDATE;
    for (uint8_t i = 0; i < NUM_TRANSDUCERS; i++)
      *reinterpret_cast<uint16_t*>((data_body + 4 + i * 2)) = (i << 8) | i;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);

    ASSERT_EQ(bram_read_controller(ADDR_STM_MODE0), STM_MODE_GAIN);
    ASSERT_EQ(bram_read_controller(ADDR_STM_REQ_RD_SEGMENT), 0);
    for (uint8_t i = 0; i < NUM_TRANSDUCERS; i++)
      ASSERT_EQ(bram_read_stm(0, i), (i << 8) | i);
  }

  // segment 1
  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_GAIN;
    data_body[1] = 1;
    *reinterpret_cast<uint16_t*>((data_body + 2)) = 0;
    for (uint8_t i = 0; i < NUM_TRANSDUCERS; i++)
      *reinterpret_cast<uint16_t*>((data_body + 4 + i * 2)) =
          ((i + 1) << 8) | (i + 1);

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);

    ASSERT_EQ(bram_read_controller(ADDR_STM_MODE1), STM_MODE_GAIN);
    ASSERT_EQ(bram_read_controller(ADDR_STM_REQ_RD_SEGMENT), 0);
    for (uint8_t i = 0; i < NUM_TRANSDUCERS; i++)
      ASSERT_EQ(bram_read_stm(1, i), ((i + 1) << 8) | (i + 1));
  }

  // change segment
  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_GAIN_CHANGE_SEGMENT;
    data_body[1] = 1;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);

    ASSERT_EQ(bram_read_controller(ADDR_STM_REQ_RD_SEGMENT), 1);
  }
}

TEST(Op, GainInvalidSegmentTransition) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  Header* header = reinterpret_cast<Header*>(data.data);
  header->slot_2_offset = 0;

  // segment 0: FocusSTM
  {
    const uint32_t size = 2;
    const uint32_t freq_div = 0xFFFFFFFF;
    const uint32_t sound_speed = 0x00000000;
    const uint32_t rep = 0xFFFFFFFF;

    size_t cnt = 0;
    while (cnt < size) {
      header->msg_id = get_msg_id();

      auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
      data_body[0] = TAG_FOCUS_STM;
      auto offset = 4;
      if (cnt == 0) {
        data_body[1] = FOCUS_STM_FLAG_BEGIN;
        *reinterpret_cast<uint8_t*>(data_body + 3) = 0;
        *reinterpret_cast<uint32_t*>(data_body + 4) = freq_div;
        *reinterpret_cast<uint32_t*>(data_body + 8) = sound_speed;
        *reinterpret_cast<uint32_t*>(data_body + 12) = rep;
        offset += 12;
      } else {
        data_body[1] = 0;
      }
      auto send =
          std::min(size - cnt, (sizeof(RX_STR) - sizeof(Header) - offset) / 8);
      *reinterpret_cast<uint8_t*>(data_body + 2) = static_cast<uint8_t>(send);

      cnt += send;

      if (cnt == size)
        data_body[1] |= FOCUS_STM_FLAG_END | FOCUS_STM_FLAG_UPDATE;

      auto frame = to_frame_data(data);

      recv_ethercat(&frame[0]);
      update();

      const auto ack = _sTx.ack >> 8;
      ASSERT_EQ(ack, header->msg_id);
    }
  }

  // segment 1: GainSTM
  {
    const uint32_t size = 2;
    const uint8_t mode = GAIN_STM_MODE_INTENSITY_PHASE_FULL;
    const uint32_t freq_div = 0xFFFFFFFF;
    const uint32_t rep = 0xFFFFFFFF;
    size_t cnt = 0;
    while (cnt < size) {
      header->msg_id = get_msg_id();
      auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
      data_body[0] = TAG_GAIN_STM;
      if (cnt == 0) {
        data_body[1] = GAIN_STM_FLAG_BEGIN | GAIN_STM_FLAG_SEGMENT;
        *reinterpret_cast<uint8_t*>(data_body + 2) = mode;
        *reinterpret_cast<uint32_t*>(data_body + 8) = freq_div;
        *reinterpret_cast<uint32_t*>(data_body + 12) = rep;
      } else {
        data_body[1] = 0;
      }
      cnt++;
      if (cnt == size) data_body[1] |= GAIN_STM_FLAG_END | GAIN_STM_FLAG_UPDATE;
      auto frame = to_frame_data(data);
      recv_ethercat(&frame[0]);
      update();
      const auto ack = _sTx.ack >> 8;
      ASSERT_EQ(ack, header->msg_id);
    }
  }

  // change segment to 0
  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_GAIN_CHANGE_SEGMENT;
    data_body[1] = 0;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, ERR_INVALID_SEGMENT_TRANSITION);
  }

  // change segment to 1
  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_GAIN_CHANGE_SEGMENT;
    data_body[1] = 1;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, ERR_INVALID_SEGMENT_TRANSITION);
  }
}
