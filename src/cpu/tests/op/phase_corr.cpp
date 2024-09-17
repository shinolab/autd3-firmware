#include <gtest/gtest.h>

#include "app.h"
#include "ecat.h"
#include "params.h"
#include "utils.hpp"

extern "C" {
extern TX_STR _sTx;
}

TEST(Op, PhaseCorrection) {
  init_app();

  RX_STR data;
  std::memset(data.data, 0, sizeof(RX_STR));

  std::vector<uint8_t> buf;
  for (size_t i = 0; i < NUM_TRANSDUCERS; i++) buf.push_back(static_cast<uint8_t>(i));

  Header* header = reinterpret_cast<Header*>(data.data);
  header->slot_2_offset = 0;

  header->msg_id = get_msg_id();

  auto* data_body = reinterpret_cast<uint8_t*>(data.data) + sizeof(Header);
  data_body[0] = TAG_PHASE_CORRECTION;
  auto offset = 2;
  auto send = 249;

  for (size_t i = 0; i < send; i++) data_body[offset + i] = buf[i];

  auto frame = to_frame_data(data);

  recv_ethercat(&frame[0]);
  update();

  const auto ack = _sTx.ack >> 8;
  ASSERT_EQ(ack, header->msg_id);

  for (size_t i = 0; i < NUM_TRANSDUCERS - 1; i += 2) {
    ASSERT_EQ(buf[i], bram_read_phase_corr(i / 2) & 0xFF);
    ASSERT_EQ(buf[i + 1], bram_read_phase_corr(i / 2) >> 8);
  }
  ASSERT_EQ(buf[NUM_TRANSDUCERS - 1], bram_read_phase_corr((NUM_TRANSDUCERS - 1) / 2) & 0xFF);
}
