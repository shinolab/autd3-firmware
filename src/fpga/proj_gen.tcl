set project_directory   [file normalize [file dirname [info script]]]
set project_name        "autd3-fpga"

cd $project_directory
create_project -force $project_name $project_directory

set_property PART xc7a200tfbg676-2 [current_project]

set_property default_lib        xil_defaultlib [current_project]
set_property simulator_language Mixed          [current_project]
set_property target_language    Verilog        [current_project]

if {[string equal [get_filesets -quiet sources_1] ""]} {
    create_fileset -srcset sources_1
}

if {[string equal [get_filesets -quiet constrs_1] ""]} {
    create_fileset -constrset constrs_1
}

if {[string equal [get_filesets -quiet sim_1] ""]} {
    create_fileset -simset sim_1
}

set synth_flow              "Vivado Synthesis 2025"
set synth_strategy_default  "Vivado Synthesis Defaults"
set synth_strategy_alter    "Flow_AlternateRoutability"
create_run -name synth_default -flow $synth_flow -strategy $synth_strategy_default -constrset constrs_1
create_run -name synth_alter -flow $synth_flow -strategy $synth_strategy_alter -constrset constrs_1
current_run -synthesis [get_runs synth_default]

set impl_flow                "Vivado Implementation 2025"
set impl_strategy_default    "Vivado Implementation Defaults"
set impl_strategy_area       "Area_ExploreWithRemap"
set impl_strategy_fanout_opt "Performance_WLBlockPlacementFanoutOpt"
set impl_strategy_retiming   "Performance_Retiming"
create_run -name impl_def_def -flow $impl_flow -strategy $impl_strategy_default -constrset constrs_1 -parent_run synth_default
create_run -name impl_def_area -flow $impl_flow -strategy $impl_strategy_area -constrset constrs_1 -parent_run synth_default
create_run -name impl_def_fanout_opt -flow $impl_flow -strategy $impl_strategy_fanout_opt -constrset constrs_1 -parent_run synth_default
create_run -name impl_def_retiming -flow $impl_flow -strategy $impl_strategy_retiming -constrset constrs_1 -parent_run synth_default
create_run -name impl_alter_def -flow $impl_flow -strategy $impl_strategy_default -constrset constrs_1 -parent_run synth_alter
create_run -name impl_alter_area -flow $impl_flow -strategy $impl_strategy_area -constrset constrs_1 -parent_run synth_alter
create_run -name impl_alter_fanout_opt -flow $impl_flow -strategy $impl_strategy_fanout_opt -constrset constrs_1 -parent_run synth_alter
create_run -name impl_alter_retiming -flow $impl_flow -strategy $impl_strategy_retiming -constrset constrs_1 -parent_run synth_alter
current_run -implementation [get_runs impl_def_def]

delete_runs "impl_1"
delete_runs "synth_1"
delete_runs "impl_2"

add_files -fileset constrs_1 -norecurse [file join $project_directory "rtl/constrs_1/new/top.xdc"]
add_files -fileset constrs_1 -norecurse [file join $project_directory "rtl/constrs_1/new/timing.xdc"]
set_property used_in_synthesis false [get_files rtl/constrs_1/new/timing.xdc]

proc add_verilog_file {fileset_name library_name file_name} {
    set file    [file normalize $file_name]
    set fileset [get_filesets   $fileset_name] 
    add_files -norecurse -fileset $fileset $file
    set file_obj [get_files -of_objects $fileset $file]
    set_property "file_type" "SystemVerilog" $file_obj
    set_property "library" $library_name $file_obj
}
set file_list [glob -nocomplain -join rtl/sources_1/new/* *.sv]
foreach src_file_path $file_list {
  add_verilog_file sources_1 xil_defaultlib $src_file_path
}
set file_list [glob -nocomplain -join rtl/sources_1/new/*/** *.sv]
foreach src_file_path $file_list {
  add_verilog_file sources_1 xil_defaultlib $src_file_path
}
set file_list [glob -nocomplain rtl/sources_1/new/*.sv]
foreach src_file_path $file_list {
  add_verilog_file sources_1 xil_defaultlib $src_file_path
}

proc add_header_file {fileset_name library_name file_name} {
    set file    [file normalize $file_name]
    set fileset [get_filesets   $fileset_name] 
    add_files -norecurse -fileset $fileset $file
    set file_obj [get_files -of_objects $fileset $file]
    set_property "file_type" "Verilog Header" $file_obj
    set_property "library" $library_name $file_obj
}
set file_list [glob -nocomplain rtl/sources_1/new/headers/*.svh]
foreach header_file_path $file_list {
  add_header_file sources_1 xil_defaultlib $header_file_path
}
set file_list [glob -nocomplain rtl/sources_1/new/headers/*.vh]
foreach header_file_path $file_list {
  add_header_file sources_1 xil_defaultlib $header_file_path
}

set file_list [glob -nocomplain -join rtl/sources_1/ip/* *.xci]
foreach xci_file_path $file_list {
  import_ip $xci_file_path
}
set_property used_in_implementation false [get_files [file join $project_directory "autd3-fpga.srcs/sources_1/ip/sqrt_36_trunc/sqrt_36_trunc.xci"]]
set_property used_in_synthesis false [get_files [file join $project_directory "autd3-fpga.srcs/sources_1/ip/sqrt_36_trunc/sqrt_36_trunc.xci"]]

proc add_sim_file {fileset_name library_name file_name} {
    set file    [file normalize $file_name]
    set fileset [get_filesets   $fileset_name] 
    add_files -norecurse -fileset $fileset $file
    set file_obj [get_files -of_objects $fileset $file]
    set_property "file_type" "SystemVerilog" $file_obj
    set_property "library" $library_name $file_obj
}
set file_list [glob -nocomplain rtl/sim_1/new/*.sv]
foreach sim_file_path $file_list {
  add_sim_file sim_1 xil_defaultlib $sim_file_path
}
set file_list [glob -nocomplain -join rtl/sim_1/new/* *.sv]
foreach sim_file_path $file_list {
  add_sim_file sim_1 xil_defaultlib $sim_file_path
}
set_property -name {xsim.compile.tcl.pre} -value [file join $project_directory "rtl/sim_1/new/rand.tcl"] -objects [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]

add_files -fileset sim_1 -norecurse [file join $project_directory "rtl/sim_1/new/stm/atan.txt"]
add_files -fileset sim_1 -norecurse [file join $project_directory "rtl/sim_1/new/stm/sin.txt"]

set_msg_config -id {Synth 8-7080} -new_severity {ADVISORY}
set_msg_config -id {Synth 8-7129} -new_severity {ADVISORY}
set_msg_config -id {Synth 8-5640} -new_severity {ADVISORY}
# set_msg_config -id {Synth 8-5858} -new_severity {ADVISORY}

set_property top top [get_filesets sources_1]
set_property top sim_synchronizer [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

set header_list [glob -nocomplain rtl/sources_1/new/headers/*.svh]
foreach header_file $header_list {
  set_property is_global_include true [get_files $header_file]
  set_property file_type SystemVerilog [get_files $header_file]
}

set header_list [glob -nocomplain rtl/sources_1/new/headers/*.vh]
foreach header_file $header_list {
  set_property is_global_include true [get_files $header_file]
  set_property file_type {Verilog Header} [get_files $header_file]
}

current_run [get_runs impl_alter_def]
