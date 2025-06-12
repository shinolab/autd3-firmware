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
  data_body[0] = 0xFF;

  auto frame = to_frame_data(data);

  recv_ethercat(&frame[0]);
  update();

  const auto ack = _sTx.ack >> 12;
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

  const auto ack = _sTx.ack >> 12;
  ASSERT_EQ(ack, ERR_INVALID_MSG_ID);
}

TEST(Op, Slot2) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  Header* header = reinterpret_cast<Header*>(data.data);
  header->msg_id = get_msg_id();
  header->slot_2_offset = 40;

  const uint64_t value[4] = {0x0123456789ABCDEF, 0xEFCDAB8967452301, 0xFEDCBA9876543210, 0x1032547698BADCFE};
  {
    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_DEBUG;
    std::memcpy(&data_body[8], value, 4 * sizeof(uint64_t));
  }
  {
    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header) + 40;
    data_body[0] = TAG_FORCE_FAN;
    data_body[1] = 0x01;
  }

  auto frame = to_frame_data(data);

  recv_ethercat(&frame[0]);
  update();

  const auto ack = _sTx.ack >> 8;
  ASSERT_EQ(ack, header->msg_id);

  ASSERT_EQ(bram_read_controller(ADDR_DEBUG_VALUE0_0), value[0] & 0xFFFF);
  ASSERT_EQ(bram_read_controller(ADDR_DEBUG_VALUE0_1), (value[0] >> 16) & 0xFFFF);
  ASSERT_EQ(bram_read_controller(ADDR_DEBUG_VALUE0_2), (value[0] >> 32) & 0xFFFF);
  ASSERT_EQ(bram_read_controller(ADDR_DEBUG_VALUE0_3), (value[0] >> 48) & 0xFFFF);
  ASSERT_EQ(bram_read_controller(ADDR_DEBUG_VALUE1_0), value[1] & 0xFFFF);
  ASSERT_EQ(bram_read_controller(ADDR_DEBUG_VALUE1_1), (value[1] >> 16) & 0xFFFF);
  ASSERT_EQ(bram_read_controller(ADDR_DEBUG_VALUE1_2), (value[1] >> 32) & 0xFFFF);
  ASSERT_EQ(bram_read_controller(ADDR_DEBUG_VALUE1_3), (value[1] >> 48) & 0xFFFF);
  ASSERT_EQ(bram_read_controller(ADDR_DEBUG_VALUE2_0), value[2] & 0xFFFF);
  ASSERT_EQ(bram_read_controller(ADDR_DEBUG_VALUE2_1), (value[2] >> 16) & 0xFFFF);
  ASSERT_EQ(bram_read_controller(ADDR_DEBUG_VALUE2_2), (value[2] >> 32) & 0xFFFF);
  ASSERT_EQ(bram_read_controller(ADDR_DEBUG_VALUE2_3), (value[2] >> 48) & 0xFFFF);
  ASSERT_EQ(bram_read_controller(ADDR_DEBUG_VALUE3_0), value[3] & 0xFFFF);
  ASSERT_EQ(bram_read_controller(ADDR_DEBUG_VALUE3_1), (value[3] >> 16) & 0xFFFF);
  ASSERT_EQ(bram_read_controller(ADDR_DEBUG_VALUE3_2), (value[3] >> 32) & 0xFFFF);
  ASSERT_EQ(bram_read_controller(ADDR_DEBUG_VALUE3_3), (value[3] >> 48) & 0xFFFF);

  ASSERT_TRUE((bram_read_controller(ADDR_CTL_FLAG) & CTL_FLAG_FORCE_FAN) == CTL_FLAG_FORCE_FAN);
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
