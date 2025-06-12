#include <gtest/gtest.h>

//
#include "app.h"
#include "ecat.h"
#include "foci_stm.h"
#include "gain_stm.h"
#include "iodefine.h"
#include "params.h"
#include "silencer.h"
#include "utils.hpp"

extern "C" {
extern TX_STR _sTx;
}

TEST(Op, GainSTMPhaseIntensityFull) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  std::vector<std::vector<uint16_t>> buf;
  for (uint16_t i = 0; i < 1024; i++) {
    std::vector<uint16_t> tmp;
    tmp.reserve(NUM_TRANSDUCERS);
    for (uint16_t j = 0; j < NUM_TRANSDUCERS; j++) tmp.emplace_back(i + j);
    buf.emplace_back(std::move(tmp));
  }

  Header* header = reinterpret_cast<Header*>(data.data);
  header->slot_2_offset = 0;

  // segment 0
  {
    const uint8_t transition_mode = TRANSITION_MODE_EXT;
    const uint64_t transition_value = 0x0123456789ABCDEF;
    const uint32_t size = 1024;
    const uint8_t mode = GAIN_STM_MODE_INTENSITY_PHASE_FULL;
    const uint16_t freq_div = 0x5678;
    const uint16_t rep = 0x4321;

    size_t cnt = 0;
    while (cnt < size) {
      header->msg_id = get_msg_id();

      auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
      reinterpret_cast<GainSTMHead*>(p)->tag = TAG_GAIN_STM;
      reinterpret_cast<GainSTMHead*>(p)->flag = 0;
      size_t offset;
      if (cnt == 0) {
        reinterpret_cast<GainSTMHead*>(p)->flag = GAIN_STM_FLAG_BEGIN;
        reinterpret_cast<GainSTMHead*>(p)->mode = mode;
        reinterpret_cast<GainSTMHead*>(p)->transition_mode = transition_mode;
        reinterpret_cast<GainSTMHead*>(p)->freq_div = freq_div;
        reinterpret_cast<GainSTMHead*>(p)->rep = rep;
        reinterpret_cast<GainSTMHead*>(p)->transition_value = transition_value;
        offset = sizeof(GainSTMHead);
      } else {
        offset = sizeof(GainSTMSubseq);
      }

      for (size_t i = 0; i < NUM_TRANSDUCERS; i++) *reinterpret_cast<uint16_t*>(p + offset + 2 * i) = buf[cnt][i];

      cnt++;

      if (cnt == size) reinterpret_cast<GainSTMSubseq*>(p)->flag |= GAIN_STM_FLAG_END | GAIN_STM_FLAG_UPDATE;

      auto frame = to_frame_data(data);

      recv_ethercat(&frame[0]);
      update();

      const auto ack = _sTx.ack >> 8;
      ASSERT_EQ(ack, header->msg_id);
    }

    ASSERT_EQ(bram_read_controller(ADDR_STM_MODE0), STM_MODE_GAIN);
    ASSERT_EQ(bram_read_controller(ADDR_STM_REQ_RD_SEGMENT), 0);
    ASSERT_EQ(bram_read_controller(ADDR_STM_CYCLE0), size - 1);
    ASSERT_EQ(bram_read_controller(ADDR_STM_FREQ_DIV0), 0x5678);
    ASSERT_EQ(bram_read_controller(ADDR_STM_REP0), 0x4321);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_MODE), transition_mode);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_0), 0xCDEF);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_1), 0x89AB);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_2), 0x4567);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_3), 0x0123);
    for (uint16_t i = 0; i < size; i++)
      for (uint16_t j = 0; j < NUM_TRANSDUCERS; j++) ASSERT_EQ(bram_read_stm(0, 256 * i + j), i + j);
  }

  // segment 1 without segment change
  {
    const uint32_t size = 64;
    const uint8_t mode = GAIN_STM_MODE_INTENSITY_PHASE_FULL;
    const uint16_t freq_div = 0x4321;
    const uint16_t rep = 0x5678;

    size_t cnt = 0;
    while (cnt < size) {
      header->msg_id = get_msg_id();

      auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
      reinterpret_cast<GainSTMHead*>(p)->tag = TAG_GAIN_STM;
      reinterpret_cast<GainSTMHead*>(p)->flag = 0;
      size_t offset;
      if (cnt == 0) {
        reinterpret_cast<GainSTMHead*>(p)->flag = GAIN_STM_FLAG_BEGIN;
        reinterpret_cast<GainSTMHead*>(p)->mode = mode;
        reinterpret_cast<GainSTMHead*>(p)->transition_mode = TRANSITION_MODE_NONE;
        reinterpret_cast<GainSTMHead*>(p)->freq_div = freq_div;
        reinterpret_cast<GainSTMHead*>(p)->rep = rep;
        reinterpret_cast<GainSTMHead*>(p)->transition_value = 0;
        offset = sizeof(GainSTMHead);
      } else {
        offset = sizeof(GainSTMSubseq);
      }
      reinterpret_cast<GainSTMHead*>(p)->flag |= GAIN_STM_FLAG_SEGMENT;

      for (size_t i = 0; i < NUM_TRANSDUCERS; i++) *reinterpret_cast<uint16_t*>(p + offset + 2 * i) = buf[cnt][i];

      cnt++;

      if (cnt == size) reinterpret_cast<GainSTMHead*>(p)->flag |= GAIN_STM_FLAG_END;

      auto frame = to_frame_data(data);

      recv_ethercat(&frame[0]);
      update();

      const auto ack = _sTx.ack >> 8;
      ASSERT_EQ(ack, header->msg_id);
    }

    ASSERT_EQ(bram_read_controller(ADDR_STM_MODE1), STM_MODE_GAIN);
    ASSERT_EQ(bram_read_controller(ADDR_STM_REQ_RD_SEGMENT), 0);
    ASSERT_EQ(bram_read_controller(ADDR_STM_CYCLE1), size - 1);
    ASSERT_EQ(bram_read_controller(ADDR_STM_FREQ_DIV1), 0x4321);
    ASSERT_EQ(bram_read_controller(ADDR_STM_REP1), 0x5678);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_MODE), TRANSITION_MODE_EXT);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_0), 0xCDEF);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_1), 0x89AB);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_2), 0x4567);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_3), 0x0123);
    for (uint16_t i = 0; i < size; i++)
      for (uint16_t j = 0; j < NUM_TRANSDUCERS; j++) ASSERT_EQ(bram_read_stm(1, 256 * i + j), i + j);
  }

  // change segment
  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const uint8_t transition_mode = TRANSITION_MODE_SYS_TIME;
    const uint64_t transition_value = 0xFEDCBA9876543210;

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    reinterpret_cast<FocusSTMUpdate*>(p)->tag = TAG_GAIN_STM_CHANGE_SEGMENT;
    reinterpret_cast<FocusSTMUpdate*>(p)->segment = 1;
    reinterpret_cast<FocusSTMUpdate*>(p)->transition_mode = transition_mode;
    reinterpret_cast<FocusSTMUpdate*>(p)->transition_value = transition_value;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);

    ASSERT_EQ(bram_read_controller(ADDR_STM_REQ_RD_SEGMENT), 1);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_MODE), transition_mode);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_0), 0x3210);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_1), 0x7654);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_2), 0xBA98);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_3), 0xFEDC);
  }
}

