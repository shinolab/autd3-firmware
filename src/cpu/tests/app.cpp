#include <gtest/gtest.h>

//
#include "app.h"
#include "ecat.h"
#include "iodefine.h"
#include "params.h"
#include "utils.hpp"

extern "C" {
extern TX_STR _sTx;
}

TEST(Op, NotSuppoertedTag) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  Header* header = reinterpret_cast<Header*>(data.data);
  header->msg_id = get_msg_id();
  header->slot_2_offset = 0;

  auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
  data_body[0] = 0x00;

  auto frame = to_frame_data(data);

  recv_ethercat(&frame[0]);
  update();

  const auto ack = _sTx.ack >> 8;
  ASSERT_EQ(ack, ERR_NOT_SUPPORTED_TAG);
}

TEST(Op, InvalidMsgId) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  Header* header = reinterpret_cast<Header*>(data.data);
  header->msg_id = 0xFF;
  header->slot_2_offset = 0;

  auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
  data_body[0] = 0x00;

  auto frame = to_frame_data(data);

  recv_ethercat(&frame[0]);
  update();

  const auto ack = _sTx.ack >> 8;
  ASSERT_EQ(ack, ERR_INVALID_MSG_ID);
}

TEST(Op, Slot2) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  Header* header = reinterpret_cast<Header*>(data.data);
  header->msg_id = get_msg_id();
  header->slot_2_offset = 14;

  const uint8_t ty[4] = {0x00, 0x01, 0x02, 0x03};
  const uint16_t value[4] = {0x0123, 0x4567, 0x89ab, 0xcdef};
  {
    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_DEBUG;
    std::memcpy(&data_body[2], ty, 4);
    std::memcpy(&data_body[6], value, 8);
  }
  {
    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header) + 14;
    data_body[0] = TAG_FORCE_FAN;
    data_body[1] = 0x01;
  }

  auto frame = to_frame_data(data);

  recv_ethercat(&frame[0]);
  update();

  const auto ack = _sTx.ack >> 8;
  ASSERT_EQ(ack, header->msg_id);

  ASSERT_EQ(bram_read_controller(BRAM_ADDR_DEBUG_TYPE_0), ty[0]);
  ASSERT_EQ(bram_read_controller(BRAM_ADDR_DEBUG_TYPE_1), ty[1]);
  ASSERT_EQ(bram_read_controller(BRAM_ADDR_DEBUG_TYPE_2), ty[2]);
  ASSERT_EQ(bram_read_controller(BRAM_ADDR_DEBUG_TYPE_3), ty[3]);
  ASSERT_EQ(bram_read_controller(BRAM_ADDR_DEBUG_VALUE_0), value[0]);
  ASSERT_EQ(bram_read_controller(BRAM_ADDR_DEBUG_VALUE_1), value[1]);
  ASSERT_EQ(bram_read_controller(BRAM_ADDR_DEBUG_VALUE_2), value[2]);
  ASSERT_EQ(bram_read_controller(BRAM_ADDR_DEBUG_VALUE_3), value[3]);
  ASSERT_TRUE((bram_read_controller(BRAM_ADDR_CTL_FLAG) & CTL_FLAG_FORCE_FAN) == CTL_FLAG_FORCE_FAN);
}

TEST(Op, WDT) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  ECATC.AL_STATUS_CODE.WORD = 0x001A;

  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = 0x00;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();
  }

  ECATC.AL_STATUS_CODE.WORD = 0x0000;
}
