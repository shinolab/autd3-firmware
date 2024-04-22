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

  // segment 0
  {
    const uint8_t transition_mode = TRANSITION_MODE_EXT;
    const uint64_t transition_value = 0x0123456789ABCDEF;
    const uint32_t size = 65536;
    const uint32_t freq_div = 0x12345678;
    const uint32_t sound_speed = 0x9ABCDEF0;
    const uint32_t rep = 0x87654321;

    size_t cnt = 0;
    while (cnt < size) {
      header->msg_id = get_msg_id();

      auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
      data_body[0] = TAG_FOCUS_STM;
      auto offset = 4;
      if (cnt == 0) {
        data_body[1] = FOCUS_STM_FLAG_BEGIN;
        *reinterpret_cast<uint8_t*>(data_body + 3) = transition_mode;
        *reinterpret_cast<uint32_t*>(data_body + 4) = freq_div;
        *reinterpret_cast<uint32_t*>(data_body + 8) = sound_speed;
        *reinterpret_cast<uint32_t*>(data_body + 12) = rep;
        *reinterpret_cast<uint64_t*>(data_body + 16) = transition_value;
        offset += 20;
      } else {
        data_body[1] = 0;
      }
      auto send =
          std::min(size - cnt, (sizeof(RX_STR) - sizeof(Header) - offset) / 8);
      *reinterpret_cast<uint8_t*>(data_body + 2) = static_cast<uint8_t>(send);

      for (size_t i = 0; i < send; i++)
        *reinterpret_cast<uint64_t*>(data_body + offset + 8 * i) = buf[cnt + i];

      cnt += send;

      if (cnt == size)
        data_body[1] |= FOCUS_STM_FLAG_END | FOCUS_STM_FLAG_UPDATE;

      auto frame = to_frame_data(data);

      recv_ethercat(&frame[0]);
      update();

      const auto ack = _sTx.ack >> 8;
      ASSERT_EQ(ack, header->msg_id);
    }

    ASSERT_EQ(bram_read_controller(ADDR_STM_MODE0), STM_MODE_FOCUS);
    ASSERT_EQ(bram_read_controller(ADDR_STM_REQ_RD_SEGMENT), 0);
    ASSERT_EQ(bram_read_controller(ADDR_STM_CYCLE0), size - 1);
    ASSERT_EQ(bram_read_controller(ADDR_STM_FREQ_DIV0_0), 0x5678);
    ASSERT_EQ(bram_read_controller(ADDR_STM_FREQ_DIV0_1), 0x1234);
    ASSERT_EQ(bram_read_controller(ADDR_STM_SOUND_SPEED0_0), 0xDEF0);
    ASSERT_EQ(bram_read_controller(ADDR_STM_SOUND_SPEED0_1), 0x9ABC);
    ASSERT_EQ(bram_read_controller(ADDR_STM_REP0_0), 0x4321);
    ASSERT_EQ(bram_read_controller(ADDR_STM_REP0_1), 0x8765);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_MODE), transition_mode);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_0), 0xCDEF);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_1), 0x89AB);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_2), 0x4567);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_3), 0x0123);
    for (size_t i = 0; i < size; i++) {
      ASSERT_EQ(bram_read_stm(0, 4 * i), buf[i] & 0xFFFF);
      ASSERT_EQ(bram_read_stm(0, 4 * i + 1), (buf[i] >> 16) & 0xFFFF);
      ASSERT_EQ(bram_read_stm(0, 4 * i + 2), (buf[i] >> 32) & 0xFFFF);
      ASSERT_EQ(bram_read_stm(0, 4 * i + 3), (buf[i] >> 48) & 0xFFFF);
    }
  }

  // segment 1 without segment change
  {
    const uint8_t transition_mode = TRANSITION_MODE_SYS_TIME;
    const uint64_t transition_value = 0xFEDCBA9876543210;
    const uint32_t size = 1024;
    const uint32_t freq_div = 0x87654321;
    const uint32_t sound_speed = 0x0FEDCBA9;
    const uint32_t rep = 0x12345678;

    size_t cnt = 0;
    while (cnt < size) {
      header->msg_id = get_msg_id();

      auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
      data_body[0] = TAG_FOCUS_STM;
      auto offset = 4;
      if (cnt == 0) {
        data_body[1] = FOCUS_STM_FLAG_BEGIN | FOCUS_STM_FLAG_SEGMENT;
        *reinterpret_cast<uint8_t*>(data_body + 3) = transition_mode;
        *reinterpret_cast<uint32_t*>(data_body + 4) = freq_div;
        *reinterpret_cast<uint32_t*>(data_body + 8) = sound_speed;
        *reinterpret_cast<uint32_t*>(data_body + 12) = rep;
        *reinterpret_cast<uint64_t*>(data_body + 16) = transition_value;
        offset += 20;
      } else {
        data_body[1] = 0;
      }
      auto send =
          std::min(size - cnt, (sizeof(RX_STR) - sizeof(Header) - offset) / 8);
      *reinterpret_cast<uint8_t*>(data_body + 2) = static_cast<uint8_t>(send);

      for (size_t i = 0; i < send; i++)
        *reinterpret_cast<uint64_t*>(data_body + offset + 8 * i) = buf[cnt + i];

      cnt += send;

      if (cnt == size) data_body[1] |= FOCUS_STM_FLAG_END;

      auto frame = to_frame_data(data);

      recv_ethercat(&frame[0]);
      update();

      const auto ack = _sTx.ack >> 8;
      ASSERT_EQ(ack, header->msg_id);
    }

    ASSERT_EQ(bram_read_controller(ADDR_STM_MODE1), STM_MODE_FOCUS);
    ASSERT_EQ(bram_read_controller(ADDR_STM_REQ_RD_SEGMENT), 0);
    ASSERT_EQ(bram_read_controller(ADDR_STM_CYCLE1), size - 1);
    ASSERT_EQ(bram_read_controller(ADDR_STM_FREQ_DIV1_0), 0x4321);
    ASSERT_EQ(bram_read_controller(ADDR_STM_FREQ_DIV1_1), 0x8765);
    ASSERT_EQ(bram_read_controller(ADDR_STM_SOUND_SPEED1_0), 0xCBA9);
    ASSERT_EQ(bram_read_controller(ADDR_STM_SOUND_SPEED1_1), 0x0FED);
    ASSERT_EQ(bram_read_controller(ADDR_STM_REP1_0), 0x5678);
    ASSERT_EQ(bram_read_controller(ADDR_STM_REP1_1), 0x1234);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_MODE),
              TRANSITION_MODE_EXT);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_0), 0xCDEF);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_1), 0x89AB);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_2), 0x4567);
    ASSERT_EQ(bram_read_controller(ADDR_STM_TRANSITION_VALUE_3), 0x0123);
    for (size_t i = 0; i < size; i++) {
      ASSERT_EQ(bram_read_stm(1, 4 * i), buf[i] & 0xFFFF);
      ASSERT_EQ(bram_read_stm(1, 4 * i + 1), (buf[i] >> 16) & 0xFFFF);
      ASSERT_EQ(bram_read_stm(1, 4 * i + 2), (buf[i] >> 32) & 0xFFFF);
      ASSERT_EQ(bram_read_stm(1, 4 * i + 3), (buf[i] >> 48) & 0xFFFF);
    }
  }

  // change segment
  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const uint8_t transition_mode = TRANSITION_MODE_SYS_TIME;
    const uint64_t transition_value = 0xFEDCBA9876543210;

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_FOCUS_STM_CHANGE_SEGMENT;
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

