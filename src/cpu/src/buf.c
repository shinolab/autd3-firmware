/*
 * File: buf.c
 * Project: src
 * Created Date: 17/01/2024
 * Author: Shun Suzuki
 * -----
 * Last Modified: 17/01/2024
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2024 Shun Suzuki. All rights reserved.
 *
 */

#ifdef __cplusplus
extern "C" {
#endif

#include "app.h"
#include "ecat.h"
#include "utils.h"

#define BUF_SIZE (64)

static volatile RX_STR _buf[BUF_SIZE];
volatile uint8_t _write_cursor;
volatile uint8_t _read_cursor;

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

#ifdef __cplusplus
}
#endif