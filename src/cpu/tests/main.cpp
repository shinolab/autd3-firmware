#include <gtest/gtest.h>

#include <cstring>

extern "C" {

#include "app.h"
#include "ecat.h"
#include "iodefine.h"
#include "params.h"

TX_STR _sTx = TX_STR{};
st_ecatc_t ECATC = st_ecatc_t{
    .AL_STATUS_CODE = {.WORD = 0x0000},
};

uint8_t get_msg_id(void) {
  static uint8_t msg_id = 0;
  const auto id = msg_id++;
  if (msg_id == 0x80) msg_id = 0;
  return id;
}

uint16_t* controller_bram = new uint16_t[256];
uint16_t* modulation_bram_0 = new uint16_t[32768 / sizeof(uint16_t)];
uint16_t* modulation_bram_1 = new uint16_t[32768 / sizeof(uint16_t)];
uint16_t* duty_table_bram = new uint16_t[65536 / sizeof(uint16_t)];
uint16_t* phase_filter_bram = new uint16_t[256 / sizeof(uint16_t)];
uint16_t* stm_op_bram_0 = new uint16_t[1024 * 256];
uint16_t* stm_op_bram_1 = new uint16_t[1024 * 256];

uint32_t mod_wr_segment = 0;
uint32_t stm_wr_segment = 0;
uint32_t stm_wr_page = 0;
uint32_t pulse_width_encoder_table_wr_page = 0;

uint16_t bram_read_controller(uint32_t bram_addr) {
  return controller_bram[bram_addr];
}

uint16_t bram_read_mod(uint32_t segment, uint32_t bram_addr) {
  switch (segment) {
    case 0:
      return modulation_bram_0[bram_addr];
    case 1:
      return modulation_bram_1[bram_addr];
    default:
      exit(1);
  }
}

uint16_t bram_read_duty_table(uint32_t bram_addr) {
  return duty_table_bram[bram_addr];
}

uint16_t bram_read_phase_filter(uint32_t bram_addr) {
  return phase_filter_bram[bram_addr];
}

uint16_t bram_read_stm(uint32_t segment, uint32_t bram_addr) {
  switch (segment) {
    case 0:
      return stm_op_bram_0[bram_addr];
    case 1:
      return stm_op_bram_1[bram_addr];
    default:
      exit(1);
  }
}

uint16_t fpga_read(uint16_t bram_addr) {
  const auto select = (bram_addr >> 14) & 0x0003;
  const auto addr = bram_addr & 0x3FFF;
  switch (select) {
    case BRAM_SELECT_CONTROLLER:
      return controller_bram[addr];
    default:
      exit(1);
  }
}

void fpga_write(uint16_t bram_addr, uint16_t value) {
  const auto select = (bram_addr >> 14) & 0x0003;
  auto addr = bram_addr & 0x3FFF;
  switch (select) {
    case BRAM_SELECT_CONTROLLER:
      switch (addr >> 8) {
        case BRAM_CNT_SEL_MAIN:
          if (addr == BRAM_ADDR_MOD_MEM_WR_SEGMENT) {
            mod_wr_segment = value;
          } else if (addr == BRAM_ADDR_STM_MEM_WR_SEGMENT) {
            stm_wr_segment = value;
          } else if (addr == BRAM_ADDR_STM_MEM_WR_PAGE) {
            stm_wr_page = value;
          } else if (addr == BRAM_ADDR_PULSE_WIDTH_ENCODER_TABLE_WR_PAGE) {
            pulse_width_encoder_table_wr_page = value;
          } else {
            controller_bram[addr] = value;
          }
          break;
        case BRAM_CNT_SEL_FILTER:
          phase_filter_bram[addr & 0xFF] = value;
          break;
        default:
          exit(1);
      }
      break;
    case BRAM_SELECT_MOD:
      switch (mod_wr_segment) {
        case 0:
          modulation_bram_0[addr] = value;
          break;
        case 1:
          modulation_bram_1[addr] = value;
          break;
        default:
          exit(1);
      }
      break;
    case BRAM_SELECT_DUTY_TABLE:
      duty_table_bram[(pulse_width_encoder_table_wr_page << 14) | addr] = value;
      break;
    case BRAM_SELECT_STM:
      switch (stm_wr_segment) {
        case 0:
          stm_op_bram_0[(stm_wr_page << 14) | addr] = value;
          break;
        case 1:
          stm_op_bram_1[(stm_wr_page << 14) | addr] = value;
          break;
        default:
          exit(1);
      }
      break;
    default:
      exit(1);
  }
}

void set_and_wait_update(uint16_t) {}
}

int main(int argc, char** argv) {
  std::memset(controller_bram, 0, sizeof(uint16_t) * 256);
  std::memset(modulation_bram_0, 0, sizeof(uint8_t) * 32768);
  std::memset(modulation_bram_1, 0, sizeof(uint8_t) * 32768);
  std::memset(duty_table_bram, 0, sizeof(uint8_t) * 65536);
  std::memset(phase_filter_bram, 0, sizeof(uint8_t) * 256);
  std::memset(stm_op_bram_0, 0, sizeof(uint64_t) * 1024 * 64);
  std::memset(stm_op_bram_1, 0, sizeof(uint64_t) * 1024 * 64);

  controller_bram[BRAM_ADDR_VERSION_NUM_MAJOR] = 0x008F;
  controller_bram[BRAM_ADDR_VERSION_NUM_MINOR] = 0x0000;

  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
