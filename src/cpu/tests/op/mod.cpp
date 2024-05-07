#include <gtest/gtest.h>

#include "app.h"
#include "ecat.h"
#include "iodefine.h"
#include "params.h"
#include "utils.hpp"

extern "C" {
extern TX_STR _sTx;
}

TEST(Op, Mod) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  std::vector<uint8_t> m;
  for (auto i = 0; i < 32768; i++) m.push_back(static_cast<uint8_t>(i));

  Header* header = reinterpret_cast<Header*>(data.data);
  header->slot_2_offset = 0;

  // segment 0
  {
    const uint8_t transition_mode = TRANSITION_MODE_EXT;
    const uint64_t transition_value = 0x0123456789ABCDEF;
    const uint32_t size = 32768;
    const uint32_t freq_div = 0x12345678;
    const uint32_t rep = 0x9ABCDEF0;

    size_t cnt = 0;
    while (cnt < size) {
      header->msg_id = get_msg_id();

      auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
      data_body[0] = TAG_MODULATION;
      auto offset = 4;
      if (cnt == 0) {
        data_body[1] = MODULATION_FLAG_BEGIN;
        data_body[4] = transition_mode;
        *reinterpret_cast<uint32_t*>(data_body + 8) = freq_div;
        *reinterpret_cast<uint32_t*>(data_body + 12) = rep;
        *reinterpret_cast<uint64_t*>(data_body + 16) = transition_value;
        offset += 20;
      } else {
        data_body[1] = 0;
      }
      auto send =
          std::min(size - cnt, sizeof(RX_STR) - sizeof(Header) - offset);
      *reinterpret_cast<uint16_t*>(data_body + 2) = static_cast<uint16_t>(send);

      for (size_t i = 0; i < send; i++) data_body[offset + i] = m[cnt + i];
      cnt += send;

      if (cnt == size)
        data_body[1] |= MODULATION_FLAG_END | MODULATION_FLAG_UPDATE;

      auto frame = to_frame_data(data);

      recv_ethercat(&frame[0]);
      update();

      const auto ack = _sTx.ack >> 8;
      ASSERT_EQ(ack, header->msg_id);
    }

    ASSERT_EQ(bram_read_controller(ADDR_MOD_REQ_RD_SEGMENT), 0);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_CYCLE0), size - 1);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_FREQ_DIV0_0), 0x5678);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_FREQ_DIV0_1), 0x1234);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_REP0_0), 0xDEF0);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_REP0_1), 0x9ABC);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_MODE), transition_mode);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_VALUE_0), 0xCDEF);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_VALUE_1), 0x89AB);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_VALUE_2), 0x4567);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_VALUE_3), 0x0123);
    for (size_t i = 0; i < size >> 1; i++) {
      ASSERT_EQ(bram_read_mod(0, i),
                ((static_cast<uint8_t>((i << 1) + 1)) << 8) |
                    static_cast<uint8_t>(i << 1));
    }
  }

  // segment 1 without segment change
  {
    const uint8_t transition_mode = TRANSITION_MODE_SYS_TIME;
    const uint64_t transition_value = 0xFEDCBA9876543210;
    const uint32_t size = 1024;
    const uint32_t freq_div = 0x9ABCDEF0;
    const uint32_t rep = 0x12345678;

    size_t cnt = 0;
    while (cnt < size) {
      header->msg_id = get_msg_id();

      auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
      data_body[0] = TAG_MODULATION;
      auto offset = 4;
      if (cnt == 0) {
        data_body[1] = MODULATION_FLAG_BEGIN | MODULATION_FLAG_SEGMENT;
        data_body[4] = transition_mode;
        *reinterpret_cast<uint32_t*>(data_body + 8) = freq_div;
        *reinterpret_cast<uint32_t*>(data_body + 12) = rep;
        *reinterpret_cast<uint64_t*>(data_body + 16) = transition_value;
        offset += 20;
      } else {
        data_body[1] = 0;
      }
      auto send =
          std::min(size - cnt, sizeof(RX_STR) - sizeof(Header) - offset);
      *reinterpret_cast<uint16_t*>(data_body + 2) = static_cast<uint16_t>(send);

      for (size_t i = 0; i < send; i++) data_body[offset + i] = m[cnt + i];
      cnt += send;

      if (cnt == size) data_body[1] |= MODULATION_FLAG_END;

      auto frame = to_frame_data(data);

      recv_ethercat(&frame[0]);
      update();

      const auto ack = _sTx.ack >> 8;
      ASSERT_EQ(ack, header->msg_id);
    }

    ASSERT_EQ(bram_read_controller(ADDR_MOD_REQ_RD_SEGMENT), 0);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_CYCLE1), size - 1);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_FREQ_DIV1_0), 0xDEF0);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_FREQ_DIV1_1), 0x9ABC);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_REP1_0), 0x5678);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_REP1_1), 0x1234);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_MODE),
              TRANSITION_MODE_EXT);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_VALUE_0), 0xCDEF);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_VALUE_1), 0x89AB);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_VALUE_2), 0x4567);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_VALUE_3), 0x0123);
    for (size_t i = 0; i < size >> 1; i++) {
      ASSERT_EQ(bram_read_mod(1, i),
                ((static_cast<uint8_t>((i << 1) + 1)) << 8) |
                    static_cast<uint8_t>(i << 1));
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
    data_body[0] = TAG_MODULATION_CHANGE_SEGMENT;
    data_body[1] = 1;
    data_body[2] = transition_mode;
    *reinterpret_cast<uint64_t*>(data_body + 8) = transition_value;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);

    ASSERT_EQ(bram_read_controller(ADDR_MOD_REQ_RD_SEGMENT), 1);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_MODE), transition_mode);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_VALUE_0), 0x3210);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_VALUE_1), 0x7654);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_VALUE_2), 0xBA98);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_VALUE_3), 0xFEDC);
  }
}

