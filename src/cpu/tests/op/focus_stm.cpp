#include <gtest/gtest.h>

#include "app.h"
#include "ecat.h"
#include "params.h"
#include "utils.hpp"

extern "C" {
extern TX_STR _sTx;
}

TEST(Op, FocusSTM) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  std::vector<uint64_t> buf;
  for (uint64_t i = 0; i < 65536; i++)
    buf.push_back(i << 48 | i << 32 | i << 16 | i);

  Header* header = reinterpret_cast<Header*>(data.data);
  header->slot_2_offset = 0;

  const uint32_t freq_div = 0x12345678;
  const uint32_t sound_speed = 0x9ABCDEF0;

  size_t cnt = 0;
  while (cnt < 65536) {
    header->msg_id = get_msg_id();

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_FOCUS_STM;
    auto offset = 4;
    if (cnt == 0) {
      data_body[1] = FOCUS_STM_FLAG_BEGIN;
      *reinterpret_cast<uint32_t*>(data_body + 4) = freq_div;
      *reinterpret_cast<uint32_t*>(data_body + 8) = sound_speed;
      *reinterpret_cast<uint16_t*>(data_body + 12) = 0;
      *reinterpret_cast<uint16_t*>(data_body + 14) = 0;
      offset += 12;
    } else {
      data_body[1] = 0;
    }
    auto send =
        std::min(65536 - cnt, (sizeof(RX_STR) - sizeof(Header) - offset) / 8);
    *reinterpret_cast<uint16_t*>(data_body + 2) = static_cast<uint16_t>(send);

    for (size_t i = 0; i < send; i++) {
      *reinterpret_cast<uint64_t*>(data_body + offset + 8 * i) = buf[cnt + i];
    }
    cnt += send;

    if (cnt == 65536) {
      data_body[1] = FOCUS_STM_FLAG_END;
    }

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }

  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_CTL_FLAG) &
                CTL_FLAG_OP_MODE,
            CTL_FLAG_OP_MODE);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_CTL_FLAG) &
                CTL_FLAG_STM_GAIN_MODE,
            0);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_CTL_FLAG) &
                CTL_FLAG_USE_STM_FINISH_IDX,
            0);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_CTL_FLAG) &
                CTL_FLAG_USE_STM_START_IDX,
            0);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_CYCLE), 65535);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FREQ_DIV_0),
            0x5678);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FREQ_DIV_1),
            0x1234);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_SOUND_SPEED_0),
            0xDEF0);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_SOUND_SPEED_1),
            0x9ABC);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_START_IDX), 0);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FINISH_IDX), 0);
  for (size_t i = 0; i < 65536; i++) {
    ASSERT_EQ(bram_read_raw(BRAM_SELECT_STM, 8 * i), buf[i] & 0xFFFF);
    ASSERT_EQ(bram_read_raw(BRAM_SELECT_STM, 8 * i + 1),
              (buf[i] >> 16) & 0xFFFF);
    ASSERT_EQ(bram_read_raw(BRAM_SELECT_STM, 8 * i + 2),
              (buf[i] >> 32) & 0xFFFF);
    ASSERT_EQ(bram_read_raw(BRAM_SELECT_STM, 8 * i + 3),
              (buf[i] >> 48) & 0xFFFF);
  }
}

TEST(Op, FocusSTMWithStartFinishIdx) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  std::vector<uint64_t> buf;
  for (uint64_t i = 0; i < 65536; i++)
    buf.push_back(i << 48 | i << 32 | i << 16 | i);

  Header* header = reinterpret_cast<Header*>(data.data);
  header->slot_2_offset = 0;

  const uint32_t freq_div = 0x12345678;
  const uint32_t sound_speed = 0x9ABCDEF0;
  const uint16_t start_idx = 0x0123;
  const uint16_t finish_idx = 0x4567;

  size_t cnt = 0;
  while (cnt < 65536) {
    header->msg_id = get_msg_id();

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_FOCUS_STM;
    auto offset = 4;
    if (cnt == 0) {
      data_body[1] = FOCUS_STM_FLAG_BEGIN | FOCUS_STM_FLAG_USE_START_IDX |
                     FOCUS_STM_FLAG_USE_FINISH_IDX;
      *reinterpret_cast<uint32_t*>(data_body + 4) = freq_div;
      *reinterpret_cast<uint32_t*>(data_body + 8) = sound_speed;
      *reinterpret_cast<uint16_t*>(data_body + 12) = start_idx;
      *reinterpret_cast<uint16_t*>(data_body + 14) = finish_idx;
      offset += 12;
    } else {
      data_body[1] = 0;
    }
    auto send =
        std::min(65536 - cnt, (sizeof(RX_STR) - sizeof(Header) - offset) / 8);
    *reinterpret_cast<uint16_t*>(data_body + 2) = static_cast<uint16_t>(send);

    for (size_t i = 0; i < send; i++) {
      *reinterpret_cast<uint64_t*>(data_body + offset + 8 * i) = buf[cnt + i];
    }
    cnt += send;

    if (cnt == 65536) {
      data_body[1] = FOCUS_STM_FLAG_END;
    }

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }

  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_CTL_FLAG) &
                CTL_FLAG_OP_MODE,
            CTL_FLAG_OP_MODE);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_CTL_FLAG) &
                CTL_FLAG_STM_GAIN_MODE,
            0);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_CTL_FLAG) &
                CTL_FLAG_USE_STM_FINISH_IDX,
            CTL_FLAG_USE_STM_FINISH_IDX);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_CTL_FLAG) &
                CTL_FLAG_USE_STM_START_IDX,
            CTL_FLAG_USE_STM_START_IDX);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_CYCLE), 65535);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FREQ_DIV_0),
            0x5678);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FREQ_DIV_1),
            0x1234);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_SOUND_SPEED_0),
            0xDEF0);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_SOUND_SPEED_1),
            0x9ABC);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_START_IDX),
            0x0123);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_STM_FINISH_IDX),
            0x4567);
  for (size_t i = 0; i < 65536; i++) {
    ASSERT_EQ(bram_read_raw(BRAM_SELECT_STM, 8 * i), buf[i] & 0xFFFF);
    ASSERT_EQ(bram_read_raw(BRAM_SELECT_STM, 8 * i + 1),
              (buf[i] >> 16) & 0xFFFF);
    ASSERT_EQ(bram_read_raw(BRAM_SELECT_STM, 8 * i + 2),
              (buf[i] >> 32) & 0xFFFF);
    ASSERT_EQ(bram_read_raw(BRAM_SELECT_STM, 8 * i + 3),
              (buf[i] >> 48) & 0xFFFF);
  }
}

