#include <gtest/gtest.h>

#include "app.h"
#include "ecat.h"
#include "params.h"
#include "utils.hpp"

extern "C" {
extern TX_STR _sTx;
}

TEST(Op, Clk) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  Header* header = reinterpret_cast<Header*>(data.data);
  header->slot_2_offset = 0;

  uint64_t rom[32] = {0};
  for (size_t i = 0; i < 128; i++) reinterpret_cast<uint16_t*>(rom)[i] = i;

  auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
  data_body[0] = TAG_CONFIG_FPGA_CLK;

  {
    header->msg_id = get_msg_id();
    data_body[1] = CLK_FLAG_BEGIN;
    *reinterpret_cast<uint16_t*>(data_body + 2) = 16;
    for (size_t i = 0; i < 16; i++) reinterpret_cast<uint64_t*>(data_body + 4)[i] = rom[i];

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }

  {
    header->msg_id = get_msg_id();
    data_body[1] = CLK_FLAG_END;
    *reinterpret_cast<uint16_t*>(data_body + 2) = 16;
    for (size_t i = 0; i < 16; i++) reinterpret_cast<uint64_t*>(data_body + 4)[i] = rom[16 + i];

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }

  for (size_t i = 0; i < 128; i++) ASSERT_EQ(bram_read_clk(i), reinterpret_cast<uint16_t*>(rom)[i]);
}
