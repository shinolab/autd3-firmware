#ifdef __cplusplus
extern "C" {
#endif

#include <assert.h>
#include <stddef.h>

#include "app.h"
#include "params.h"

extern volatile uint32_t _mod_freq_div;
extern volatile uint32_t _stm_freq_div;

volatile bool_t _silencer_strict_mode;
volatile uint32_t _min_freq_div_intensity;
volatile uint32_t _min_freq_div_phase;

typedef ALIGN2 struct {
  uint8_t tag;
  uint8_t flag;
  uint16_t value_intensity;
  uint16_t value_phase;
} ConfigSilencer;

uint8_t config_silencer(const volatile uint8_t* p_data) {
  static_assert(sizeof(ConfigSilencer) == 6, "ConfigSilencer is not valid.");
  static_assert(offsetof(ConfigSilencer, tag) == 0,
                "ConfigSilencer is not valid.");
  static_assert(offsetof(ConfigSilencer, flag) == 1,
                "ConfigSilencer is not valid.");
  static_assert(offsetof(ConfigSilencer, value_intensity) == 2,
                "ConfigSilencer is not valid.");
  static_assert(offsetof(ConfigSilencer, value_phase) == 4,
                "ConfigSilencer is not valid.");

  const ConfigSilencer* p = (const ConfigSilencer*)p_data;
  const uint16_t value_intensity = p->value_intensity;
  const uint16_t value_phase = p->value_phase;
  const uint8_t flag = p->flag;

  switch (flag & SILNCER_FLAG_MODE) {
    case SILNCER_MODE_FIXED_COMPLETION_STEPS:
      _silencer_strict_mode = (flag & SILNCER_FLAG_STRICT_MODE) != 0;
      _min_freq_div_intensity = (uint32_t)value_intensity << 9;
      _min_freq_div_phase = (uint32_t)value_phase << 9;
      if (_silencer_strict_mode) {
        if (_mod_freq_div < _min_freq_div_intensity)
          return ERR_COMPLETION_STEPS_TOO_LARGE;
        if ((_stm_freq_div < _min_freq_div_intensity) ||
            (_stm_freq_div < _min_freq_div_phase))
          return ERR_COMPLETION_STEPS_TOO_LARGE;
      }
      bram_write(BRAM_SELECT_CONTROLLER,
                 BRAM_ADDR_SILENCER_COMPLETION_STEPS_INTENSITY,
                 value_intensity);
      bram_write(BRAM_SELECT_CONTROLLER,
                 BRAM_ADDR_SILENCER_COMPLETION_STEPS_PHASE, value_phase);
      bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_SILENCER_MODE,
                 SILNCER_MODE_FIXED_COMPLETION_STEPS);
      break;
    case SILNCER_MODE_FIXED_UPDATE_RATE:
      bram_write(BRAM_SELECT_CONTROLLER,
                 BRAM_ADDR_SILENCER_UPDATE_RATE_INTENSITY, value_intensity);
      bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_SILENCER_UPDATE_RATE_PHASE,
                 value_phase);
      bram_write(BRAM_SELECT_CONTROLLER, BRAM_ADDR_SILENCER_MODE,
                 SILNCER_MODE_FIXED_UPDATE_RATE);
      _silencer_strict_mode = false;
      break;
    default:
      return ERR_INVALID_MODE;
  }

  return NO_ERR | REQ_UPDATE_SETTINGS;
}

#ifdef __cplusplus
}
#endif
