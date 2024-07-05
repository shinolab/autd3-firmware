`define USE_BLOCK_RAM
//`define USE_DIST_RAM

`ifndef RAM
`ifdef USE_BLOCK_RAM
`ifdef USE_DIST_RAM
  $error();
`else
  `define RAM (*rom_style = "block"*)
`endif
`elsif USE_DIST_RAM
  `define RAM (*rom_style = "distributed"*)
`else
  `define RAM
`endif
`endif
