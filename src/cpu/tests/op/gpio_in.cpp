#include <gtest/gtest.h>

#include <cstring>

#include "app.h"
#include "ecat.h"
#include "params.h"
#include "utils.hpp"

extern "C" {
extern TX_STR _sTx;
}

TEST(Op, EmulateGPIOIn) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  Header* header = reinterpret_cast<Header*>(data.data);

  {
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_EMULATE_GPIO_IN;
    data_body[1] =
        GPIO_IN_FLAG_0 | GPIO_IN_FLAG_1 | GPIO_IN_FLAG_2 | GPIO_IN_FLAG_3;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);

    ASSERT_TRUE((bram_read_controller(ADDR_CTL_FLAG) & CTL_FLAG_GPIO_IN_0) ==
                CTL_FLAG_GPIO_IN_0);
    ASSERT_TRUE((bram_read_controller(ADDR_CTL_FLAG) & CTL_FLAG_GPIO_IN_1) ==
                CTL_FLAG_GPIO_IN_1);
    ASSERT_TRUE((bram_read_controller(ADDR_CTL_FLAG) & CTL_FLAG_GPIO_IN_2) ==
                CTL_FLAG_GPIO_IN_2);
    ASSERT_TRUE((bram_read_controller(ADDR_CTL_FLAG) & CTL_FLAG_GPIO_IN_3) ==
                CTL_FLAG_GPIO_IN_3);
  }

  {
    header->msg_id = get_msg_id();
    header->slot_2_offset = 0;

    auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
    data_body[0] = TAG_EMULATE_GPIO_IN;
    data_body[1] = 0x00;

    auto frame = to_frame_data(data);

    recv_ethercat(&frame[0]);
    update();

    const auto ack = _sTx.ack >> 8;
    ASSERT_EQ(ack, header->msg_id);

    ASSERT_TRUE((bram_read_controller(ADDR_CTL_FLAG) & CTL_FLAG_GPIO_IN_0) ==
                0);
    ASSERT_TRUE((bram_read_controller(ADDR_CTL_FLAG) & CTL_FLAG_GPIO_IN_1) ==
                0);
    ASSERT_TRUE((bram_read_controller(ADDR_CTL_FLAG) & CTL_FLAG_GPIO_IN_2) ==
                0);
    ASSERT_TRUE((bram_read_controller(ADDR_CTL_FLAG) & CTL_FLAG_GPIO_IN_3) ==
                0);
  }
}