TEST(Op, InvalidCompletionStepsIntensityFocusSTM) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const auto intensity = 10;  // 25us * 10 = 250us
    const auto phase = 2;       // 25us * 2 = 50us
    const auto flag = SILENCER_CTL_FLAG_FIXED_COMPLETION_STEPS |
                      SILENCER_CTL_FLAG_STRICT_MODE;

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
  }

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->slot_2_offset = 0;

    const uint32_t freq_div = 5120;  // 1/20.48MHz/5120 = 250us

    header->msg_id = get_msg_id();

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_FOCUS_STM;
    data_body[1] = FOCUS_STM_FLAG_BEGIN | FOCUS_STM_FLAG_END;
    *reinterpret_cast<uint32_t*>(data_body + 4) = freq_div;
    *reinterpret_cast<uint32_t*>(data_body + 8) = 0;
    *reinterpret_cast<uint16_t*>(data_body + 12) = 0;
    *reinterpret_cast<uint16_t*>(data_body + 14) = 0;
    *reinterpret_cast<uint16_t*>(data_body + 2) = static_cast<uint16_t>(2);

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
    data_body[0] = TAG_FOCUS_STM;
    data_body[1] = FOCUS_STM_FLAG_BEGIN | FOCUS_STM_FLAG_END;
    *reinterpret_cast<uint32_t*>(data_body + 4) = freq_div;
    *reinterpret_cast<uint32_t*>(data_body + 8) = 0;
    *reinterpret_cast<uint16_t*>(data_body + 12) = 0;
    *reinterpret_cast<uint16_t*>(data_body + 14) = 0;
    *reinterpret_cast<uint16_t*>(data_body + 2) = static_cast<uint16_t>(2);

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, ERR_FREQ_DIV_TOO_SMALL);
  }
}

TEST(Op, InvalidCompletionStepsPhaseFocusSTM) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const auto intensity = 2;  // 25us * 2 = 50us
    const auto phase = 10;     // 25us * 10 = 250us
    const auto flag = SILENCER_CTL_FLAG_FIXED_COMPLETION_STEPS |
                      SILENCER_CTL_FLAG_STRICT_MODE;

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
  }

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->slot_2_offset = 0;

    const uint32_t freq_div = 5120;  // 1/20.48MHz/5120 = 250us

    header->msg_id = get_msg_id();

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_FOCUS_STM;
    data_body[1] = FOCUS_STM_FLAG_BEGIN | FOCUS_STM_FLAG_END;
    *reinterpret_cast<uint32_t*>(data_body + 4) = freq_div;
    *reinterpret_cast<uint32_t*>(data_body + 8) = 0;
    *reinterpret_cast<uint16_t*>(data_body + 12) = 0;
    *reinterpret_cast<uint16_t*>(data_body + 14) = 0;
    *reinterpret_cast<uint16_t*>(data_body + 2) = static_cast<uint16_t>(2);

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
    data_body[0] = TAG_FOCUS_STM;
    data_body[1] = FOCUS_STM_FLAG_BEGIN | FOCUS_STM_FLAG_END;
    *reinterpret_cast<uint32_t*>(data_body + 4) = freq_div;
    *reinterpret_cast<uint32_t*>(data_body + 8) = 0;
    *reinterpret_cast<uint16_t*>(data_body + 12) = 0;
    *reinterpret_cast<uint16_t*>(data_body + 14) = 0;
    *reinterpret_cast<uint16_t*>(data_body + 2) = static_cast<uint16_t>(2);

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, ERR_FREQ_DIV_TOO_SMALL);
  }
}

TEST(Op, InvalidCompletionStepsWithPermisiveModeFocusSTM) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const auto intensity = 10;  // 25us * 10 = 250us
    const auto phase = 10;      // 25us * 2 = 250us
    const auto flag = SILENCER_CTL_FLAG_FIXED_COMPLETION_STEPS;

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
  }

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->slot_2_offset = 0;

    const uint32_t freq_div = 5119;  // 1/20.48MHz/5119 < 250us

    header->msg_id = get_msg_id();

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_FOCUS_STM;
    data_body[1] = FOCUS_STM_FLAG_BEGIN | FOCUS_STM_FLAG_END;
    *reinterpret_cast<uint32_t*>(data_body + 4) = freq_div;
    *reinterpret_cast<uint32_t*>(data_body + 8) = 0;
    *reinterpret_cast<uint16_t*>(data_body + 12) = 0;
    *reinterpret_cast<uint16_t*>(data_body + 14) = 0;
    *reinterpret_cast<uint16_t*>(data_body + 2) = static_cast<uint16_t>(2);

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }
}
