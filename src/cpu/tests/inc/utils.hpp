// File: utils.hpp
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

#include <cstring>
#include <vector>

#include "ecat.h"

inline std::vector<uint16_t> to_frame_data(RX_STR data) {
  std::vector<uint16_t> frame_data;
  frame_data.resize(249 + 1 + 64, 0x0000);
  std::memcpy(frame_data.data(), data.data, 249 * 2);
  std::memcpy(frame_data.data() + 249 + 1, data.data + 249, 64 * 2);
  return frame_data;
}
