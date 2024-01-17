// File: iodefine.h
// Project: inc
// Created Date: 31/12/2023
// Author: Shun Suzuki
// -----
// Last Modified: 17/01/2024
// Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
// -----
// Copyright (c) 2023 Shun Suzuki. All rights reserved.
//

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  union {
    unsigned short WORD;
    struct {
      unsigned short STATUSCODE : 16;
    } BIT;
  } AL_STATUS_CODE;
} st_ecatc_t;

extern st_ecatc_t ECATC;

#ifdef __cplusplus
}
#endif
