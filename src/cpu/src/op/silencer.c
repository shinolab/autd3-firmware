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
extern volatile uint16_t _mod_freq_div[2];
extern volatile uint16_t _stm_freq_div[2];

bool_t _silencer_strict_mode;
uint16_t _min_freq_div_intensity;
uint16_t _min_freq_div_phase;

bool_t validate_silencer_settings(const uint16_t stm_freq_div,
                                  const uint16_t mod_freq_div) {
  if (_silencer_strict_mode) {
    if ((mod_freq_div < _min_freq_div_intensity) ||
        (stm_freq_div < _min_freq_div_intensity) ||
        (stm_freq_div < _min_freq_div_phase))
      return true;
  }
  return false;
}

uint8_t config_silencer(const volatile uint8_t* p_data) {
  static_assert(sizeof(ConfigSilencer) == 4, "ConfigSilencer is not valid.");
  static_assert(offsetof(ConfigSilencer, tag) == 0,
                "ConfigSilencer is not valid.");
  static_assert(offsetof(ConfigSilencer, flag) == 1,
                "ConfigSilencer is not valid.");
  static_assert(offsetof(ConfigSilencer, value_intensity) == 2,
                "ConfigSilencer is not valid.");
  static_assert(offsetof(ConfigSilencer, value_phase) == 3,
                "ConfigSilencer is not valid.");

  const ConfigSilencer* p = (const ConfigSilencer*)p_data;
  const uint16_t value_intensity = (uint16_t)p->value_intensity;
  const uint16_t value_phase = (uint16_t)p->value_phase;
  const uint8_t flag = p->flag;
  bool_t strict_mode;
  uint16_t min_freq_div_intensity;
  uint16_t min_freq_div_phase;

  if ((flag & SILENCER_FLAG_FIXED_UPDATE_RATE_MODE) ==
      SILENCER_FLAG_FIXED_UPDATE_RATE_MODE) {
    bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_UPDATE_RATE_INTENSITY,
               value_intensity);
    bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_UPDATE_RATE_PHASE,
               value_phase);
    bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_FLAG, flag);
    _silencer_strict_mode = false;
  } else {
    strict_mode = _silencer_strict_mode;
    min_freq_div_intensity = _min_freq_div_intensity;
    min_freq_div_phase = _min_freq_div_phase;

    _silencer_strict_mode = (flag & SILENCER_FLAG_STRICT_MODE) != 0;
    _min_freq_div_intensity = value_intensity;
    _min_freq_div_phase = value_phase;
    if (validate_silencer_settings(_stm_freq_div[_stm_segment],
                                   _mod_freq_div[_mod_segment])) {
      _silencer_strict_mode = strict_mode;
      _min_freq_div_intensity = min_freq_div_intensity;
      _min_freq_div_phase = min_freq_div_phase;
      return ERR_INVALID_SILENCER_SETTING;
    }

    bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_COMPLETION_STEPS_INTENSITY,
               value_intensity);
    bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_COMPLETION_STEPS_PHASE,
               value_phase);
    bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_FLAG, flag);
  }

  set_and_wait_update(CTL_FLAG_SILENCER_SET);

  return NO_ERR;
}

#ifdef __cplusplus
}
#endif
