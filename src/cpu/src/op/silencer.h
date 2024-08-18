#ifndef OP_SILENCER_H_
#define OP_SILENCER_H_

#include "app.h"

// TODO@v10: Remove ConfigSilencer
typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
  uint8_t value_intensity;
  uint8_t value_phase;
} ConfigSilencer;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
  uint16_t value_intensity;
  uint16_t value_phase;
} ConfigSilencer2;

bool_t validate_silencer_settings(const uint16_t stm_freq_div, const uint16_t mod_freq_div);

#endif  // OP_SILENCER_H_
