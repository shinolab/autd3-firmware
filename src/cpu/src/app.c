#ifdef __cplusplus
extern "C" {
#endif

#include "app.h"

#include "ecat.h"
#include "iodefine.h"
#include "kernel.h"
#include "params.h"
#include "utils.h"

extern uint8_t clear(void);
extern uint8_t synchronize(const volatile uint8_t*);
extern uint8_t configure_clk(const volatile uint8_t*);
extern uint8_t firmware_info(const volatile uint8_t*);
extern uint8_t write_mod(const volatile uint8_t*);
extern uint8_t change_mod_segment(const volatile uint8_t*);
extern uint8_t config_silencer(const volatile uint8_t*);
extern uint8_t write_gain(const volatile uint8_t*);
extern uint8_t change_gain_segment(const volatile uint8_t*);
extern uint8_t write_foci_stm(const volatile uint8_t*);
extern uint8_t change_foci_stm_segment(const volatile uint8_t*);
extern uint8_t write_gain_stm(const volatile uint8_t*);
extern uint8_t change_gain_stm_segment(const volatile uint8_t*);
extern uint8_t configure_force_fan(const volatile uint8_t*);
extern uint8_t configure_reads_fpga_state(const volatile uint8_t*);
extern uint8_t change_mod_segment(const volatile uint8_t*);
extern uint8_t config_pwe(const volatile uint8_t*);
extern uint8_t configure_debug(const volatile uint8_t*);
extern uint8_t read_fpga_state(void);
extern uint8_t emulate_gpio_in(const volatile uint8_t*);

#define WDT_CNT_MAX (500)

static volatile short _wdt_cnt = WDT_CNT_MAX;

extern TX_STR _sTx;

extern bool_t push(const volatile uint16_t*);
extern bool_t pop(volatile RX_STR*);
static volatile RX_STR _data;

// fire when ethercat packet arrives
extern void recv_ethercat(uint16_t* p_data);
// fire once after power on
extern void init_app(void);
// fire periodically with 1ms interval
extern void update(void);

static volatile uint8_t _ack = 0;
volatile uint8_t _rx_data = 0;
volatile uint16_t _fpga_flags_internal = 0;

void init_app(void) { clear(); }

uint8_t handle_payload(const volatile uint8_t* p_data) {
  switch (p_data[0]) {
    case TAG_CLEAR:
      return clear();
    case TAG_SYNC:
      return synchronize(p_data);
    case TAG_FIRM_INFO:
      return firmware_info(p_data);
    case TAG_MODULATION:
      return write_mod(p_data);
    case TAG_MODULATION_CHANGE_SEGMENT:
      return change_mod_segment(p_data);
    case TAG_SILENCER:
      return config_silencer(p_data);
    case TAG_GAIN:
      return write_gain(p_data);
    case TAG_GAIN_CHANGE_SEGMENT:
      return change_gain_segment(p_data);
    case TAG_FOCI_STM:
      return write_foci_stm(p_data);
    case TAG_GAIN_STM:
      return write_gain_stm(p_data);
    case TAG_GAIN_STM_CHANGE_SEGMENT:
      return change_gain_stm_segment(p_data);
    case TAG_FOCI_STM_CHANGE_SEGMENT:
      return change_foci_stm_segment(p_data);
    case TAG_FORCE_FAN:
      return configure_force_fan(p_data);
    case TAG_READS_FPGA_STATE:
      return configure_reads_fpga_state(p_data);
    case TAG_CONFIG_PULSE_WIDTH_ENCODER:
      return config_pwe(p_data);
    case TAG_DEBUG:
      return configure_debug(p_data);
    case TAG_EMULATE_GPIO_IN:
      return emulate_gpio_in(p_data);
    default:
      return ERR_NOT_SUPPORTED_TAG;
  }
}

#define AL_STATUS_CODE_SYNC_ERR (0x001A)
#define AL_STATUS_CODE_SYNC_MANAGER_WATCHDOG (0x001B)

void update(void) {
  volatile uint8_t* p_data;
  Header* header;

  if ((ECATC.AL_STATUS_CODE.WORD == AL_STATUS_CODE_SYNC_ERR) ||
      (ECATC.AL_STATUS_CODE.WORD == AL_STATUS_CODE_SYNC_MANAGER_WATCHDOG)) {
    if (_wdt_cnt < 0) return;
    if (_wdt_cnt == 0) clear();
    _wdt_cnt = _wdt_cnt - 1;
  } else {
    _wdt_cnt = WDT_CNT_MAX;
  }

  read_fpga_state();

  if (pop(&_data)) {
    p_data = (volatile uint8_t*)&_data;
    header = (Header*)p_data;
    if ((header->msg_id & 0x80) != 0) {
      _ack = ERR_INVALID_MSG_ID;
      goto FINISH;
    }

    _ack = handle_payload(&p_data[sizeof(Header)]);
    if ((_ack & ERR_BIT) != 0) goto FINISH;
    if (header->slot_2_offset != 0) {
      _ack |= handle_payload(&p_data[sizeof(Header) + header->slot_2_offset]);
      if ((_ack & ERR_BIT) != 0) goto FINISH;
    }

    bram_write(BRAM_SELECT_CONTROLLER, ADDR_CTL_FLAG, _fpga_flags_internal);

    _ack = header->msg_id;
  } else {
    dly_tsk(1);
  }

FINISH:
  _sTx.ack = (((uint16_t)_ack) << 8) | _rx_data;
}

static uint8_t _last_msg_id = 0xFF;
void recv_ethercat(uint16_t* p_data) {
  Header* header = (Header*)p_data;
  if (header->msg_id == _last_msg_id) return;
  if (push(p_data)) _last_msg_id = header->msg_id;
}

#ifdef __cplusplus
}
#endif
