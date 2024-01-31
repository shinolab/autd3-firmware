#include <gtest/gtest.h>

#include "app.h"
#include "ecat.h"
#include "params.h"
#include "utils.hpp"

extern "C" {
extern TX_STR _sTx;
}

TEST(Op, SilencerFixedUpdateRate) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  Header* header = reinterpret_cast<Header*>(data.data);
  header->msg_id = get_msg_id();
  header->slot_2_offset = 0;

  const auto intensity = 0x1234;
  const auto phase = 0x5678;
  const auto flag = 0;

  const auto data_body = reinterpret_cast<uint8_t*>(data.data);
  data_body[sizeof(Header)] = TAG_SILENCER;
  *reinterpret_cast<uint16_t*>(data_body + sizeof(Header) + 2) = intensity;
  *reinterpret_cast<uint16_t*>(data_body + sizeof(Header) + 4) = phase;
  *reinterpret_cast<uint16_t*>(data_body + sizeof(Header) + 6) = flag;

  auto frame = to_frame_data(data);

  recv_ethercat(&frame[0]);
  update();

  const auto ack = _sTx.ack >> 8;
  ASSERT_EQ(ack, header->msg_id);

  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER,
                          BRAM_ADDR_SILENCER_UPDATE_RATE_INTENSITY),
            intensity);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER,
                          BRAM_ADDR_SILENCER_UPDATE_RATE_PHASE),
            phase);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_SILENCER_CTL_FLAG),
            flag);
}

TEST(Op, SilencerFixedCompletionSteps) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  Header* header = reinterpret_cast<Header*>(data.data);
  header->msg_id = get_msg_id();
  header->slot_2_offset = 0;

  const auto intensity = 0x0001;
  const auto phase = 0x0002;
  const auto flag =
      SILENCER_CTL_FLAG_FIXED_COMPLETION_STEPS | SILENCER_CTL_FLAG_STRICT_MODE;

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

  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER,
                          BRAM_ADDR_SILENCER_COMPLETION_STEPS_INTENSITY),
            intensity);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER,
                          BRAM_ADDR_SILENCER_COMPLETION_STEPS_PHASE),
            phase);
  ASSERT_EQ(bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_SILENCER_CTL_FLAG),
            flag);
}

TEST(Op, SilencerFixedCompletionStepsInvaidStepMod) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->slot_2_offset = 0;

    const uint32_t freq_div = 5120;  // 1/20.48MHz/5120 = 250us

    header->msg_id = get_msg_id();

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_MODULATION;
    auto offset = 4;
    data_body[1] = MODULATION_FLAG_BEGIN | MODULATION_FLAG_END;
    *reinterpret_cast<uint32_t*>(data_body + offset) = freq_div;
    offset += 4;
    *reinterpret_cast<uint16_t*>(data_body + 2) = 2;

    for (size_t i = 0; i < 2; i++) data_body[offset + i] = 0xFF;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const auto intensity = 10;  // 25us * 10 = 250us
    const auto phase = 0xFF;
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
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const auto intensity = 0x0011;  // 25us * 11 > 250us
    const auto phase = 0xFF;
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
    ASSERT_EQ(ack, ERR_COMPLETION_STEPS_TOO_LARGE);
  }

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const auto intensity = 11;  // 25us * 11 > 250us
    const auto phase = 0xFF;
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
}

TEST(Op, SilencerFixedCompletionStepsInvaidStepSTM) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const auto intensity = 1;
    const auto phase = 1;
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
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const auto intensity = 2;  // 25us * 2= 50us
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
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const auto intensity = 11;  // 25us * 11 > 250us
    const auto phase = 10;
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
    ASSERT_EQ(ack, ERR_COMPLETION_STEPS_TOO_LARGE);
  }

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const auto intensity = 10;
    const auto phase = 11;  // 25us * 11 > 250us
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
    ASSERT_EQ(ack, ERR_COMPLETION_STEPS_TOO_LARGE);
  }

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const auto intensity = 11;  // 25us * 11 > 250us
    const auto phase = 11;      // 25us * 11 > 250us
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
}