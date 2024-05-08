#ifndef OP_SILENCER_H_
#define OP_SILENCER_H_

#include "app.h"

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
  uint16_t value_intensity;
  uint16_t value_phase;
} ConfigSilencer;

inline static bool_t validate_silencer_settings(
    const bool_t strict_mode, const uint32_t min_freq_div_intensity,
    const uint32_t min_freq_div_phase, const uint32_t stm_freq_div,
    const uint32_t mod_freq_div) {
  if (strict_mode) {
    if ((mod_freq_div < min_freq_div_intensity) ||
        (stm_freq_div < min_freq_div_intensity) ||
        (stm_freq_div < min_freq_div_phase))
      return true;
  }
  return false;
}

#endif  // OP_SILENCER_H_
