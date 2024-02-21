#ifdef __cplusplus
extern "C" {
#endif

#include <assert.h>
#include <stddef.h>

#include "app.h"
#include "params.h"

volatile bool_t _read_fpga_state = false;
extern volatile uint8_t _rx_data;

static volatile bool_t _read_fpga_state_store;
extern volatile bool_t _is_rx_data_used;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t ty;
} FirmInfo;

inline static uint16_t get_cpu_version(void) { return CPU_VERSION_MAJOR; }
inline static uint16_t get_cpu_version_minor(void) { return CPU_VERSION_MINOR; }
inline static uint16_t get_fpga_version(void) {
  return bram_read(BRAM_SELECT_CONTROLLER, BRAM_ADDR_VERSION_NUM_MAJOR);
}
inline static uint16_t get_fpga_version_minor(void) {
  return bram_read(BRAM_SELECT_CONTROLLER, BRAM_ADDR_VERSION_NUM_MINOR);
}

uint8_t firmware_info(const volatile uint8_t* p_data) {
  static_assert(sizeof(FirmInfo) == 2, "FirmInfo is not valid.");
  static_assert(offsetof(FirmInfo, tag) == 0, "FirmInfo is not valid.");
  static_assert(offsetof(FirmInfo, ty) == 1, "FirmInfo is not valid.");

  const FirmInfo* p = (const FirmInfo*)p_data;
  switch (p->ty) {
    case INFO_TYPE_CPU_VERSION_MAJOR:
      _read_fpga_state_store = _read_fpga_state;
      _is_rx_data_used = true;
      _read_fpga_state = false;
      _rx_data = get_cpu_version() & 0xFF;
      break;
    case INFO_TYPE_CPU_VERSION_MINOR:
      _rx_data = get_cpu_version_minor() & 0xFF;
      break;
    case INFO_TYPE_FPGA_VERSION_MAJOR:
      _rx_data = get_fpga_version() & 0xFF;
      break;
    case INFO_TYPE_FPGA_VERSION_MINOR:
      _rx_data = get_fpga_version_minor() & 0xFF;
      break;
    case INFO_TYPE_FPGA_FUNCTIONS:
      _rx_data = (get_fpga_version() >> 8) & 0xFF;
      break;
    case INFO_TYPE_CLEAR:
      _read_fpga_state = _read_fpga_state_store;
      _is_rx_data_used = false;
      _rx_data = 0;
      break;
    default:
      return ERR_INVALID_INFO_TYPE;
  }
  return NO_ERR;
}

#ifdef __cplusplus
}
#endif