TEST(Op, FocusSTMInvalidSegmentTransition) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  Header* header = reinterpret_cast<Header*>(data.data);
  header->slot_2_offset = 0;

  // segment 0: GainSTM
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
        data_body[1] = GAIN_STM_FLAG_BEGIN;
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
    data_body[0] = TAG_FOCUS_STM_CHANGE_SEGMENT;
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
    data_body[0] = TAG_FOCUS_STM_CHANGE_SEGMENT;
    data_body[1] = 1;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, ERR_INVALID_SEGMENT_TRANSITION);
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
    data_body[0] = TAG_FOCUS_STM;
    data_body[1] = FOCUS_STM_FLAG_BEGIN | FOCUS_STM_FLAG_END;
    *reinterpret_cast<uint16_t*>(data_body + 2) = static_cast<uint16_t>(2);
    *reinterpret_cast<uint32_t*>(data_body + 4) = freq_div;

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
    *reinterpret_cast<uint16_t*>(data_body + 2) = static_cast<uint16_t>(2);
    *reinterpret_cast<uint32_t*>(data_body + 4) = freq_div;

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
    data_body[0] = TAG_FOCUS_STM;
    data_body[1] = FOCUS_STM_FLAG_BEGIN | FOCUS_STM_FLAG_END;
    *reinterpret_cast<uint16_t*>(data_body + 2) = static_cast<uint16_t>(2);
    *reinterpret_cast<uint32_t*>(data_body + 4) = freq_div;

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
    *reinterpret_cast<uint16_t*>(data_body + 2) = static_cast<uint16_t>(2);
    *reinterpret_cast<uint32_t*>(data_body + 4) = freq_div;

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

    const uint16_t intensity = 10;  // 25us * 10 = 250us
    const uint16_t phase = 10;      // 25us * 2 = 250us
    const uint8_t flag = SILENCER_MODE_FIXED_COMPLETION_STEPS;

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

    const uint32_t freq_div = 5119;  // 1/20.48MHz/5119 < 250us

    header->msg_id = get_msg_id();

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_FOCUS_STM;
    data_body[1] = FOCUS_STM_FLAG_BEGIN | FOCUS_STM_FLAG_END;
    *reinterpret_cast<uint16_t*>(data_body + 2) = static_cast<uint16_t>(2);
    *reinterpret_cast<uint32_t*>(data_body + 4) = freq_div;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }
}
