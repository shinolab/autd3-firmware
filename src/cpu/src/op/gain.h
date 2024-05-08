#ifndef OP_GAIN_H_
#define OP_GAIN_H_

#include "app.h"

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t segment;
  uint8_t flag;
  uint8_t __pad;
} Gain;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t segment;
} GainUpdate;

#endif  // OP_GAIN_H_
