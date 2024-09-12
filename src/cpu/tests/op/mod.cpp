#include <gtest/gtest.h>

//
#include "app.h"
#include "ecat.h"
#include "iodefine.h"
#include "mod.h"
#include "params.h"
#include "silencer.h"
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
    const uint16_t freq_div = 0x5678;
    const uint16_t rep = 0xDEF0;

    size_t cnt = 0;
    size_t send;
    while (cnt < size) {
      header->msg_id = get_msg_id();

      auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
      reinterpret_cast<ModulationHead*>(p)->tag = TAG_MODULATION;
      reinterpret_cast<ModulationHead*>(p)->flag = 0;
      size_t offset;
      if (cnt == 0) {
        reinterpret_cast<ModulationHead*>(p)->flag = MODULATION_FLAG_BEGIN;
        reinterpret_cast<ModulationHead*>(p)->freq_div = freq_div;
        reinterpret_cast<ModulationHead*>(p)->rep = rep;
        reinterpret_cast<ModulationHead*>(p)->transition.value = transition_value;
        reinterpret_cast<ModulationHead*>(p)->transition.MODE.mode = transition_mode;
        offset = sizeof(ModulationHead);
        send = std::min(std::min(size - cnt, sizeof(RX_STR) - sizeof(Header) - offset), (size_t)254);
        reinterpret_cast<ModulationHead*>(p)->size = static_cast<uint8_t>(send);
      } else {
        offset = sizeof(ModulationSubseq);
        send = std::min(size - cnt, sizeof(RX_STR) - sizeof(Header) - offset);
        reinterpret_cast<ModulationSubseq*>(p)->size = static_cast<uint16_t>(send);
      }

      for (size_t i = 0; i < send; i++) p[offset + i] = m[cnt + i];
      cnt += send;

      if (cnt == size) reinterpret_cast<ModulationHead*>(p)->flag |= MODULATION_FLAG_END | MODULATION_FLAG_UPDATE;

      auto frame = to_frame_data(data);

      recv_ethercat(&frame[0]);
      update();

      const auto ack = _sTx.ack >> 8;
      ASSERT_EQ(ack, header->msg_id);
    }

    ASSERT_EQ(bram_read_controller(ADDR_MOD_REQ_RD_SEGMENT), 0);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_CYCLE0), size - 1);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_FREQ_DIV0), 0x5678);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_REP0), 0xDEF0);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_0), 0xCDEF);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_1), 0x89AB);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_2), 0x4567);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_3), (TRANSITION_MODE_EXT << 8) | 0x23);
    for (size_t i = 0; i < size >> 1; i++) {
      ASSERT_EQ(bram_read_mod(0, i), ((static_cast<uint8_t>((i << 1) + 1)) << 8) | static_cast<uint8_t>(i << 1));
    }
  }

  // segment 1 without segment change
  {
    const uint32_t size = 1024;
    const uint16_t freq_div = 0xDEF0;
    const uint16_t rep = 0x5678;

    size_t cnt = 0;
    while (cnt < size) {
      header->msg_id = get_msg_id();

      auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
      reinterpret_cast<ModulationHead*>(p)->tag = TAG_MODULATION;
      reinterpret_cast<ModulationHead*>(p)->flag = 0;
      size_t offset, send;
      if (cnt == 0) {
        reinterpret_cast<ModulationHead*>(p)->flag = MODULATION_FLAG_BEGIN;
        reinterpret_cast<ModulationHead*>(p)->freq_div = freq_div;
        reinterpret_cast<ModulationHead*>(p)->rep = rep;
        reinterpret_cast<ModulationHead*>(p)->transition.value = 0;
        reinterpret_cast<ModulationHead*>(p)->transition.MODE.mode = TRANSITION_MODE_NONE;
        offset = sizeof(ModulationHead);
        send = std::min(std::min(size - cnt, sizeof(RX_STR) - sizeof(Header) - offset), (size_t)254);
        reinterpret_cast<ModulationHead*>(p)->size = static_cast<uint8_t>(send);
      } else {
        offset = sizeof(ModulationSubseq);
        send = std::min(size - cnt, sizeof(RX_STR) - sizeof(Header) - offset);
        reinterpret_cast<ModulationSubseq*>(p)->size = static_cast<uint16_t>(send);
      }
      reinterpret_cast<ModulationHead*>(p)->flag |= MODULATION_FLAG_SEGMENT;

      for (size_t i = 0; i < send; i++) p[offset + i] = m[cnt + i];
      cnt += send;

      if (cnt == size) reinterpret_cast<ModulationHead*>(p)->flag |= MODULATION_FLAG_END;

      auto frame = to_frame_data(data);

      recv_ethercat(&frame[0]);
      update();

      const auto ack = _sTx.ack >> 8;
      ASSERT_EQ(ack, header->msg_id);
    }

    ASSERT_EQ(bram_read_controller(ADDR_MOD_REQ_RD_SEGMENT), 0);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_CYCLE1), size - 1);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_FREQ_DIV1), 0xDEF0);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_REP1), 0x5678);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_0), 0xCDEF);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_1), 0x89AB);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_2), 0x4567);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_3), (TRANSITION_MODE_EXT << 8) | 0x23);
    for (size_t i = 0; i < size >> 1; i++) {
      ASSERT_EQ(bram_read_mod(1, i), ((static_cast<uint8_t>((i << 1) + 1)) << 8) | static_cast<uint8_t>(i << 1));
    }
  }

  // change segment
  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    const uint8_t transition_mode = TRANSITION_MODE_SYS_TIME;
    const uint64_t transition_value = 0xFEDCBA9876543210;

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    reinterpret_cast<ModulationUpdate*>(p)->tag = TAG_MODULATION_CHANGE_SEGMENT;
    reinterpret_cast<ModulationUpdate*>(p)->segment = 1;
    reinterpret_cast<ModulationUpdate*>(p)->transition.value = transition_value;
    reinterpret_cast<ModulationUpdate*>(p)->transition.MODE.mode = transition_mode;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);

    ASSERT_EQ(bram_read_controller(ADDR_MOD_REQ_RD_SEGMENT), 1);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_0), 0x3210);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_1), 0x7654);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_2), 0xBA98);
    ASSERT_EQ(bram_read_controller(ADDR_MOD_TRANSITION_3), (TRANSITION_MODE_SYS_TIME << 8) | 0xDC);
  }
}

