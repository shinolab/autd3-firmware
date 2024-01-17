# 5.1.0

- Return `READS_FPGA_INFO_ENABLED` in rx data if reads FPGA info is enabled

# 5.0.1

- Fix [#3](https://github.com/shinolab/autd3-firmware/issues/3): v5.0.0 firmware's emulator bit is set

# 5.0.0

- Add Silencer with fixed completion steps algorithm
- An error is now returned for invalid data

# 4.1.2

- Fix [#2](https://github.com/shinolab/autd3-firmware/issues/2): Page is not update when Modulation or FocusSTM is sent with a data length that is an integer multiple of Page size

# 4.1.1

- Fix [#1](https://github.com/shinolab/autd3-firmware/issues/1): Modulation do not be applied correctly when the size is larger than 32768