TEST(Op, GainSTMInvalidSegmentTransition) {
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
        reinterpret_cast<FocusSTMHead*>(p)->transition_mode = TRANSITION_MODE_IMMIDIATE;
        reinterpret_cast<FocusSTMHead*>(p)->freq_div = freq_div;
        reinterpret_cast<FocusSTMHead*>(p)->num_foci = 1;
        reinterpret_cast<FocusSTMHead*>(p)->sound_speed = sound_speed;
        reinterpret_cast<FocusSTMHead*>(p)->rep = rep;
        offset = sizeof(FocusSTMHead);
      } else {
        offset = sizeof(FocusSTMSubseq);
      }
      auto send = std::min(size - cnt, (sizeof(RX_STR) - sizeof(Header) - offset) / 8);
      *reinterpret_cast<uint8_t*>(p + 2) = static_cast<uint8_t>(send);

      cnt += send;

      if (cnt == size) reinterpret_cast<FocusSTMHead*>(p)->flag |= FOCUS_STM_FLAG_END | FOCUS_STM_FLAG_UPDATE;

      auto frame = to_frame_data(data);

      recv_ethercat(&frame[0]);
      update();

      const auto ack = _sTx.ack >> 8;
      ASSERT_EQ(ack, header->msg_id);
    }
  }

  // segment 1: Gain
  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    p[0] = TAG_GAIN;
    p[1] = 1;
    *reinterpret_cast<uint16_t*>((p + 2)) = 0;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }

  // change segment to 0
  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    p[0] = TAG_GAIN_STM_CHANGE_SEGMENT;
    p[1] = 0;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 12;
    ASSERT_EQ(ack, ERR_INVALID_SEGMENT_TRANSITION);
  }

  // change segment to 1
  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    p[0] = TAG_GAIN_STM_CHANGE_SEGMENT;
    p[1] = 1;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 12;
    ASSERT_EQ(ack, ERR_INVALID_SEGMENT_TRANSITION);
  }
}

