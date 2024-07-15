#ifndef OP_GAIN_STM_H_
#define OP_GAIN_STM_H_

#include "app.h"

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
  uint8_t mode;
  uint8_t transition_mode;
  uint16_t freq_div;
  uint16_t rep;
  uint64_t transition_value;
} GainSTMHead;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
} GainSTMSubseq;

typedef union {
  GainSTMHead head;
  GainSTMSubseq subseq;
} GainSTM;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t segment;
  uint8_t transition_mode;
  uint8_t _pad[5];
  uint64_t transition_value;
} GainSTMUpdate;

#endif  // OP_GAIN_STM_H_