TEST(Op, ModulationInvalidTransitionMode) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  // segment 0 to 0
  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    reinterpret_cast<ModulationHead*>(p)->tag = TAG_MODULATION;
    reinterpret_cast<ModulationHead*>(p)->flag = MODULATION_FLAG_BEGIN;
    reinterpret_cast<ModulationHead*>(p)->transition.MODE.mode = TRANSITION_MODE_SYNC_IDX;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ERR_INVALID_TRANSITION_MODE, ack);
  }

  // segment 0 to 1
  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    reinterpret_cast<ModulationHead*>(p)->tag = TAG_MODULATION;
    reinterpret_cast<ModulationHead*>(p)->flag = MODULATION_FLAG_BEGIN | MODULATION_FLAG_SEGMENT;
    reinterpret_cast<ModulationHead*>(p)->rep = 0;
    reinterpret_cast<ModulationHead*>(p)->transition.MODE.mode = TRANSITION_MODE_IMMIDIATE;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ERR_INVALID_TRANSITION_MODE, ack);
  }

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;
    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    reinterpret_cast<ModulationHead*>(p)->tag = TAG_MODULATION;
    reinterpret_cast<ModulationHead*>(p)->flag = MODULATION_FLAG_BEGIN | MODULATION_FLAG_END | MODULATION_FLAG_SEGMENT;
    reinterpret_cast<ModulationHead*>(p)->size = 2;
    reinterpret_cast<ModulationHead*>(p)->freq_div = 0xFFFF;
    reinterpret_cast<ModulationHead*>(p)->rep = 0xFFFF;
    reinterpret_cast<ModulationHead*>(p)->transition.MODE.mode = TRANSITION_MODE_NONE;
    auto frame = to_frame_data(data);
    recv_ethercat(&frame[0]);
    update();
    auto ack = _sTx.ack >> 8;
    ASSERT_EQ(header->msg_id, ack);

    header->msg_id = get_msg_id();
    reinterpret_cast<ModulationUpdate*>(p)->tag = TAG_MODULATION_CHANGE_SEGMENT;
    reinterpret_cast<ModulationUpdate*>(p)->segment = 1;
    reinterpret_cast<ModulationUpdate*>(p)->transition.MODE.mode = TRANSITION_MODE_SYNC_IDX;
    frame = to_frame_data(data);
    recv_ethercat(&frame[0]);
    update();
    ack = _sTx.ack >> 8;
    ASSERT_EQ(ERR_INVALID_TRANSITION_MODE, ack);
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
    reinterpret_cast<ModulationHead*>(p)->tag = TAG_MODULATION;
    reinterpret_cast<ModulationHead*>(p)->flag = MODULATION_FLAG_BEGIN | MODULATION_FLAG_END;
    reinterpret_cast<ModulationHead*>(p)->freq_div = freq_div;
    reinterpret_cast<ModulationHead*>(p)->size = 2;
    reinterpret_cast<ModulationHead*>(p)->transition.MODE.mode = TRANSITION_MODE_IMMIDIATE;

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
    reinterpret_cast<ModulationHead*>(p)->tag = TAG_MODULATION;
    reinterpret_cast<ModulationHead*>(p)->flag = MODULATION_FLAG_BEGIN | MODULATION_FLAG_END;
    reinterpret_cast<ModulationHead*>(p)->freq_div = freq_div;
    reinterpret_cast<ModulationHead*>(p)->size = 2;
    reinterpret_cast<ModulationHead*>(p)->transition.MODE.mode = TRANSITION_MODE_IMMIDIATE;

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

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    reinterpret_cast<ModulationHead*>(p)->tag = TAG_MODULATION;
    reinterpret_cast<ModulationHead*>(p)->flag = MODULATION_FLAG_BEGIN | MODULATION_FLAG_END;
    reinterpret_cast<ModulationHead*>(p)->size = 2;
    reinterpret_cast<ModulationHead*>(p)->freq_div = 0xFFFF;
    reinterpret_cast<ModulationHead*>(p)->rep = 0xFFFF;
    reinterpret_cast<ModulationHead*>(p)->transition.MODE.mode = TRANSITION_MODE_IMMIDIATE;
    auto frame = to_frame_data(data);
    recv_ethercat(&frame[0]);
    update();
    auto ack = _sTx.ack >> 8;
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
    reinterpret_cast<ModulationHead*>(p)->tag = TAG_MODULATION;
    reinterpret_cast<ModulationHead*>(p)->flag = MODULATION_FLAG_BEGIN | MODULATION_FLAG_END | MODULATION_FLAG_SEGMENT;
    reinterpret_cast<ModulationHead*>(p)->size = 2;
    reinterpret_cast<ModulationHead*>(p)->freq_div = 40;
    reinterpret_cast<ModulationHead*>(p)->rep = 0xFFFF;
    reinterpret_cast<ModulationHead*>(p)->transition.MODE.mode = TRANSITION_MODE_NONE;
    frame = to_frame_data(data);
    recv_ethercat(&frame[0]);
    update();
    ack = _sTx.ack >> 8;
    ASSERT_EQ(header->msg_id, ack);

    header->msg_id = get_msg_id();
    reinterpret_cast<ConfigSilencer*>(p)->tag = TAG_SILENCER;
    reinterpret_cast<ConfigSilencer*>(p)->flag = SILENCER_FLAG_STRICT_MODE;
    reinterpret_cast<ConfigSilencer*>(p)->value_intensity = 80;
    reinterpret_cast<ConfigSilencer*>(p)->value_phase = 40;
    frame = to_frame_data(data);
    recv_ethercat(&frame[0]);
    update();
    ack = _sTx.ack >> 8;
    ASSERT_EQ(header->msg_id, ack);

    header->msg_id = get_msg_id();
    reinterpret_cast<ModulationUpdate*>(p)->tag = TAG_MODULATION_CHANGE_SEGMENT;
    reinterpret_cast<ModulationUpdate*>(p)->segment = 1;
    reinterpret_cast<ModulationUpdate*>(p)->transition.MODE.mode = TRANSITION_MODE_IMMIDIATE;
    frame = to_frame_data(data);
    recv_ethercat(&frame[0]);
    update();
    ack = _sTx.ack >> 8;
    ASSERT_EQ(ERR_INVALID_SILENCER_SETTING, ack);
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
    const auto flag = 0;

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

    const uint16_t freq_div = 9;

    header->msg_id = get_msg_id();

    auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    reinterpret_cast<ModulationHead*>(p)->tag = TAG_MODULATION;
    reinterpret_cast<ModulationHead*>(p)->flag = MODULATION_FLAG_BEGIN | MODULATION_FLAG_END;
    reinterpret_cast<ModulationHead*>(p)->freq_div = freq_div;
    reinterpret_cast<ModulationHead*>(p)->size = 2;
    reinterpret_cast<ModulationHead*>(p)->transition.MODE.mode = TRANSITION_MODE_IMMIDIATE;

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
    const uint16_t freq_div = 0x5678;
    const uint16_t rep = 0xDEF0;

    size_t cnt = 0;
    while (cnt < size) {
      header->msg_id = get_msg_id();

      auto* p = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
      reinterpret_cast<ModulationHead*>(p)->tag = TAG_MODULATION;
      reinterpret_cast<ModulationHead*>(p)->flag = 0;
      size_t offset;
      if (cnt == 0) {
        reinterpret_cast<ModulationHead*>(p)->flag = MODULATION_FLAG_BEGIN;
        reinterpret_cast<ModulationHead*>(p)->freq_div = freq_div;
        reinterpret_cast<ModulationHead*>(p)->rep = rep;
        reinterpret_cast<ModulationHead*>(p)->transition.value = transition_value;
        reinterpret_cast<ModulationHead*>(p)->transition.MODE.mode = transition_mode;
        offset = sizeof(ModulationHead);
      } else {
        offset = sizeof(ModulationSubseq);
      }
      reinterpret_cast<ModulationHead*>(p)->flag |= MODULATION_FLAG_SEGMENT;

      auto send = std::min(size - cnt, sizeof(RX_STR) - sizeof(Header) - offset);
      reinterpret_cast<ModulationHead*>(p)->size = static_cast<uint16_t>(send);

      for (size_t i = 0; i < send; i++) p[offset + i] = m[cnt + i];
      cnt += send;

      if (cnt == size) reinterpret_cast<ModulationHead*>(p)->flag |= MODULATION_FLAG_END | MODULATION_FLAG_UPDATE;

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