TEST(Op, GainSTMInvalidTransitionMode) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  // segment 0 to 0
  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    reinterpret_cast<GainSTMHead*>(p)->tag = TAG_GAIN_STM;
    reinterpret_cast<GainSTMHead*>(p)->flag = GAIN_STM_FLAG_BEGIN;
    reinterpret_cast<GainSTMHead*>(p)->transition_mode = TRANSITION_MODE_SYNC_IDX;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 12;
    ASSERT_EQ(ERR_INVALID_TRANSITION_MODE, ack);
  }

  // segment 0 to 1
  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    reinterpret_cast<GainSTMHead*>(p)->tag = TAG_GAIN_STM;
    reinterpret_cast<GainSTMHead*>(p)->flag = GAIN_STM_FLAG_BEGIN | GAIN_STM_FLAG_SEGMENT;
    reinterpret_cast<GainSTMHead*>(p)->rep = 0;
    reinterpret_cast<GainSTMHead*>(p)->transition_mode = TRANSITION_MODE_IMMIDIATE;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 12;
    ASSERT_EQ(ERR_INVALID_TRANSITION_MODE, ack);
  }

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;
    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);

    reinterpret_cast<GainSTMHead*>(p)->tag = TAG_GAIN_STM;
    reinterpret_cast<GainSTMHead*>(p)->flag = GAIN_STM_FLAG_BEGIN | GAIN_STM_FLAG_SEGMENT;
    reinterpret_cast<GainSTMHead*>(p)->freq_div = 0xFFFF;
    reinterpret_cast<GainSTMHead*>(p)->rep = 0xFFFF;
    reinterpret_cast<GainSTMHead*>(p)->transition_mode = TRANSITION_MODE_NONE;
    auto frame = to_frame_data(data);
    recv_ethercat(&frame[0]);
    update();
    auto ack = _sTx.ack >> 8;
    ASSERT_EQ(header->msg_id, ack);

    header->msg_id = get_msg_id();
    reinterpret_cast<GainSTMSubseq*>(p)->tag = TAG_GAIN_STM;
    reinterpret_cast<GainSTMSubseq*>(p)->flag = GAIN_STM_FLAG_END | GAIN_STM_FLAG_SEGMENT;
    frame = to_frame_data(data);
    recv_ethercat(&frame[0]);
    update();
    ack = _sTx.ack >> 8;
    ASSERT_EQ(header->msg_id, ack);

    header->msg_id = get_msg_id();
    reinterpret_cast<GainSTMUpdate*>(p)->tag = TAG_GAIN_STM_CHANGE_SEGMENT;
    reinterpret_cast<GainSTMUpdate*>(p)->segment = 1;
    reinterpret_cast<GainSTMUpdate*>(p)->transition_mode = TRANSITION_MODE_SYNC_IDX;
    reinterpret_cast<GainSTMUpdate*>(p)->transition_value = 0;
    frame = to_frame_data(data);
    recv_ethercat(&frame[0]);
    update();
    ack = _sTx.ack >> 12;
    ASSERT_EQ(ERR_INVALID_TRANSITION_MODE, ack);
  }
}

