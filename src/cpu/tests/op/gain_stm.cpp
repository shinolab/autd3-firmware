#include <gtest/gtest.h>

#include "app.h"
#include "ecat.h"
#include "iodefine.h"
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
    const uint32_t freq_div = 0x12345678;
    const uint32_t rep = 0x87654321;

    size_t cnt = 0;
    while (cnt < size) {
      header->msg_id = get_msg_id();

      auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
      data_body[0] = TAG_GAIN_STM;
      auto offset = 2;
      if (cnt == 0) {
        data_body[1] = GAIN_STM_FLAG_BEGIN;
        *reinterpret_cast<uint8_t*>(data_body + 2) = mode;
        *reinterpret_cast<uint8_t*>(data_body + 3) = transition_mode;
        *reinterpret_cast<uint32_t*>(data_body + 8) = freq_div;
        *reinterpret_cast<uint32_t*>(data_body + 12) = rep;
        *reinterpret_cast<uint64_t*>(data_body + 16) = transition_value;
        offset += 22;
      } else {
        data_body[1] = 0;
      }

      for (size_t i = 0; i < NUM_TRANSDUCERS; i++)
        *reinterpret_cast<uint16_t*>(data_body + offset + 2 * i) = buf[cnt][i];

      cnt++;

      if (cnt == size) data_body[1] |= GAIN_STM_FLAG_END | GAIN_STM_FLAG_UPDATE;

      auto frame = to_frame_data(data);

      recv_ethercat(&frame[0]);
      update();

      const auto ack = _sTx.ack >> 8;
      ASSERT_EQ(ack, header->msg_id);
    }

    ASSERT_EQ(bram_read_controller(ADDR_STM_MODE0), STM_MODE_GAIN);
    ASSERT_EQ(bram_read_controller(ADDR_STM_REQ_RD_SEGMENT), 0);
    ASSERT_EQ(bram_read_controller(ADDR_STM_CYCLE0), size - 1);
    ASSERT_EQ(bram_read_controller(ADDR_STM_FREQ_DIV0_0), 0x5678);
    ASSERT_EQ(bram_read_controller(ADDR_STM_FREQ_DIV0_1), 0x1234);
    ASSERT_EQ(bram_read_controller(ADDR_STM_REP0_0), 0x4321);
    ASSERT_EQ(bram_read_controller(ADDR_STM_REP0_1), 0x8765);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_MODE), transition_mode);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_0), 0xCDEF);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_1), 0x89AB);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_2), 0x4567);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_3), 0x0123);
    for (uint16_t i = 0; i < size; i++)
      for (uint16_t j = 0; j < NUM_TRANSDUCERS; j++)
        ASSERT_EQ(bram_read_stm(0, 256 * i + j), i + j);
  }

  // segment 1 without segment change
  {
    const uint8_t transition_mode = TRANSITION_MODE_SYS_TIME;
    const uint64_t transition_value = 0xFEDCBA9876543210;
    const uint32_t size = 64;
    const uint8_t mode = GAIN_STM_MODE_INTENSITY_PHASE_FULL;
    const uint32_t freq_div = 0x87654321;
    const uint32_t rep = 0x12345678;

    size_t cnt = 0;
    while (cnt < size) {
      header->msg_id = get_msg_id();

      auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
      data_body[0] = TAG_GAIN_STM;
      auto offset = 2;
      if (cnt == 0) {
        data_body[1] = GAIN_STM_FLAG_BEGIN | GAIN_STM_FLAG_SEGMENT;
        *reinterpret_cast<uint8_t*>(data_body + 2) = mode;
        *reinterpret_cast<uint8_t*>(data_body + 3) = transition_mode;
        *reinterpret_cast<uint32_t*>(data_body + 8) = freq_div;
        *reinterpret_cast<uint32_t*>(data_body + 12) = rep;
        *reinterpret_cast<uint64_t*>(data_body + 16) = transition_value;
        offset += 22;
      } else {
        data_body[1] = 0;
      }

      for (size_t i = 0; i < NUM_TRANSDUCERS; i++)
        *reinterpret_cast<uint16_t*>(data_body + offset + 2 * i) = buf[cnt][i];

      cnt++;

      if (cnt == size) data_body[1] |= GAIN_STM_FLAG_END;

      auto frame = to_frame_data(data);

      recv_ethercat(&frame[0]);
      update();

      const auto ack = _sTx.ack >> 8;
      ASSERT_EQ(ack, header->msg_id);
    }

    ASSERT_EQ(bram_read_controller(ADDR_STM_MODE1), STM_MODE_GAIN);
    ASSERT_EQ(bram_read_controller(ADDR_STM_REQ_RD_SEGMENT), 0);
    ASSERT_EQ(bram_read_controller(ADDR_STM_CYCLE1), size - 1);
    ASSERT_EQ(bram_read_controller(ADDR_STM_FREQ_DIV1_0), 0x4321);
    ASSERT_EQ(bram_read_controller(ADDR_STM_FREQ_DIV1_1), 0x8765);
    ASSERT_EQ(bram_read_controller(ADDR_STM_REP1_0), 0x5678);
    ASSERT_EQ(bram_read_controller(ADDR_STM_REP1_1), 0x1234);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_MODE),
              TRANSITION_MODE_EXT);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_0), 0xCDEF);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_1), 0x89AB);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_2), 0x4567);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_3), 0x0123);
    for (uint16_t i = 0; i < size; i++)
      for (uint16_t j = 0; j < NUM_TRANSDUCERS; j++)
        ASSERT_EQ(bram_read_stm(1, 256 * i + j), i + j);
  }

  // change segment
  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const uint8_t transition_mode = TRANSITION_MODE_SYS_TIME;
    const uint64_t transition_value = 0xFEDCBA9876543210;

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_GAIN_STM_CHANGE_SEGMENT;
    data_body[1] = 1;
    data_body[2] = transition_mode;
    *reinterpret_cast<uint64_t*>(data_body + 8) = transition_value;

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
        *reinterpret_cast<uint32_t*>(data_body + 4) = freq_div;
        *reinterpret_cast<uint32_t*>(data_body + 8) = sound_speed;
        *reinterpret_cast<uint32_t*>(data_body + 12) = rep;
        offset += 20;
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

  // segment 1: Gain
  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_GAIN;
    data_body[1] = 1;
    *reinterpret_cast<uint16_t*>((data_body + 2)) = 0;

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

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_GAIN_STM_CHANGE_SEGMENT;
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
    data_body[0] = TAG_GAIN_STM_CHANGE_SEGMENT;
    data_body[1] = 1;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, ERR_INVALID_SEGMENT_TRANSITION);
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
    for (uint16_t j = 0; j < NUM_TRANSDUCERS; j++)
      tmp.emplace_back(static_cast<uint8_t>(i + j));
    buf.emplace_back(std::move(tmp));
  }

  Header* header = reinterpret_cast<Header*>(data.data);
  header->slot_2_offset = 0;

  const uint32_t size = 1024;
  const uint8_t mode = GAIN_STM_MODE_PHASE_FULL;
  const uint32_t freq_div = 0x12345678;
  const uint32_t rep = 0x87654321;

  size_t cnt = 0;
  while (cnt < size) {
    header->msg_id = get_msg_id();

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_GAIN_STM;
    auto offset = 2;
    if (cnt == 0) {
      data_body[1] = GAIN_STM_FLAG_BEGIN;
      *reinterpret_cast<uint8_t*>(data_body + 2) = mode;
      *reinterpret_cast<uint32_t*>(data_body + 8) = freq_div;
      *reinterpret_cast<uint32_t*>(data_body + 12) = rep;
      offset += 22;
    } else {
      data_body[1] = 0;
    }

    for (size_t i = 0; i < NUM_TRANSDUCERS; i++)
      *reinterpret_cast<uint16_t*>(data_body + offset + 2 * i) =
          (buf[cnt + 1][i] << 8) | buf[cnt][i];

    cnt += 2;

    if (cnt == size) data_body[1] |= GAIN_STM_FLAG_END | GAIN_STM_FLAG_UPDATE;
    data_body[1] |= (2 - 1) << 6;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }

  ASSERT_EQ(bram_read_controller(ADDR_STM_MODE0), STM_MODE_GAIN);
  ASSERT_EQ(bram_read_controller(ADDR_STM_REQ_RD_SEGMENT), 0);
  ASSERT_EQ(bram_read_controller(ADDR_STM_CYCLE0), size - 1);
  ASSERT_EQ(bram_read_controller(ADDR_STM_FREQ_DIV0_0), 0x5678);
  ASSERT_EQ(bram_read_controller(ADDR_STM_FREQ_DIV0_1), 0x1234);
  ASSERT_EQ(bram_read_controller(ADDR_STM_REP0_0), 0x4321);
  ASSERT_EQ(bram_read_controller(ADDR_STM_REP0_1), 0x8765);
  for (uint16_t i = 0; i < size; i++)
    for (uint16_t j = 0; j < NUM_TRANSDUCERS; j++)
      ASSERT_EQ(bram_read_stm(0, 256 * i + j),
                0xFF00 | static_cast<uint8_t>(i + j));
}

