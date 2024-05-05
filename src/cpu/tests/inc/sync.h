#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

extern int is_sync;
extern uint64_t sync_time;

inline static uint64_t get_next_sync0() {
  is_sync = 1;
  return sync_time;
}

#ifdef __cplusplus
}
#endif
