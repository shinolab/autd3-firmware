# AUTD3 firmware

> [!IMPORTANT]
> **This repository is part of the legacy AUTD3 series.**
> New development has moved to [**autd3-sdk**](https://github.com/shinolab/autd3-sdk), a new
> generation of the SDK that is **not compatible** with this series.
> See the [autd3-sdk documentation](https://shinolab.github.io/autd3-sdk/) to get started.

![build](https://github.com/shinolab/autd3-firmware/workflows/build/badge.svg)
[![codecov](https://codecov.io/gh/shinolab/autd3-firmware/graph/badge.svg?precision=2)](https://codecov.io/gh/shinolab/autd3-firmware)
[![release](https://img.shields.io/github/v/release/shinolab/autd3-firmware)](https://github.com/shinolab/autd3-firmware/releases/latest)

## Update Instructions (Windows 64 bit only)

### Requirements

Please install the following software.

* [Vivado Lab Edition or ML Edition](https://www.xilinx.com/products/design-tools/vivado.html)
   * If you only want to update the firmware, we strongly recommend using the **Lab Edition**.
      * The Lab Edition requires only about 6 GB of disk space, whereas the ML Edition requires over 60 GB.
   * Tested with Vivado 2025.2
* [J-Link Software](https://www.segger.com/downloads/jlink/)
   * **"legacy USB Driver for J-Link"** is required for older J-Link devices.
      * Refer to [this page](https://wiki.segger.com/J-Link_Model_Overview). If your J-Link device has the WinUSB feature, you do not need to install the legacy driver.
   * Tested with J-Link Software V8.46 (x64)

The following hardware is also required:

* **For the FPGA:**: [XILINX Platform Cable](https://www.xilinx.com/products/boards-and-kits/hw-usb-ii-g.html)
* **For the CPU board:** [J-Link Plus](https://www.segger.com/products/debug-probes/j-link/models/j-link-plus/) & [J-Link 9-Pin Cortex-M Adapter](https://www.segger-pocjapan.com/j-link-9-pin-cortex-m-adapter)

### Update Process

1.  Ensure the AUTD3 device is connected via the appropriate cables and is powered on.
2.  Run `autd_firmware_writer.ps1` from PowerShell.

# Author

Shun Suzuki, 2022-2026