TEST(Op, GainSTMPhaseHalf) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  std::vector<std::vector<uint8_t>> buf;
  for (uint16_t i = 0; i < 1024; i++) {
    std::vector<uint8_t> tmp;
    tmp.reserve(NUM_TRANSDUCERS);
    for (uint16_t j = 0; j < NUM_TRANSDUCERS; j++)
      tmp.emplace_back(static_cast<uint8_t>(i + j));
    buf.emplace_back(std::move(tmp));
  }

  Header* header = reinterpret_cast<Header*>(data.data);
  header->slot_2_offset = 0;

  const uint32_t size = 1024;
  const uint8_t mode = GAIN_STM_MODE_PHASE_HALF;
  const uint32_t freq_div = 0x12345678;
  const uint32_t rep = 0x87654321;

  size_t cnt = 0;
  while (cnt < size) {
    header->msg_id = get_msg_id();

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_GAIN_STM;
    auto offset = 2;
    if (cnt == 0) {
      data_body[1] = GAIN_STM_FLAG_BEGIN;
      *reinterpret_cast<uint8_t*>(data_body + 2) = mode;
      *reinterpret_cast<uint32_t*>(data_body + 8) = freq_div;
      *reinterpret_cast<uint32_t*>(data_body + 12) = rep;
      offset += 22;
    } else {
      data_body[1] = 0;
    }

    for (size_t i = 0; i < NUM_TRANSDUCERS; i++)
      *reinterpret_cast<uint16_t*>(data_body + offset + 2 * i) =
          ((buf[cnt + 3][i] >> 4) << 12) | ((buf[cnt + 2][i] >> 4) << 8) |
          ((buf[cnt + 1][i] >> 4) << 4) | (buf[cnt][i] >> 4);

    cnt += 4;

    if (cnt == size) data_body[1] |= GAIN_STM_FLAG_END | GAIN_STM_FLAG_UPDATE;
    data_body[1] |= (4 - 1) << 6;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }

  ASSERT_EQ(bram_read_controller(ADDR_STM_MODE0), STM_MODE_GAIN);
  ASSERT_EQ(bram_read_controller(ADDR_STM_REQ_RD_SEGMENT), 0);
  ASSERT_EQ(bram_read_controller(ADDR_STM_CYCLE0), size - 1);
  ASSERT_EQ(bram_read_controller(ADDR_STM_FREQ_DIV0_0), 0x5678);
  ASSERT_EQ(bram_read_controller(ADDR_STM_FREQ_DIV0_1), 0x1234);
  ASSERT_EQ(bram_read_controller(ADDR_STM_REP0_0), 0x4321);
  ASSERT_EQ(bram_read_controller(ADDR_STM_REP0_1), 0x8765);
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
  const uint32_t freq_div = 0x12345678;

  header->msg_id = get_msg_id();

  auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
  data_body[0] = TAG_GAIN_STM;
  data_body[1] = GAIN_STM_FLAG_BEGIN;
  *reinterpret_cast<uint8_t*>(data_body + 2) = mode;
  *reinterpret_cast<uint32_t*>(data_body + 8) = freq_div;

  auto frame = to_frame_data(data);

  recv_ethercat(&frame[0]);
  update();

  const auto ack = _sTx.ack >> 8;
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
    const uint8_t flag =
        SILENCER_MODE_FIXED_COMPLETION_STEPS | SILENCER_FLAG_STRICT_MODE;

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_SILENCER;
    *reinterpret_cast<uint8_t*>(data_body + 1) = flag;
    *reinterpret_cast<uint16_t*>(data_body + 2) = intensity;
    *reinterpret_cast<uint16_t*>(data_body + 4) = phase;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->slot_2_offset = 0;

    const uint32_t freq_div = 5120;  // 1/20.48MHz/5120 = 250us

    header->msg_id = get_msg_id();

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_GAIN_STM;
    data_body[1] = GAIN_STM_FLAG_BEGIN | GAIN_STM_FLAG_END;
    *reinterpret_cast<uint8_t*>(data_body + 2) =
        GAIN_STM_MODE_INTENSITY_PHASE_FULL;
    *reinterpret_cast<uint32_t*>(data_body + 8) = freq_div;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->slot_2_offset = 0;

    const uint32_t freq_div = 5119;  // 1/20.48MHz/5119 < 250us

    header->msg_id = get_msg_id();

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_GAIN_STM;
    data_body[1] = GAIN_STM_FLAG_BEGIN | GAIN_STM_FLAG_END;
    *reinterpret_cast<uint8_t*>(data_body + 2) =
        GAIN_STM_MODE_INTENSITY_PHASE_FULL;
    *reinterpret_cast<uint32_t*>(data_body + 8) = freq_div;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, ERR_INVALID_SILENCER_SETTING);
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
    const uint8_t flag =
        SILENCER_MODE_FIXED_COMPLETION_STEPS | SILENCER_FLAG_STRICT_MODE;

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_SILENCER;
    *reinterpret_cast<uint8_t*>(data_body + 1) = flag;
    *reinterpret_cast<uint16_t*>(data_body + 2) = intensity;
    *reinterpret_cast<uint16_t*>(data_body + 4) = phase;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->slot_2_offset = 0;

    const uint32_t freq_div = 5120;  // 1/20.48MHz/5120 = 250us

    header->msg_id = get_msg_id();

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_GAIN_STM;
    data_body[1] = GAIN_STM_FLAG_BEGIN | GAIN_STM_FLAG_END;
    *reinterpret_cast<uint8_t*>(data_body + 2) =
        GAIN_STM_MODE_INTENSITY_PHASE_FULL;
    *reinterpret_cast<uint32_t*>(data_body + 8) = freq_div;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->slot_2_offset = 0;

    const uint32_t freq_div = 5119;  // 1/20.48MHz/5119 < 250us

    header->msg_id = get_msg_id();

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_GAIN_STM;
    data_body[1] = GAIN_STM_FLAG_BEGIN | GAIN_STM_FLAG_END;
    *reinterpret_cast<uint8_t*>(data_body + 2) =
        GAIN_STM_MODE_INTENSITY_PHASE_FULL;
    *reinterpret_cast<uint32_t*>(data_body + 8) = freq_div;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
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
    const uint8_t flag = SILENCER_MODE_FIXED_COMPLETION_STEPS;

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_SILENCER;
    *reinterpret_cast<uint16_t*>(data_body + 1) = flag;
    *reinterpret_cast<uint16_t*>(data_body + 2) = intensity;
    *reinterpret_cast<uint16_t*>(data_body + 4) = phase;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->slot_2_offset = 0;

    const uint32_t freq_div = 5119;  // 1/20.48MHz/5119 < 250us

    header->msg_id = get_msg_id();

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_GAIN_STM;
    data_body[1] = GAIN_STM_FLAG_BEGIN | GAIN_STM_FLAG_END;
    *reinterpret_cast<uint8_t*>(data_body + 2) =
        GAIN_STM_MODE_INTENSITY_PHASE_FULL;
    *reinterpret_cast<uint32_t*>(data_body + 4) = freq_div;
    *reinterpret_cast<uint16_t*>(data_body + 8) = 0;
    *reinterpret_cast<uint16_t*>(data_body + 10) = 0;

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
    const uint32_t freq_div = 0x12345678;
    const uint32_t rep = 0x87654321;

    size_t cnt = 0;
    while (cnt < size) {
      header->msg_id = get_msg_id();

      auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
      data_body[0] = TAG_GAIN_STM;
      auto offset = 2;
      if (cnt == 0) {
        data_body[1] = GAIN_STM_FLAG_BEGIN;
        *reinterpret_cast<uint8_t*>(data_body + 2) = mode;
        *reinterpret_cast<uint8_t*>(data_body + 3) = transition_mode;
        *reinterpret_cast<uint32_t*>(data_body + 8) = freq_div;
        *reinterpret_cast<uint32_t*>(data_body + 12) = rep;
        *reinterpret_cast<uint64_t*>(data_body + 16) = transition_value;
        offset += 22;
      } else {
        data_body[1] = 0;
      }

      for (size_t i = 0; i < NUM_TRANSDUCERS; i++)
        *reinterpret_cast<uint16_t*>(data_body + offset + 2 * i) = buf[cnt][i];

      cnt++;

      if (cnt == size) data_body[1] |= GAIN_STM_FLAG_END | GAIN_STM_FLAG_UPDATE;

      auto frame = to_frame_data(data);

      recv_ethercat(&frame[0]);
      update();

      if (cnt == size) {
        const auto ack = _sTx.ack >> 8;
        ASSERT_EQ(ack, ERR_MISS_TRANSITION_TIME);
      } else {
        const auto ack = _sTx.ack >> 8;
        ASSERT_EQ(ack, header->msg_id);
      }
    }
  }
}
