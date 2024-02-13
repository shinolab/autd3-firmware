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

      for (size_t i = 0; i < send; i++)
        *reinterpret_cast<uint64_t*>(data_body + offset + 8 * i) = buf[cnt + i];

      cnt += send;

      if (cnt == size) {
        data_body[1] = FOCUS_STM_FLAG_END;
      }

      auto frame = to_frame_data(data);

      recv_ethercat(&frame[0]);
      update();

      const auto ack = _sTx.ack >> 8;
      ASSERT_EQ(ack, header->msg_id);
    }

    ASSERT_EQ(bram_read_controller(BRAM_ADDR_STM_MODE), STM_MODE_FOCUS);
    ASSERT_EQ(bram_read_controller(BRAM_ADDR_STM_REQ_RD_SEGMENT), 0);
    ASSERT_EQ(bram_read_controller(BRAM_ADDR_STM_CYCLE_0), size - 1);
    ASSERT_EQ(bram_read_controller(BRAM_ADDR_STM_FREQ_DIV_0_0), 0x5678);
    ASSERT_EQ(bram_read_controller(BRAM_ADDR_STM_FREQ_DIV_0_1), 0x1234);
    ASSERT_EQ(bram_read_controller(BRAM_ADDR_STM_SOUND_SPEED_0), 0xDEF0);
    ASSERT_EQ(bram_read_controller(BRAM_ADDR_STM_SOUND_SPEED_1), 0x9ABC);
    ASSERT_EQ(bram_read_controller(BRAM_ADDR_STM_REP_0), 0x4321);
    ASSERT_EQ(bram_read_controller(BRAM_ADDR_STM_REP_1), 0x8765);
    for (size_t i = 0; i < size; i++) {
      ASSERT_EQ(bram_read_stm(0, 4 * i), buf[i] & 0xFFFF);
      ASSERT_EQ(bram_read_stm(0, 4 * i + 1), (buf[i] >> 16) & 0xFFFF);
      ASSERT_EQ(bram_read_stm(0, 4 * i + 2), (buf[i] >> 32) & 0xFFFF);
      ASSERT_EQ(bram_read_stm(0, 4 * i + 3), (buf[i] >> 48) & 0xFFFF);
    }
  }

  // segment 1
  {
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
        data_body[1] = FOCUS_STM_FLAG_BEGIN;
        *reinterpret_cast<uint8_t*>(data_body + 3) = 1;
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

      for (size_t i = 0; i < send; i++)
        *reinterpret_cast<uint64_t*>(data_body + offset + 8 * i) = buf[cnt + i];

      cnt += send;

      if (cnt == size) {
        data_body[1] = FOCUS_STM_FLAG_END;
      }

      auto frame = to_frame_data(data);

      recv_ethercat(&frame[0]);
      update();

      const auto ack = _sTx.ack >> 8;
      ASSERT_EQ(ack, header->msg_id);
    }

    ASSERT_EQ(bram_read_controller(BRAM_ADDR_STM_MODE), STM_MODE_FOCUS);
    ASSERT_EQ(bram_read_controller(BRAM_ADDR_STM_REQ_RD_SEGMENT), 1);
    ASSERT_EQ(bram_read_controller(BRAM_ADDR_STM_CYCLE_1), size - 1);
    ASSERT_EQ(bram_read_controller(BRAM_ADDR_STM_FREQ_DIV_1_0), 0x4321);
    ASSERT_EQ(bram_read_controller(BRAM_ADDR_STM_FREQ_DIV_1_1), 0x8765);
    ASSERT_EQ(bram_read_controller(BRAM_ADDR_STM_SOUND_SPEED_0), 0xCBA9);
    ASSERT_EQ(bram_read_controller(BRAM_ADDR_STM_SOUND_SPEED_1), 0x0FED);
    ASSERT_EQ(bram_read_controller(BRAM_ADDR_STM_REP_0), 0x5678);
    ASSERT_EQ(bram_read_controller(BRAM_ADDR_STM_REP_1), 0x1234);
    for (size_t i = 0; i < size; i++) {
      ASSERT_EQ(bram_read_stm(1, 4 * i), buf[i] & 0xFFFF);
      ASSERT_EQ(bram_read_stm(1, 4 * i + 1), (buf[i] >> 16) & 0xFFFF);
      ASSERT_EQ(bram_read_stm(1, 4 * i + 2), (buf[i] >> 32) & 0xFFFF);
      ASSERT_EQ(bram_read_stm(1, 4 * i + 3), (buf[i] >> 48) & 0xFFFF);
    }
  }
}

TEST(Op, FocusSTMInvalidSegment) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  Header* header = reinterpret_cast<Header*>(data.data);
  header->slot_2_offset = 0;

  header->msg_id = get_msg_id();

  auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
  data_body[0] = TAG_FOCUS_STM;
  data_body[1] = FOCUS_STM_FLAG_BEGIN;
  *reinterpret_cast<uint8_t*>(data_body + 3) = 0xFF;
  *reinterpret_cast<uint32_t*>(data_body + 4) = 0xFFFFFFFF;
  auto frame = to_frame_data(data);

  recv_ethercat(&frame[0]);
  update();

  const auto ack = _sTx.ack >> 8;
  ASSERT_EQ(ack, ERR_INVALID_SEGMENT);
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
        SILNCER_MODE_FIXED_COMPLETION_STEPS | SILNCER_FLAG_STRICT_MODE;

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
        SILNCER_MODE_FIXED_COMPLETION_STEPS | SILNCER_FLAG_STRICT_MODE;

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
    const uint8_t flag = SILNCER_MODE_FIXED_COMPLETION_STEPS;

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
