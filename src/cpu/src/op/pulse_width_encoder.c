#ifdef __cplusplus
extern "C" {
#endif

#include <assert.h>
#include <stddef.h>
#include <stdio.h>

#include "app.h"
#include "params.h"
#include "utils.h"

volatile uint16_t _pwe_write;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
  uint16_t size;
  uint16_t full_width_start;
} PWEHead;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
  uint16_t size;
} PWESubseq;

typedef ALIGN2 union {
  PWEHead head;
  PWESubseq subseq;
} PWE;

uint8_t config_pwe(const volatile uint8_t* p_data) {
  static_assert(sizeof(PWEHead) == 6, "PWE is not valid.");
  static_assert(offsetof(PWEHead, tag) == 0, "PWE is not valid.");
  static_assert(offsetof(PWEHead, flag) == 1, "PWE is not valid.");
  static_assert(offsetof(PWEHead, size) == 2, "PWE is not valid.");
  static_assert(offsetof(PWEHead, full_width_start) == 4, "PWE is not valid.");
  static_assert(sizeof(PWESubseq) == 4, "PWE is not valid.");
  static_assert(offsetof(PWESubseq, tag) == 0, "PWE is not valid.");
  static_assert(offsetof(PWESubseq, flag) == 1, "PWE is not valid.");
  static_assert(offsetof(PWESubseq, size) == 2, "PWE is not valid.");
  static_assert(offsetof(PWE, head) == 0, "PWE is not valid.");
  static_assert(offsetof(PWE, subseq) == 0, "PWE is not valid.");
  static_assert(sizeof(PWE) == 6, "PWE is not valid.");

  const PWE* p = (const PWE*)p_data;
  uint16_t size = p->subseq.size;
  if (size % 2 != 0) return ERR_INVALID_PWE_DATA_SIZE;

  const uint16_t* data;
  if ((p->subseq.flag & PULSE_WIDTH_ENCODER_FLAG_BEGIN) == PULSE_WIDTH_ENCODER_FLAG_BEGIN) {
    _pwe_write = 0;

    bram_write(BRAM_SELECT_CONTROLLER, ADDR_PULSE_WIDTH_ENCODER_FULL_WIDTH_START, p->head.full_width_start);

    data = (const uint16_t*)(&p_data[sizeof(PWEHead)]);
  } else {
    data = (const uint16_t*)(&p_data[sizeof(PWESubseq)]);
  }

  bram_cpy(BRAM_SELECT_DUTY_TABLE, _pwe_write >> 1, data, (size >> 1));
  _pwe_write = _pwe_write + size;

  if ((p->subseq.flag & PULSE_WIDTH_ENCODER_FLAG_END) == PULSE_WIDTH_ENCODER_FLAG_END) {
    if (_pwe_write != 32768) return ERR_PWE_INCOMPLETE_DATA;
    set_and_wait_update(CTL_FLAG_PULSE_WIDTH_ENCODER_SET);
  }

  return NO_ERR;
}

#ifdef __cplusplus
}
#endif
