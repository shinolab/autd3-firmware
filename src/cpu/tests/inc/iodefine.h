// File: iodefine.h
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

typedef struct {
  union {
    unsigned short WORD;
    struct {
      unsigned short STATUSCODE : 16;
    } BIT;
  } AL_STATUS_CODE;
  union {
    unsigned long long LONGLONG;
  } DC_SYS_TIME;
  union {
    unsigned long long LONGLONG;
  } DC_CYC_START_TIME;
} st_ecatc_t;

st_ecatc_t ECATC;
