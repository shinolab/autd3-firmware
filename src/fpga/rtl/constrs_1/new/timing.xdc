set_input_delay -clock cpu_bsc_75M -min 0.200 [get_ports CPU_WE0_N]
set_input_delay -clock cpu_bsc_75M -max 0.500 [get_ports CPU_WE0_N]
set_input_delay -clock cpu_bsc_75M -min 0.200 [get_ports CPU_CS1_N]
set_input_delay -clock cpu_bsc_75M -max 0.500 [get_ports CPU_CS1_N]
set_input_delay -clock cpu_bsc_75M -min 0.200 [get_ports CPU_DATA*]
set_input_delay -clock cpu_bsc_75M -max 0.500 [get_ports CPU_DATA*]
set_input_delay -clock cpu_bsc_75M -min 0.200 [get_ports CPU_ADDR*]
set_input_delay -clock cpu_bsc_75M -max 0.500 [get_ports CPU_ADDR*]
set_output_delay -clock cpu_bsc_75M -min 0.200 [get_ports CPU_DATA*]
set_output_delay -clock cpu_bsc_75M -max 0.500 [get_ports CPU_DATA*]

set_input_delay -clock [get_clocks -of_objects [get_pins main/clock/mmcm_adv_inst/CLKOUT0]] -min 0.500 [get_ports CAT_SYNC0]
set_input_delay -clock [get_clocks -of_objects [get_pins main/clock/mmcm_adv_inst/CLKOUT0]] -max 1.500 [get_ports CAT_SYNC0]
set_input_delay -clock [get_clocks -of_objects [get_pins main/clock/mmcm_adv_inst/CLKOUT0]] -min 0.500 [get_ports RESET_N]
set_input_delay -clock [get_clocks -of_objects [get_pins main/clock/mmcm_adv_inst/CLKOUT0]] -max 1.500 [get_ports RESET_N]
set_input_delay -clock [get_clocks -of_objects [get_pins main/clock/mmcm_adv_inst/CLKOUT0]] -min 0.500 [get_ports THERMO]
set_input_delay -clock [get_clocks -of_objects [get_pins main/clock/mmcm_adv_inst/CLKOUT0]] -max 1.500 [get_ports THERMO]
set_input_delay -clock [get_clocks -of_objects [get_pins main/clock/mmcm_adv_inst/CLKOUT0]] -min 0.500 [get_ports GPIO_IN*]
set_input_delay -clock [get_clocks -of_objects [get_pins main/clock/mmcm_adv_inst/CLKOUT0]] -max 1.500 [get_ports GPIO_IN*]
set_output_delay -clock [get_clocks -of_objects [get_pins main/clock/mmcm_adv_inst/CLKOUT0]] -min 0.500 [get_ports FORCE_FAN*]
set_output_delay -clock [get_clocks -of_objects [get_pins main/clock/mmcm_adv_inst/CLKOUT0]] -max 1.500 [get_ports FORCE_FAN*]
set_output_delay -clock [get_clocks -of_objects [get_pins main/clock/mmcm_adv_inst/CLKOUT0]] -min 0.500 [get_ports XDCR_OUT*]
set_output_delay -clock [get_clocks -of_objects [get_pins main/clock/mmcm_adv_inst/CLKOUT0]] -max 1.500 [get_ports XDCR_OUT*]
set_output_delay -clock [get_clocks -of_objects [get_pins main/clock/mmcm_adv_inst/CLKOUT0]] -min 0.500 [get_ports GPIO_OUT*]
set_output_delay -clock [get_clocks -of_objects [get_pins main/clock/mmcm_adv_inst/CLKOUT0]] -max 1.500 [get_ports GPIO_OUT*]

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
