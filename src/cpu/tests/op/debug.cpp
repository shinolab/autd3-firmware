#include <gtest/gtest.h>

#include "app.h"
#include "ecat.h"
#include "params.h"
#include "utils.hpp"

extern "C" {
extern TX_STR _sTx;
}

TEST(Op, ConfigureDebugOutIdx) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  Header* header = reinterpret_cast<Header*>(data.data);
  header->msg_id = get_msg_id();
  header->slot_2_offset = 0;

  const uint8_t ty[4] = {0x00, 0x01, 0x02, 0x03};
  const uint16_t value[4] = {0x0123, 0x4567, 0x89ab, 0xcdef};

  auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
  data_body[0] = TAG_DEBUG;
  std::memcpy(&data_body[2], ty, 4);
  std::memcpy(&data_body[6], value, 8);

  auto frame = to_frame_data(data);

  recv_ethercat(&frame[0]);
  update();

  const auto ack = _sTx.ack >> 8;
  ASSERT_EQ(ack, header->msg_id);

  ASSERT_EQ(bram_read_controller(ADDR_DEBUG_TYPE0), ty[0]);
  ASSERT_EQ(bram_read_controller(ADDR_DEBUG_TYPE1), ty[1]);
  ASSERT_EQ(bram_read_controller(ADDR_DEBUG_TYPE2), ty[2]);
  ASSERT_EQ(bram_read_controller(ADDR_DEBUG_TYPE3), ty[3]);
  ASSERT_EQ(bram_read_controller(ADDR_DEBUG_VALUE0), value[0]);
  ASSERT_EQ(bram_read_controller(ADDR_DEBUG_VALUE1), value[1]);
  ASSERT_EQ(bram_read_controller(ADDR_DEBUG_VALUE2), value[2]);
  ASSERT_EQ(bram_read_controller(ADDR_DEBUG_VALUE3), value[3]);
}