TEST(Op, InvalidCompletionStepsMod) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const uint16_t intensity = 10;  // 25us * 10 = 250us
    const uint16_t phase = 0xFF;
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
    data_body[0] = TAG_MODULATION;
    data_body[1] = MODULATION_FLAG_BEGIN | MODULATION_FLAG_END;
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
    data_body[0] = TAG_MODULATION;
    data_body[1] = MODULATION_FLAG_BEGIN | MODULATION_FLAG_END;
    *reinterpret_cast<uint32_t*>(data_body + 8) = freq_div;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, ERR_INVALID_SILENCER_SETTING);
  }
}

TEST(Op, InvalidCompletionStepsWithPermisiveModeMod) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const auto intensity = 10;  // 25us * 10 = 250us
    const auto phase = 0xFF;
    const auto flag = SILENCER_MODE_FIXED_COMPLETION_STEPS;

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
    data_body[0] = TAG_MODULATION;
    data_body[1] = MODULATION_FLAG_BEGIN | MODULATION_FLAG_END;
    *reinterpret_cast<uint32_t*>(data_body + 8) = freq_div;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }
}

TEST(Op, ModMissTransitionTime) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  std::vector<uint8_t> m;
  for (auto i = 0; i < 32768; i++) m.push_back(static_cast<uint8_t>(i));

  Header* header = reinterpret_cast<Header*>(data.data);
  header->slot_2_offset = 0;

  ECATC.DC_SYS_TIME.LONGLONG = 1;
  {
    const uint8_t transition_mode = TRANSITION_MODE_SYS_TIME;
    const uint64_t transition_value = SYS_TIME_TRANSITION_MARGIN;
    const uint32_t size = 32768;
    const uint32_t freq_div = 0x12345678;
    const uint32_t rep = 0x9ABCDEF0;

    size_t cnt = 0;
    while (cnt < size) {
      header->msg_id = get_msg_id();

      auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
      data_body[0] = TAG_MODULATION;
      auto offset = 4;
      if (cnt == 0) {
        data_body[1] = MODULATION_FLAG_BEGIN;
        data_body[4] = transition_mode;
        *reinterpret_cast<uint32_t*>(data_body + 8) = freq_div;
        *reinterpret_cast<uint32_t*>(data_body + 12) = rep;
        *reinterpret_cast<uint64_t*>(data_body + 16) = transition_value;
        offset += 20;
      } else {
        data_body[1] = 0;
      }
      auto send =
          std::min(size - cnt, sizeof(RX_STR) - sizeof(Header) - offset);
      *reinterpret_cast<uint16_t*>(data_body + 2) = static_cast<uint16_t>(send);

      for (size_t i = 0; i < send; i++) data_body[offset + i] = m[cnt + i];
      cnt += send;

      if (cnt == size)
        data_body[1] |= MODULATION_FLAG_END | MODULATION_FLAG_UPDATE;

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
