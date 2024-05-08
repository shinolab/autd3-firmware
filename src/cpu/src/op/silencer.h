#ifndef OP_SILENCER_H_
#define OP_SILENCER_H_

#include "app.h"

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
  uint16_t value_intensity;
  uint16_t value_phase;
} ConfigSilencer;

#endif  // OP_SILENCER_H_