TEST(Op, GainSTMPhaseFull) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  std::vector<std::vector<uint8_t>> buf;
  for (uint16_t i = 0; i < 1024; i++) {
    std::vector<uint8_t> tmp;
    tmp.reserve(NUM_TRANSDUCERS);
    for (uint16_t j = 0; j < NUM_TRANSDUCERS; j++) tmp.emplace_back(static_cast<uint8_t>(i + j));
    buf.emplace_back(std::move(tmp));
  }

  Header* header = reinterpret_cast<Header*>(data.data);
  header->slot_2_offset = 0;

  const uint32_t size = 1024;
  const uint8_t mode = GAIN_STM_MODE_PHASE_FULL;
  const uint16_t freq_div = 0x5678;
  const uint16_t rep = 0x4321;

  size_t cnt = 0;
  while (cnt < size) {
    header->msg_id = get_msg_id();

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    reinterpret_cast<GainSTMHead*>(p)->tag = TAG_GAIN_STM;
    reinterpret_cast<GainSTMHead*>(p)->flag = 0;
    size_t offset;
    if (cnt == 0) {
      reinterpret_cast<GainSTMHead*>(p)->flag = GAIN_STM_FLAG_BEGIN;
      reinterpret_cast<GainSTMHead*>(p)->mode = mode;
      reinterpret_cast<GainSTMHead*>(p)->transition_mode = TRANSITION_MODE_IMMIDIATE;
      reinterpret_cast<GainSTMHead*>(p)->freq_div = freq_div;
      reinterpret_cast<GainSTMHead*>(p)->rep = rep;
      offset = sizeof(GainSTMHead);
    } else {
      offset = sizeof(GainSTMSubseq);
    }

    for (size_t i = 0; i < NUM_TRANSDUCERS; i++) *reinterpret_cast<uint16_t*>(p + offset + 2 * i) = (buf[cnt + 1][i] << 8) | buf[cnt][i];

    cnt += 2;

    if (cnt == size) reinterpret_cast<GainSTMHead*>(p)->flag |= GAIN_STM_FLAG_END | GAIN_STM_FLAG_UPDATE;
    reinterpret_cast<GainSTMHead*>(p)->flag |= (2 - 1) << 6;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }

  ASSERT_EQ(bram_read_controller(ADDR_STM_MODE0), STM_MODE_GAIN);
  ASSERT_EQ(bram_read_controller(ADDR_STM_REQ_RD_SEGMENT), 0);
  ASSERT_EQ(bram_read_controller(ADDR_STM_CYCLE0), size - 1);
  ASSERT_EQ(bram_read_controller(ADDR_STM_FREQ_DIV0), 0x5678);
  ASSERT_EQ(bram_read_controller(ADDR_STM_REP0), 0x4321);
  for (uint16_t i = 0; i < size; i++)
    for (uint16_t j = 0; j < NUM_TRANSDUCERS; j++) ASSERT_EQ(bram_read_stm(0, 256 * i + j), 0xFF00 | static_cast<uint8_t>(i + j));
}

