/*
 * File: app.c
 * Project: src
 * Created Date: 22/04/2022
 * Author: Shun Suzuki
 * -----
 * Last Modified: 01/01/2024
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2022-2023 Shun Suzuki. All rights reserved.
 *
 */

#ifdef __cplusplus
extern "C" {
#endif

#include "app.h"

#include "ecat.h"
#include "iodefine.h"
#include "kernel.h"
#include "op/clear.h"
#include "op/debug.h"
#include "op/focus_stm.h"
#include "op/force_fan.h"
#include "op/gain.h"
#include "op/gain_stm.h"
#include "op/info.h"
#include "op/mod.h"
#include "op/mod_delay.h"
#include "op/reads_fpga_info.h"
#include "op/silencer.h"
#include "params.h"
#include "sync.h"
#include "utils.h"

#define WDT_CNT_MAX (500)

extern TX_STR _sTx;

#define BUF_SIZE (64)
static volatile RX_STR _buf[BUF_SIZE];
volatile uint8_t _write_cursor;
volatile uint8_t _read_cursor;

static volatile RX_STR _data;

bool_t push(const volatile uint16_t* p_data) {
  uint32_t next;
  next = _write_cursor + 1;

  if (next >= BUF_SIZE) next = 0;

  if (next == _read_cursor) return false;

  word_cpy((uint16_t*)&_buf[_write_cursor], (uint16_t*)p_data, 249);
  word_cpy(((uint16_t*)&_buf[_write_cursor]) + 249, (uint16_t*)&p_data[249 + 1], 64);

  _write_cursor = next;

  return true;
}

bool_t pop(volatile RX_STR* p_data) {
  uint32_t next;

  if (_read_cursor == _write_cursor) return false;

  memcpy_volatile(p_data, &_buf[_read_cursor], sizeof(RX_STR));

  next = _read_cursor + 1;
  if (next >= BUF_SIZE) next = 0;

  _read_cursor = next;

  return true;
}

// fire when ethercat packet arrives
extern void recv_ethercat(uint16_t* p_data);
// fire once after power on
extern void init_app(void);
// fire periodically with 1ms interval
extern void update(void);

static volatile uint8_t _ack = 0;
volatile uint8_t _rx_data = 0;
volatile bool_t _read_fpga_info;
volatile bool_t _read_fpga_info_store;

volatile uint32_t _mod_cycle = 0;
volatile uint32_t _mod_freq_div = 0;

volatile uint32_t _stm_cycle = 0;
volatile uint32_t _stm_freq_div = 0;
volatile uint16_t _gain_stm_mode = GAIN_STM_MODE_INTENSITY_PHASE_FULL;

volatile uint16_t _fpga_flags_internal = 0;

volatile bool_t _silencer_strict_mode;
volatile uint32_t _min_freq_div_intensity;
volatile uint32_t _min_freq_div_phase;

static volatile short _wdt_cnt = WDT_CNT_MAX;

void init_app(void) { clear(); }

uint8_t handle_payload(uint8_t tag, const volatile uint8_t* p_data) {
  switch (tag) {
    case TAG_NONE:
      return ERR_NONE;
    case TAG_CLEAR:
      return clear();
    case TAG_SYNC:
      return synchronize();
    case TAG_FIRM_INFO:
      return firmware_info(p_data);
    case TAG_MODULATION:
      return write_mod(p_data);
    case TAG_MODULATION_DELAY:
      return write_mod_delay(p_data);
    case TAG_SILENCER:
      return config_silencer(p_data);
    case TAG_GAIN:
      return write_gain(p_data);
    case TAG_FOCUS_STM:
      return write_focus_stm(p_data);
    case TAG_GAIN_STM:
      return write_gain_stm(p_data);
    case TAG_FORCE_FAN:
      return configure_force_fan(p_data);
    case TAG_READS_FPGA_INFO:
      return configure_reads_fpga_info(p_data);
    case TAG_DEBUG:
      return configure_debug(p_data);
    default:
      return ERR_NOT_SUPPORTED_TAG;
  }
}

#define AL_STATUS_CODE_SYNC_ERR (0x001A)
#define AL_STATUS_CODE_SYNC_MANAGER_WATCHDOG (0x001B)

void update(void) {
  volatile uint8_t* p_data;
  Header* header;

  if ((ECATC.AL_STATUS_CODE.WORD == AL_STATUS_CODE_SYNC_ERR) || (ECATC.AL_STATUS_CODE.WORD == AL_STATUS_CODE_SYNC_MANAGER_WATCHDOG)) {
    if (_wdt_cnt < 0) return;
    if (_wdt_cnt == 0) clear();
    _wdt_cnt = _wdt_cnt - 1;
  } else {
    _wdt_cnt = WDT_CNT_MAX;
  }

  if (pop(&_data)) {
    p_data = (volatile uint8_t*)&_data;
    header = (Header*)p_data;
    if ((header->msg_id & 0x80) != 0) {
      _ack = ERR_INVALID_MSG_ID;
      goto FINISH;
    }

    _ack = handle_payload(p_data[sizeof(Header)], &p_data[sizeof(Header)]);
    if (_ack != ERR_NONE) goto FINISH;
    if (header->slot_2_offset != 0) {
      _ack = handle_payload(p_data[sizeof(Header) + header->slot_2_offset], &p_data[sizeof(Header) + header->slot_2_offset]);
      if (_ack != ERR_NONE) goto FINISH;
    }

    _ack = header->msg_id;
    bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_CTL_FLAG, _fpga_flags_internal);
  } else {
    dly_tsk(1);
  }

FINISH:
  if (_read_fpga_info) _rx_data = read_fpga_info();
  _sTx.ack = (((uint16_t)_ack) << 8) | _rx_data;
}

static uint8_t _last_msg_id = 0;
void recv_ethercat(uint16_t* p_data) {
  Header* header = (Header*)p_data;
  if (header->msg_id == _last_msg_id) return;
  if (push(p_data)) _last_msg_id = header->msg_id;
}

#ifdef __cplusplus
}
#endif
