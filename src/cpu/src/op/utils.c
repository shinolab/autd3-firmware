#ifdef __cplusplus
extern "C" {
#endif

#include <stddef.h>

#include "app.h"
#include "params.h"

bool_t validate_transition_mode(const uint8_t current_segment,
                                const uint8_t segment, const uint32_t rep,
                                const uint8_t mode) {
  if (mode == TRANSITION_MODE_NONE) return false;
  if (current_segment == segment) {
    return mode == TRANSITION_MODE_SYNC_IDX ||
           mode == TRANSITION_MODE_SYS_TIME || mode == TRANSITION_MODE_GPIO;
  }
  switch (rep) {
    case 0xFFFFFFFF:
      return mode == TRANSITION_MODE_SYNC_IDX ||
             mode == TRANSITION_MODE_SYS_TIME || mode == TRANSITION_MODE_GPIO;
    default:
      return mode == TRANSITION_MODE_IMMIDIATE || mode == TRANSITION_MODE_EXT;
  }
}

#ifdef __cplusplus
}
#endif
