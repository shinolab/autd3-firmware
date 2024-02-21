#include <gtest/gtest.h>

#include "app.h"
#include "ecat.h"
#include "params.h"
#include "utils.hpp"

extern "C" {
extern TX_STR _sTx;
}

TEST(Op, PhaseFilter) {
  init_app();

  std::vector<uint8_t> buf;
  for (size_t i = 0; i < TRANS_NUM; i++) buf.push_back(static_cast<uint8_t>(i));

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  Header* header = reinterpret_cast<Header*>(data.data);
  header->msg_id = get_msg_id();
  header->slot_2_offset = 0;

  auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
  data_body[0] = TAG_PHASE_FILTER;
  data_body[1] = 0;
  for (size_t i = 0; i < TRANS_NUM; i++) data_body[2 + i] = buf[i];

  auto frame = to_frame_data(data);

  recv_ethercat(&frame[0]);
  update();

  const auto ack = _sTx.ack >> 8;
  ASSERT_EQ(ack, header->msg_id);

  for (uint8_t i = 0; i < TRANS_NUM - 1; i += 2) {
    ASSERT_EQ(buf[i], bram_read_phase_filter(i / 2) & 0xFF);
    ASSERT_EQ(buf[i + 1], bram_read_phase_filter(i / 2) >> 8);
  }
  ASSERT_EQ(buf[TRANS_NUM - 1],
            bram_read_phase_filter((TRANS_NUM - 1) / 2) & 0xFF);
}
