# AUTD3 firmware

![build](https://github.com/shinolab/autd3-firmware/workflows/build/badge.svg)
[![codecov](https://codecov.io/gh/shinolab/autd3-firmware/graph/badge.svg?precision=2)](https://codecov.io/gh/shinolab/autd3-firmware)
[![release](https://img.shields.io/github/v/release/shinolab/autd3-firmware)](https://github.com/shinolab/autd3-firmware/releases/latest)

## Usage (Windows 64bit only)

### Requirements

Please install following softwares.

* Vivado Lab edition or ML edition (https://www.xilinx.com/products/design-tools/vivado.html)
    * If you only want to update the firmware, we strongly recommend you to use Lab edition
        * Lab edition requires only about 6GB of disk space, while ML edition requires more than 60GB
    * Tested with Vivado 2025.1
* J-Link Software (https://www.segger.com/downloads/jlink/)
    * **legacy USB Driver for J-Link** is required for old J-Link devices
        * See [here](https://wiki.segger.com/J-Link_Model_Overview) and if your J-Link device has WinUSB feature, you don't need to install the legacy driver
    * Tested with J-Link Software V8.10 (x64)

Also, the following cables are required

* FPGA: [XILINX Platform Cable](https://www.xilinx.com/products/boards-and-kits/hw-usb-ii-g.html)
* CPU board: [J-Link Plus](https://www.segger.com/products/debug-probes/j-link/models/j-link-plus/) & [J-Link 9-Pin Cortex-M Adapter](https://www.segger-pocjapan.com/j-link-9-pin-cortex-m-adapter)

### Update

Make sure that AUTD3 device is connected via appropriate cables and power on. Then, run `autd_firmware_writer.ps1` from powershell.

# Author

Shun Suzuki, 2022-2025
