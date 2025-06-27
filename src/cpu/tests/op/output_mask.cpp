#include <gtest/gtest.h>

#include "app.h"
#include "ecat.h"
#include "params.h"
#include "utils.hpp"

extern "C" {
extern TX_STR _sTx;
}

TEST(Op, OutputMask) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  for (uint8_t segment = 0; segment < 2; segment++) {
    std::vector<uint16_t> buf;
    for (size_t i = 0; i < 16; i++) buf.push_back(static_cast<uint16_t>(i));

    Header* header = reinterpret_cast<Header*>(data.data);
    header->slot_2_offset = 0;

    header->msg_id = get_msg_id();

    auto* data_body_head = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body_head[0] = TAG_OUTPUT_MASK;
    data_body_head[1] = segment;

    auto* data_body = reinterpret_cast<uint16_t*>(data_body_head + 2);
    for (size_t i = 0; i < 16; i++) data_body[i] = buf[i];

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);

    for (size_t i = 0; i < 16; i++) ASSERT_EQ(buf[i], bram_read_output_mask(segment, i));
  }
}
