#include <gtest/gtest.h>

//
#include "app.h"
#include "ecat.h"
#include "foci_stm.h"
#include "gain.h"
#include "gain_stm.h"
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

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    reinterpret_cast<Gain*>(p)->tag = TAG_GAIN;
    reinterpret_cast<Gain*>(p)->segment = 0;
    reinterpret_cast<Gain*>(p)->flag = GAIN_FLAG_UPDATE;

    for (uint8_t i = 0; i < NUM_TRANSDUCERS; i++)
      *reinterpret_cast<uint16_t*>((p + sizeof(Gain) + i * 2)) = (i << 8) | i;

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

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    reinterpret_cast<Gain*>(p)->tag = TAG_GAIN;
    reinterpret_cast<Gain*>(p)->segment = 1;
    reinterpret_cast<Gain*>(p)->flag = 0;
    for (uint8_t i = 0; i < NUM_TRANSDUCERS; i++)
      *reinterpret_cast<uint16_t*>((p + sizeof(Gain) + i * 2)) =
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

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    reinterpret_cast<GainUpdate*>(p)->tag = TAG_GAIN_CHANGE_SEGMENT;
    reinterpret_cast<GainUpdate*>(p)->segment = 1;

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
    const uint16_t freq_div = 0xFFFF;
    const uint32_t sound_speed = 0x00000000;
    const uint16_t rep = 0xFFFF;

    size_t cnt = 0;
    while (cnt < size) {
      header->msg_id = get_msg_id();

      auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
      reinterpret_cast<FocusSTMHead*>(p)->tag = TAG_FOCI_STM;
      reinterpret_cast<FocusSTMHead*>(p)->flag = 0;
      size_t offset;
      if (cnt == 0) {
        reinterpret_cast<FocusSTMHead*>(p)->flag = FOCUS_STM_FLAG_BEGIN;
        reinterpret_cast<FocusSTMHead*>(p)->transition_mode =
            TRANSITION_MODE_IMMIDIATE;
        reinterpret_cast<FocusSTMHead*>(p)->freq_div = freq_div;
        reinterpret_cast<FocusSTMHead*>(p)->sound_speed = sound_speed;
        reinterpret_cast<FocusSTMHead*>(p)->rep = rep;
        offset = sizeof(FocusSTMHead);
      } else {
        offset = sizeof(FocusSTMSubseq);
      }
      auto send =
          std::min(size - cnt, (sizeof(RX_STR) - sizeof(Header) - offset) / 8);
      reinterpret_cast<FocusSTMHead*>(p)->send_num = static_cast<uint8_t>(send);

      cnt += send;

      if (cnt == size)
        reinterpret_cast<FocusSTMHead*>(p)->flag |=
            FOCUS_STM_FLAG_END | FOCUS_STM_FLAG_UPDATE;

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
    const uint16_t freq_div = 0xFFFF;
    const uint16_t rep = 0xFFFF;
    size_t cnt = 0;
    while (cnt < size) {
      header->msg_id = get_msg_id();
      auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
      reinterpret_cast<GainSTMHead*>(p)->tag = TAG_GAIN_STM;
      reinterpret_cast<GainSTMHead*>(p)->flag = 0;
      if (cnt == 0) {
        reinterpret_cast<GainSTMHead*>(p)->flag = GAIN_STM_FLAG_BEGIN;
        reinterpret_cast<GainSTMHead*>(p)->mode = mode;
        reinterpret_cast<GainSTMHead*>(p)->transition_mode =
            TRANSITION_MODE_IMMIDIATE;
        reinterpret_cast<GainSTMHead*>(p)->freq_div = freq_div;
        reinterpret_cast<GainSTMHead*>(p)->rep = rep;
      }
      reinterpret_cast<GainSTMHead*>(p)->flag |= GAIN_STM_FLAG_SEGMENT;
      cnt++;
      if (cnt == size)
        reinterpret_cast<GainSTMHead*>(p)->flag |=
            GAIN_STM_FLAG_END | GAIN_STM_FLAG_UPDATE;
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

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    reinterpret_cast<GainUpdate*>(p)->tag = TAG_GAIN_CHANGE_SEGMENT;
    reinterpret_cast<GainUpdate*>(p)->segment = 0;

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

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    reinterpret_cast<GainUpdate*>(p)->tag = TAG_GAIN_CHANGE_SEGMENT;
    reinterpret_cast<GainUpdate*>(p)->segment = 1;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, ERR_INVALID_SEGMENT_TRANSITION);
  }
}