TEST(Op, GainSTMPhaseHalf) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  std::vector<std::vector<uint8_t>> buf;
  for (uint16_t i = 0; i < 1024; i++) {
    std::vector<uint8_t> tmp;
    tmp.reserve(NUM_TRANSDUCERS);
    for (uint16_t j = 0; j < NUM_TRANSDUCERS; j++) tmp.emplace_back(static_cast<uint8_t>(i + j));
    buf.emplace_back(std::move(tmp));
  }

  Header* header = reinterpret_cast<Header*>(data.data);
  header->slot_2_offset = 0;

  const uint32_t size = 1024;
  const uint8_t mode = GAIN_STM_MODE_PHASE_HALF;
  const uint16_t freq_div = 0x5678;
  const uint16_t rep = 0x4321;

  size_t cnt = 0;
  while (cnt < size) {
    header->msg_id = get_msg_id();

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    reinterpret_cast<GainSTMHead*>(p)->tag = TAG_GAIN_STM;
    reinterpret_cast<GainSTMHead*>(p)->flag = 0;
    size_t offset;
    if (cnt == 0) {
      reinterpret_cast<GainSTMHead*>(p)->flag = GAIN_STM_FLAG_BEGIN;
      reinterpret_cast<GainSTMHead*>(p)->mode = mode;
      reinterpret_cast<GainSTMHead*>(p)->transition_mode = TRANSITION_MODE_IMMIDIATE;
      reinterpret_cast<GainSTMHead*>(p)->freq_div = freq_div;
      reinterpret_cast<GainSTMHead*>(p)->rep = rep;
      offset = sizeof(GainSTMHead);
    } else {
      offset = sizeof(GainSTMSubseq);
    }

    for (size_t i = 0; i < NUM_TRANSDUCERS; i++)
      *reinterpret_cast<uint16_t*>(p + offset + 2 * i) =
          ((buf[cnt + 3][i] >> 4) << 12) | ((buf[cnt + 2][i] >> 4) << 8) | ((buf[cnt + 1][i] >> 4) << 4) | (buf[cnt][i] >> 4);

    cnt += 4;

    if (cnt == size) reinterpret_cast<GainSTMHead*>(p)->flag |= GAIN_STM_FLAG_END | GAIN_STM_FLAG_UPDATE;
    reinterpret_cast<GainSTMHead*>(p)->flag |= (4 - 1) << 6;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }

  ASSERT_EQ(bram_read_controller(ADDR_STM_MODE0), STM_MODE_GAIN);
  ASSERT_EQ(bram_read_controller(ADDR_STM_REQ_RD_SEGMENT), 0);
  ASSERT_EQ(bram_read_controller(ADDR_STM_CYCLE0), size - 1);
  ASSERT_EQ(bram_read_controller(ADDR_STM_FREQ_DIV0), 0x5678);
  ASSERT_EQ(bram_read_controller(ADDR_STM_REP0), 0x4321);
  for (uint16_t i = 0; i < size; i++)
    for (uint16_t j = 0; j < NUM_TRANSDUCERS; j++) {
      const auto phase = static_cast<uint8_t>(i + j) >> 4;
      ASSERT_EQ(bram_read_stm(0, 256 * i + j), 0xFF00 | phase << 4 | phase);
    }
}

TEST(Op, GainSTMInvalidMode) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  Header* header = reinterpret_cast<Header*>(data.data);
  header->slot_2_offset = 0;

  const uint8_t mode = 0xFF;
  const uint16_t freq_div = 0x5678;

  header->msg_id = get_msg_id();

  auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
  reinterpret_cast<GainSTMHead*>(p)->tag = TAG_GAIN_STM;
  reinterpret_cast<GainSTMHead*>(p)->flag = GAIN_STM_FLAG_BEGIN;
  reinterpret_cast<GainSTMHead*>(p)->mode = mode;
  reinterpret_cast<GainSTMHead*>(p)->freq_div = freq_div;
  reinterpret_cast<GainSTMHead*>(p)->transition_mode = TRANSITION_MODE_IMMIDIATE;

  auto frame = to_frame_data(data);

  recv_ethercat(&frame[0]);
  update();

  const auto ack = _sTx.ack >> 12;
  ASSERT_EQ(ack, ERR_INVALID_GAIN_STM_MODE);
}

