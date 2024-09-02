#include <gtest/gtest.h>

#include "app.h"
#include "ecat.h"
#include "params.h"
#include "utils.hpp"

extern "C" {
extern TX_STR _sTx;
int is_sync = 0;
uint64_t sync_time = 0;
}

TEST(Op, Sync) {
  init_app();
  ASSERT_EQ(is_sync, 0);

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  Header* header = reinterpret_cast<Header*>(data.data);
  header->msg_id = get_msg_id();
  header->slot_2_offset = 0;

  sync_time = 0x0123456789ABCDEF;

  auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
  data_body[0] = TAG_SYNC;

  auto frame = to_frame_data(data);

  ASSERT_EQ(is_sync, 0);
  recv_ethercat(&frame[0]);
  update();

  const auto ack = _sTx.ack >> 8;
  ASSERT_EQ(ack, header->msg_id);

  ASSERT_EQ(is_sync, 1);

  ASSERT_EQ(bram_read_controller(ADDR_ECAT_SYNC_TIME_0), sync_time & 0xFFFF);
  ASSERT_EQ(bram_read_controller(ADDR_ECAT_SYNC_TIME_1), (sync_time >> 16) & 0xFFFF);
  ASSERT_EQ(bram_read_controller(ADDR_ECAT_SYNC_TIME_2), (sync_time >> 32) & 0xFFFF);
  ASSERT_EQ(bram_read_controller(ADDR_ECAT_SYNC_TIME_3), (sync_time >> 48) & 0xFFFF);
}
