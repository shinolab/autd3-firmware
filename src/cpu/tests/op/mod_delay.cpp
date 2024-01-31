#include <gtest/gtest.h>

#include "app.h"
#include "ecat.h"
#include "params.h"
#include "utils.hpp"

extern "C" {
extern TX_STR _sTx;
}

TEST(Op, ModDelay) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  Header* header = reinterpret_cast<Header*>(data.data);
  header->msg_id = get_msg_id();
  header->slot_2_offset = 0;

  auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
  data_body[0] = TAG_MODULATION_DELAY;
  for (uint8_t i = 0; i < TRANS_NUM; i++) {
    *reinterpret_cast<uint16_t*>((data_body + 2 + i * 2)) = i;
  }

  auto frame = to_frame_data(data);

  recv_ethercat(&frame[0]);
  update();

  const auto ack = _sTx.ack >> 8;
  ASSERT_EQ(ack, header->msg_id);

  for (uint8_t i = 0; i < TRANS_NUM; i++) {
    ASSERT_EQ(
        bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_MOD_DELAY_BASE + i), i);
  }
}
