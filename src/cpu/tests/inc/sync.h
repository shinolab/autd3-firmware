// File: sync.h
// Project: inc
// Created Date: 31/12/2023
// Author: Shun Suzuki
// -----
// Last Modified: 31/12/2023
// Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
// -----
// Copyright (c) 2023 Shun Suzuki. All rights reserved.
//

#pragma once

#include <stdint.h>
#include <stdio.h>

#include "params.h"

#ifdef __cplusplus
extern "C" {
#endif

extern int is_sync;

static inline uint8_t synchronize(void) {
  is_sync = 1;
  return ERR_NONE;
}

#ifdef __cplusplus
}
#endif
