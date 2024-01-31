#include <gtest/gtest.h>

#include <cstring>

#include "app.h"
#include "ecat.h"
#include "params.h"
#include "utils.hpp"

extern "C" {
extern TX_STR _sTx;
}

TEST(Op, ConfigureForceFan) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  Header* header = reinterpret_cast<Header*>(data.data);

  {
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_FORCE_FAN;
    data_body[1] = 0x01;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);

    ASSERT_TRUE((bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_CTL_FLAG) &
                 CTL_FLAG_FORCE_FAN_EX) == CTL_FLAG_FORCE_FAN_EX);
  }

  {
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_FORCE_FAN;
    data_body[1] = 0x00;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);

    ASSERT_TRUE((bram_read_raw(BRAM_SELECT_CONTROLLER, BRAM_ADDR_CTL_FLAG) &
                 CTL_FLAG_FORCE_FAN_EX) == 0);
  }
}
