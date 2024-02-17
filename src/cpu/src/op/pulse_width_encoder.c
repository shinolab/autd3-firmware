#ifdef __cplusplus
extern "C" {
#endif

#include <assert.h>
#include <stddef.h>
#include <stdio.h>

#include "app.h"
#include "params.h"
#include "utils.h"

#define PWE_TABLE_PAGE_SIZE_WIDTH (15)
#define PWE_TABLE_PAGE_SIZE (1 << PWE_TABLE_PAGE_SIZE_WIDTH)
#define PWE_TABLE_PAGE_SIZE_MASK (PWE_TABLE_PAGE_SIZE - 1)

volatile uint32_t _pwe_write;

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

inline static void change_pwe_wr_page(uint16_t page) {
  asm("dmb");
  bram_write(BRAM_SELECT_CONTROLLER,
             BRAM_ADDR_PULSE_WIDTH_ENCODER_TABLE_WR_PAGE, page);
  asm("dmb");
}

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

  uint32_t page_capacity;
  const PWE* p = (const PWE*)p_data;
  uint16_t size = p->subseq.size;
  if (size % 2 != 0) return ERR_INVALID_PWE_DATA_SIZE;

  const uint16_t* data;
  if ((p->subseq.flag & PULSE_WIDTH_ENCODER_FLAG_BEGIN) ==
      PULSE_WIDTH_ENCODER_FLAG_BEGIN) {
    _pwe_write = 0;

    bram_write(BRAM_SELECT_CONTROLLER,
               BRAM_ADDR_PULSE_WIDTH_ENCODER_FULL_WIDTH_START,
               p->head.full_width_start);

    change_pwe_wr_page(0);

    data = (const uint16_t*)(&p_data[sizeof(PWEHead)]);
  } else {
    data = (const uint16_t*)(&p_data[sizeof(PWESubseq)]);
  }

  page_capacity = (_pwe_write & ~PWE_TABLE_PAGE_SIZE_MASK) +
                  PWE_TABLE_PAGE_SIZE - _pwe_write;

  if (size < page_capacity) {
    bram_cpy(BRAM_SELECT_DUTY_TABLE,
             (_pwe_write & PWE_TABLE_PAGE_SIZE_MASK) >> 1, data, (size >> 1));
    _pwe_write = _pwe_write + size;
  } else {
    bram_cpy(BRAM_SELECT_DUTY_TABLE,
             (_pwe_write & PWE_TABLE_PAGE_SIZE_MASK) >> 1, data,
             page_capacity >> 1);
    _pwe_write = _pwe_write + page_capacity;
    change_pwe_wr_page((_pwe_write & ~PWE_TABLE_PAGE_SIZE_MASK) >>
                       PWE_TABLE_PAGE_SIZE_WIDTH);
    data = data + (page_capacity >> 1);
    bram_cpy(BRAM_SELECT_DUTY_TABLE,
             (_pwe_write & PWE_TABLE_PAGE_SIZE_MASK) >> 1, data,
             (size - page_capacity) >> 1);
    _pwe_write = _pwe_write + size - page_capacity;
  }

  if ((p->subseq.flag & PULSE_WIDTH_ENCODER_FLAG_END) ==
      PULSE_WIDTH_ENCODER_FLAG_END) {
    if (_pwe_write != 65536) return ERR_PWE_INCOMPLETE_DATA;
  }

  return NO_ERR;
}

#ifdef __cplusplus
}
#endif
