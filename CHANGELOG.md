# 12.1.0

- Add output mask operation

# 12.0.0

- Optimize error handling
- Add `SYNC_DIFF` GPIO output type

# 11.0.0

- Optimize STM memory usage: supports 65536 foci in total, regardless of the number of foci per pattern
- The period of ultrasound is changed from 256 to 512
    - The maximum value of pulse width is changed from 255 to 511
- Remove silencer target
- FPGA (estimated) power consumption increased from 367mW to 456mW

# 10.0.1

- phase correction bram and pulse width encoder table reset to default in clear op

# 10.0.0

- Change silencer minimum update rate from 2pi/256 to 2pi/65536
- Add `DBG_SYS_TIME_EQ` debug type
- Add phase correction operation
- (internal) Make `sys_time` 56 bit

# 9.1.0

- Add `cpu_gpio_out` operation

# 9.0.0

- Change ultrasound period to 256 from 512
    - Changed main clock frequency to 10.24MHz
    - Remove dynamic reconfiguration function
    - Change pulse width encoder table size to 256
- Silencer can now be applied to pulse width
- Invert the sign of the phase

# 8.0.1

- Fixed a bug when page capacity equals write data volume in `FociSTM`

# 8.0.0

- Do not clear full width start param of Pulse Width Encoder
- FocusSTM is now FociSTM with maximum 8 foci
    - Maximum pattern size of FociSTM is now 8192
- The unit of sound speed is now (1/64 * (ultrasound freq) / 40 [kHz]) [m/s]
- Remove phase filter

# 7.0.0

- Add new segment transition mode
    - SysTime
    - GPIO
    - Ext
- Return errors more strictly for invalid operations
- Validate silencer setting only for current segment
- Allows ultrasound frequency to be changed
- Fix configure PulseWidthEncoder operation

# 6.1.0

- Add new debug output settings

# 6.0.1

- Minor performance improvements

# 5.1.0

- Return `READS_FPGA_STATE_ENABLED` in rx data if reads FPGA info is enabled

# 5.0.1

- Fix [#3](https://github.com/shinolab/autd3-firmware/issues/3): v5.0.0 firmware's emulator bit is set

# 5.0.0

- Add Silencer with fixed completion steps algorithm
- An error is now returned for invalid data

# 4.1.2

- Fix [#2](https://github.com/shinolab/autd3-firmware/issues/2): Page is not update when Modulation or FocusSTM is sent with a data length that is an integer multiple of Page size

# 4.1.1

- Fix [#1](https://github.com/shinolab/autd3-firmware/issues/1): Modulation do not be applied correctly when the size is larger than 32768