TEST(Op, InvalidCompletionStepsIntensityGainSTM) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const uint16_t intensity = 10;  // 25us * 10 = 250us
    const uint16_t phase = 2;       // 25us * 2 = 50us
    const uint8_t flag = SILENCER_FLAG_STRICT_MODE;

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    reinterpret_cast<ConfigSilencer*>(p)->tag = TAG_SILENCER;
    reinterpret_cast<ConfigSilencer*>(p)->flag = flag;
    reinterpret_cast<ConfigSilencer*>(p)->value_intensity = intensity;
    reinterpret_cast<ConfigSilencer*>(p)->value_phase = phase;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->slot_2_offset = 0;

    const uint16_t freq_div = 10;

    header->msg_id = get_msg_id();

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    reinterpret_cast<GainSTMHead*>(p)->tag = TAG_GAIN_STM;
    reinterpret_cast<GainSTMHead*>(p)->flag = GAIN_STM_FLAG_BEGIN | GAIN_STM_FLAG_END;
    reinterpret_cast<GainSTMHead*>(p)->mode = GAIN_STM_MODE_INTENSITY_PHASE_FULL;
    reinterpret_cast<GainSTMHead*>(p)->freq_div = freq_div;
    reinterpret_cast<GainSTMHead*>(p)->transition_mode = TRANSITION_MODE_IMMIDIATE;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->slot_2_offset = 0;

    const uint16_t freq_div = 9;

    header->msg_id = get_msg_id();

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    reinterpret_cast<GainSTMHead*>(p)->tag = TAG_GAIN_STM;
    reinterpret_cast<GainSTMHead*>(p)->flag = GAIN_STM_FLAG_BEGIN | GAIN_STM_FLAG_END;
    reinterpret_cast<GainSTMHead*>(p)->mode = GAIN_STM_MODE_INTENSITY_PHASE_FULL;
    reinterpret_cast<GainSTMHead*>(p)->freq_div = freq_div;
    reinterpret_cast<GainSTMHead*>(p)->transition_mode = TRANSITION_MODE_IMMIDIATE;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 12;
    ASSERT_EQ(ack, ERR_INVALID_SILENCER_SETTING);
  }

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    reinterpret_cast<GainSTMHead*>(p)->tag = TAG_GAIN_STM;
    reinterpret_cast<GainSTMHead*>(p)->flag = GAIN_STM_FLAG_BEGIN;
    reinterpret_cast<GainSTMHead*>(p)->mode = GAIN_STM_MODE_INTENSITY_PHASE_FULL;
    reinterpret_cast<GainSTMHead*>(p)->freq_div = 0xFFFF;
    reinterpret_cast<GainSTMHead*>(p)->rep = 0xFFFF;
    reinterpret_cast<GainSTMHead*>(p)->transition_mode = TRANSITION_MODE_IMMIDIATE;
    auto frame = to_frame_data(data);
    recv_ethercat(&frame[0]);
    update();
    auto ack = _sTx.ack >> 8;
    ASSERT_EQ(header->msg_id, ack);

    header->msg_id = get_msg_id();
    reinterpret_cast<GainSTMSubseq*>(p)->tag = TAG_GAIN_STM;
    reinterpret_cast<GainSTMSubseq*>(p)->flag = GAIN_STM_FLAG_END;
    frame = to_frame_data(data);
    recv_ethercat(&frame[0]);
    update();
    ack = _sTx.ack >> 8;
    ASSERT_EQ(header->msg_id, ack);

    header->msg_id = get_msg_id();
    reinterpret_cast<ConfigSilencer*>(p)->tag = TAG_SILENCER;
    reinterpret_cast<ConfigSilencer*>(p)->flag = SILENCER_FLAG_STRICT_MODE;
    reinterpret_cast<ConfigSilencer*>(p)->value_intensity = 10;
    reinterpret_cast<ConfigSilencer*>(p)->value_phase = 40;
    frame = to_frame_data(data);
    recv_ethercat(&frame[0]);
    update();
    ack = _sTx.ack >> 8;
    ASSERT_EQ(header->msg_id, ack);

    header->msg_id = get_msg_id();
    reinterpret_cast<GainSTMHead*>(p)->tag = TAG_GAIN_STM;
    reinterpret_cast<GainSTMHead*>(p)->flag = GAIN_STM_FLAG_BEGIN | GAIN_STM_FLAG_SEGMENT;
    reinterpret_cast<GainSTMHead*>(p)->mode = GAIN_STM_MODE_INTENSITY_PHASE_FULL;
    reinterpret_cast<GainSTMHead*>(p)->freq_div = 40;
    reinterpret_cast<GainSTMHead*>(p)->rep = 0xFFFF;
    reinterpret_cast<GainSTMHead*>(p)->transition_mode = TRANSITION_MODE_NONE;
    frame = to_frame_data(data);
    recv_ethercat(&frame[0]);
    update();
    ack = _sTx.ack >> 8;
    ASSERT_EQ(header->msg_id, ack);

    header->msg_id = get_msg_id();
    reinterpret_cast<GainSTMSubseq*>(p)->tag = TAG_GAIN_STM;
    reinterpret_cast<GainSTMSubseq*>(p)->flag = GAIN_STM_FLAG_END | GAIN_STM_FLAG_SEGMENT;
    frame = to_frame_data(data);
    recv_ethercat(&frame[0]);
    update();
    ack = _sTx.ack >> 8;
    ASSERT_EQ(header->msg_id, ack);

    header->msg_id = get_msg_id();
    reinterpret_cast<ConfigSilencer*>(p)->tag = TAG_SILENCER;
    reinterpret_cast<ConfigSilencer*>(p)->flag = SILENCER_FLAG_STRICT_MODE;
    reinterpret_cast<ConfigSilencer*>(p)->value_intensity = 10;
    reinterpret_cast<ConfigSilencer*>(p)->value_phase = 80;
    frame = to_frame_data(data);
    recv_ethercat(&frame[0]);
    update();
    ack = _sTx.ack >> 8;
    ASSERT_EQ(header->msg_id, ack);

    header->msg_id = get_msg_id();
    reinterpret_cast<GainSTMUpdate*>(p)->tag = TAG_GAIN_STM_CHANGE_SEGMENT;
    reinterpret_cast<GainSTMUpdate*>(p)->segment = 1;
    reinterpret_cast<GainSTMUpdate*>(p)->transition_mode = TRANSITION_MODE_IMMIDIATE;
    reinterpret_cast<GainSTMUpdate*>(p)->transition_value = 0;
    frame = to_frame_data(data);
    recv_ethercat(&frame[0]);
    update();
    ack = _sTx.ack >> 12;
    ASSERT_EQ(ERR_INVALID_SILENCER_SETTING, ack);
  }
}

