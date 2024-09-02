#include <gtest/gtest.h>

//
#include "app.h"
#include "ecat.h"
#include "foci_stm.h"
#include "mod.h"
#include "params.h"
#include "silencer.h"
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

  const uint8_t intensity = 0x12;
  const uint8_t phase = 0x34;
  const uint8_t flag = SILENCER_FLAG_FIXED_UPDATE_RATE_MODE;

  const auto p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
  reinterpret_cast<ConfigSilencer*>(p)->tag = TAG_SILENCER;
  reinterpret_cast<ConfigSilencer*>(p)->flag = flag;
  reinterpret_cast<ConfigSilencer*>(p)->value_intensity = intensity;
  reinterpret_cast<ConfigSilencer*>(p)->value_phase = phase;

  auto frame = to_frame_data(data);

  recv_ethercat(&frame[0]);
  update();

  const auto ack = _sTx.ack >> 8;
  ASSERT_EQ(ack, header->msg_id);

  ASSERT_EQ(bram_read_controller(ADDR_SILENCER_UPDATE_RATE_INTENSITY), intensity);
  ASSERT_EQ(bram_read_controller(ADDR_SILENCER_UPDATE_RATE_PHASE), phase);
  ASSERT_EQ(bram_read_controller(ADDR_SILENCER_FLAG), SILENCER_FLAG_FIXED_UPDATE_RATE_MODE);
}

TEST(Op, SilencerFixedCompletionSteps) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  Header* header = reinterpret_cast<Header*>(data.data);
  header->msg_id = get_msg_id();
  header->slot_2_offset = 0;

  const uint16_t intensity = 0x1234;
  const uint16_t phase = 0x5678;
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

  ASSERT_EQ(bram_read_controller(ADDR_SILENCER_COMPLETION_STEPS_INTENSITY), intensity);
  ASSERT_EQ(bram_read_controller(ADDR_SILENCER_COMPLETION_STEPS_PHASE), phase);
  ASSERT_EQ(bram_read_controller(ADDR_SILENCER_FLAG), flag);
}

TEST(Op, SilencerFixedCompletionStepsInvaidStepMod) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->slot_2_offset = 0;

    const uint16_t freq_div = 10;

    header->msg_id = get_msg_id();

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    reinterpret_cast<ModulationHead*>(p)->tag = TAG_MODULATION;
    reinterpret_cast<ModulationHead*>(p)->flag = MODULATION_FLAG_BEGIN | MODULATION_FLAG_END;
    reinterpret_cast<ModulationHead*>(p)->freq_div = freq_div;
    reinterpret_cast<ModulationHead*>(p)->size = 2;
    reinterpret_cast<ModulationHead*>(p)->transition_mode = TRANSITION_MODE_IMMIDIATE;
    for (size_t i = 0; i < 2; i++) p[sizeof(ModulationHead) + i] = 0xFF;

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

    const uint8_t intensity = 10;  // 25us * 10 = 250us
    const uint8_t phase = 0xFF;
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
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const uint8_t intensity = 11;  // 25us * 11 > 250us
    const uint8_t phase = 0xFF;
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
    ASSERT_EQ(ack, ERR_INVALID_SILENCER_SETTING);
  }

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const uint8_t intensity = 11;  // 25us * 11 > 250us
    const uint8_t phase = 0xFF;
    const uint8_t flag = 0;

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
}

TEST(Op, SilencerFixedCompletionStepsInvaidStepSTM) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const uint8_t intensity = 1;
    const uint8_t phase = 1;
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
    reinterpret_cast<FocusSTMHead*>(p)->tag = TAG_FOCI_STM;
    reinterpret_cast<FocusSTMHead*>(p)->flag = FOCUS_STM_FLAG_BEGIN | FOCUS_STM_FLAG_END;
    reinterpret_cast<FocusSTMHead*>(p)->segment = 0;
    reinterpret_cast<FocusSTMHead*>(p)->send_num = 2;
    reinterpret_cast<FocusSTMHead*>(p)->freq_div = freq_div;
    reinterpret_cast<FocusSTMHead*>(p)->transition_mode = TRANSITION_MODE_IMMIDIATE;

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

    const uint8_t intensity = 10;  // 25us * 10 = 250us
    const uint8_t phase = 2;       // 25us * 2 = 50us
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
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const uint8_t intensity = 2;  // 25us * 2= 50us
    const uint8_t phase = 10;     // 25us * 10 = 250us
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
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const uint8_t intensity = 11;  // 25us * 11 > 250us
    const uint8_t phase = 10;
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
    ASSERT_EQ(ack, ERR_INVALID_SILENCER_SETTING);
  }

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const uint8_t intensity = 10;
    const uint8_t phase = 11;  // 25us * 11 > 250us
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
    ASSERT_EQ(ack, ERR_INVALID_SILENCER_SETTING);
  }

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const uint8_t intensity = 11;  // 25us * 11 > 250us
    const uint8_t phase = 11;      // 25us * 11 > 250us
    const uint8_t flag = 0;

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
}
