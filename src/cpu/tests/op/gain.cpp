#include <gtest/gtest.h>

#include "app.h"
#include "ecat.h"
#include "params.h"
#include "utils.hpp"

extern "C" {
extern TX_STR _sTx;
}

TEST(Op, Gain) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  // segment 0
  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_GAIN;
    data_body[1] = 0;
    for (uint8_t i = 0; i < TRANS_NUM; i++)
      *reinterpret_cast<uint16_t*>((data_body + 2 + i * 2)) = (i << 8) | i;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);

    ASSERT_EQ(bram_read_controller(BRAM_ADDR_STM_MODE), STM_MODE_GAIN);
    ASSERT_EQ(bram_read_controller(BRAM_ADDR_STM_REQ_RD_SEGMENT), 0);
    for (uint8_t i = 0; i < TRANS_NUM; i++)
      ASSERT_EQ(bram_read_stm(0, i), (i << 8) | i);
  }

  // segment 1
  {
    Header* header = reinterpret_cast<Header*>(data.data);
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_GAIN;
    data_body[1] = 1;
    for (uint8_t i = 0; i < TRANS_NUM; i++)
      *reinterpret_cast<uint16_t*>((data_body + 2 + i * 2)) = (i << 8) | i;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);

    ASSERT_EQ(bram_read_controller(BRAM_ADDR_STM_MODE), STM_MODE_GAIN);
    ASSERT_EQ(bram_read_controller(BRAM_ADDR_STM_REQ_RD_SEGMENT), 1);
    for (uint8_t i = 0; i < TRANS_NUM; i++)
      ASSERT_EQ(bram_read_stm(0, i), (i << 8) | i);
  }
}

TEST(Op, GainInvalidSegment) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  Header* header = reinterpret_cast<Header*>(data.data);
  header->msg_id = get_msg_id();
  header->slot_2_offset = 0;

  auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
  data_body[0] = TAG_GAIN;
  data_body[1] = 0xFF;

  auto frame = to_frame_data(data);

  recv_ethercat(&frame[0]);
  update();

  const auto ack = _sTx.ack >> 8;
  ASSERT_EQ(ack, ERR_INVALID_SEGMENT);
}
