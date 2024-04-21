#include <gtest/gtest.h>

#include "app.h"
#include "ecat.h"
#include "params.h"
#include "utils.hpp"

extern "C" {
extern TX_STR _sTx;
}

TEST(Op, PulseWidthEncoder) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  std::vector<uint8_t> buf;
  for (size_t i = 0; i < 65536; i++) buf.push_back(static_cast<uint8_t>(i));

  Header* header = reinterpret_cast<Header*>(data.data);
  header->slot_2_offset = 0;

  uint16_t full_width_start = 0x1234;

  size_t cnt = 0;
  while (cnt < 65536) {
    header->msg_id = get_msg_id();

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_CONFIG_PULSE_WIDTH_ENCODER;
    auto offset = 4;
    if (cnt == 0) {
      data_body[1] = PULSE_WIDTH_ENCODER_FLAG_BEGIN;
      *reinterpret_cast<uint16_t*>(data_body + 4) = full_width_start;
      offset += 2;
    } else {
      data_body[1] = 0;
    }
    auto send =
        std::min(65536 - cnt, sizeof(RX_STR) - sizeof(Header) - offset) & ~0x1;
    *reinterpret_cast<uint16_t*>(data_body + 2) = static_cast<uint16_t>(send);

    for (size_t i = 0; i < send; i++) data_body[offset + i] = buf[cnt + i];

    cnt += send;

    if (cnt == 65536) data_body[1] |= PULSE_WIDTH_ENCODER_FLAG_END;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);
  }

  ASSERT_EQ(full_width_start,
            bram_read_controller(ADDR_PULSE_WIDTH_ENCODER_FULL_WIDTH_START));
  for (size_t i = 0; i < 65536; i += 2) {
    ASSERT_EQ(buf[i], bram_read_duty_table(i / 2) & 0xFF);
    ASSERT_EQ(buf[i + 1], bram_read_duty_table(i / 2) >> 8);
  }
}