TEST(Op, InvalidCompletionStepsPhaseGainSTM) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const uint16_t intensity = 2;  // 25us * 2 = 50us
    const uint16_t phase = 10;     // 25us * 10 = 250us
    const uint8_t flag = SILENCER_FLAG_STRICT_MODE;

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    reinterpret_cast<ConfigSilencer*>(p)->tag = TAG_SILENCER;
    reinterpret_cast<ConfigSilencer*>(p)->flag = flag;
    reinterpret_cast<ConfigSilencer*>(p)->value_intensity = intensity;
    reinterpret_cast<ConfigSilencer*>(p)->value_phase = phase;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->slot_2_offset = 0;

    const uint16_t freq_div = 10;

    header->msg_id = get_msg_id();

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    reinterpret_cast<GainSTMHead*>(p)->tag = TAG_GAIN_STM;
    reinterpret_cast<GainSTMHead*>(p)->flag = GAIN_STM_FLAG_BEGIN | GAIN_STM_FLAG_END;
    reinterpret_cast<GainSTMHead*>(p)->mode = GAIN_STM_MODE_INTENSITY_PHASE_FULL;
    reinterpret_cast<GainSTMHead*>(p)->freq_div = freq_div;
    reinterpret_cast<GainSTMHead*>(p)->transition_mode = TRANSITION_MODE_IMMIDIATE;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->slot_2_offset = 0;

    const uint16_t freq_div = 9;

    header->msg_id = get_msg_id();

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    reinterpret_cast<GainSTMHead*>(p)->tag = TAG_GAIN_STM;
    reinterpret_cast<GainSTMHead*>(p)->flag = GAIN_STM_FLAG_BEGIN | GAIN_STM_FLAG_END;
    reinterpret_cast<GainSTMHead*>(p)->mode = GAIN_STM_MODE_INTENSITY_PHASE_FULL;
    reinterpret_cast<GainSTMHead*>(p)->freq_div = freq_div;
    reinterpret_cast<GainSTMHead*>(p)->transition_mode = TRANSITION_MODE_IMMIDIATE;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 12;
    ASSERT_EQ(ack, ERR_INVALID_SILENCER_SETTING);
  }
}

