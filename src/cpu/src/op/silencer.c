#ifdef __cplusplus
extern "C" {
#endif

#include "silencer.h"

#include <assert.h>
#include <stddef.h>

#include "app.h"
#include "params.h"

extern volatile uint8_t _mod_segment;
extern volatile uint8_t _stm_segment;
extern volatile uint32_t _mod_freq_div[2];
extern volatile uint32_t _stm_freq_div[2];

volatile bool_t _silencer_strict_mode;
volatile uint32_t _min_freq_div_intensity;
volatile uint32_t _min_freq_div_phase;

bool_t validate_silencer_settings(const uint8_t stm_segment,
                                  const uint8_t mod_segment) {
  if (_silencer_strict_mode) {
    if ((_mod_freq_div[mod_segment] < _min_freq_div_intensity) ||
        (_stm_freq_div[stm_segment] < _min_freq_div_intensity) ||
        (_stm_freq_div[stm_segment] < _min_freq_div_phase))
      return true;
  }
  return false;
}

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

  if ((flag & SILENCER_FLAG_MODE) == SILENCER_MODE_FIXED_COMPLETION_STEPS) {
    _silencer_strict_mode = (flag & SILENCER_FLAG_STRICT_MODE) != 0;
    _min_freq_div_intensity = (uint32_t)value_intensity << 9;
    _min_freq_div_phase = (uint32_t)value_phase << 9;

    if (validate_silencer_settings(_stm_segment, _mod_segment))
      return ERR_INVALID_SILENCER_SETTING;
    bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_COMPLETION_STEPS_INTENSITY,
               value_intensity);
    bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_COMPLETION_STEPS_PHASE,
               value_phase);
    bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_MODE,
               SILENCER_MODE_FIXED_COMPLETION_STEPS);
  } else {
    bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_UPDATE_RATE_INTENSITY,
               value_intensity);
    bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_UPDATE_RATE_PHASE,
               value_phase);
    bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_MODE,
               SILENCER_MODE_FIXED_UPDATE_RATE);
    _silencer_strict_mode = false;
  }

  set_and_wait_update(CTL_FLAG_SILENCER_SET);

  return NO_ERR;
}

#ifdef __cplusplus
}
#endif
