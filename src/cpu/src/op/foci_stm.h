#ifndef OP_FOCUS_STM_H_
#define OP_FOCUS_STM_H_

#include "app.h"

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
  uint8_t send_num;
  uint8_t segment;
  uint8_t transition_mode;
  uint8_t num_foci;
  uint16_t sound_speed;
  uint16_t freq_div;
  uint16_t rep;
  uint8_t _pad[4];
  uint64_t transition_value;
} FocusSTMHead;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
  uint8_t send_num;
  uint8_t segment;
} FocusSTMSubseq;

typedef union {
  FocusSTMHead head;
  FocusSTMSubseq subseq;
} FocusSTM;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t segment;
  uint8_t transition_mode;
  uint8_t _pad[5];
  uint64_t transition_value;
} FocusSTMUpdate;

#endif  // OP_FOCUS_STM_H_