TEST(Op, InvalidCompletionStepsWithPermisiveModeGainSTM) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const uint16_t intensity = 10;  // 25us *10 = 250us
    const uint16_t phase = 10;      // 25us * 10 = 250us
    const uint8_t flag = 0;

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    p[0] = TAG_SILENCER;
    *reinterpret_cast<uint16_t*>(p + 1) = flag;
    *reinterpret_cast<uint16_t*>(p + 2) = intensity;
    *reinterpret_cast<uint16_t*>(p + 4) = phase;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->slot_2_offset = 0;

    const uint16_t freq_div = 9;

    header->msg_id = get_msg_id();

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    reinterpret_cast<GainSTMHead*>(p)->tag = TAG_GAIN_STM;
    reinterpret_cast<GainSTMHead*>(p)->flag = GAIN_STM_FLAG_BEGIN | GAIN_STM_FLAG_END;
    reinterpret_cast<GainSTMHead*>(p)->mode = GAIN_STM_MODE_INTENSITY_PHASE_FULL;
    reinterpret_cast<GainSTMHead*>(p)->transition_mode = TRANSITION_MODE_IMMIDIATE;
    reinterpret_cast<GainSTMHead*>(p)->freq_div = freq_div;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }
}

TEST(Op, STMMissTransitionTime) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  std::vector<std::vector<uint16_t>> buf;
  for (uint16_t i = 0; i < 1024; i++) {
    std::vector<uint16_t> tmp;
    tmp.reserve(NUM_TRANSDUCERS);
    for (uint16_t j = 0; j < NUM_TRANSDUCERS; j++) tmp.emplace_back(i + j);
    buf.emplace_back(std::move(tmp));
  }

  Header* header = reinterpret_cast<Header*>(data.data);
  header->slot_2_offset = 0;

  ECATC.DC_SYS_TIME.LONGLONG = 1;
  {
    const uint8_t transition_mode = TRANSITION_MODE_SYS_TIME;
    const uint64_t transition_value = SYS_TIME_TRANSITION_MARGIN;
    const uint32_t size = 1024;
    const uint8_t mode = GAIN_STM_MODE_INTENSITY_PHASE_FULL;
    const uint16_t freq_div = 0x5678;
    const uint16_t rep = 0x4321;

    size_t cnt = 0;
    while (cnt < size) {
      header->msg_id = get_msg_id();

      auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
      reinterpret_cast<GainSTMHead*>(p)->tag = TAG_GAIN_STM;
      reinterpret_cast<GainSTMHead*>(p)->flag = 0;
      size_t offset;
      if (cnt == 0) {
        reinterpret_cast<GainSTMHead*>(p)->flag = GAIN_STM_FLAG_BEGIN;
        reinterpret_cast<GainSTMHead*>(p)->mode = mode;
        reinterpret_cast<GainSTMHead*>(p)->transition_mode = transition_mode;
        reinterpret_cast<GainSTMHead*>(p)->freq_div = freq_div;
        reinterpret_cast<GainSTMHead*>(p)->rep = rep;
        reinterpret_cast<GainSTMHead*>(p)->transition_value = transition_value;
        offset = sizeof(GainSTMHead);
      } else {
        offset = sizeof(GainSTMSubseq);
      }
      reinterpret_cast<GainSTMHead*>(p)->flag |= GAIN_STM_FLAG_SEGMENT;
      for (size_t i = 0; i < NUM_TRANSDUCERS; i++) *reinterpret_cast<uint16_t*>(p + offset + 2 * i) = buf[cnt][i];

      cnt++;

      if (cnt == size) reinterpret_cast<GainSTMHead*>(p)->flag |= GAIN_STM_FLAG_END | GAIN_STM_FLAG_UPDATE;

      auto frame = to_frame_data(data);

      recv_ethercat(&frame[0]);
      update();

      if (cnt == size) {
        const auto ack = _sTx.ack >> 12;
        ASSERT_EQ(ack, ERR_MISS_TRANSITION_TIME);
      } else {
        const auto ack = _sTx.ack >> 8;
        ASSERT_EQ(ack, header->msg_id);
      }
    }
  }
}
