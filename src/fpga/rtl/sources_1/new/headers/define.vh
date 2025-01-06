//`define USE_BLOCK_RAM
//`define USE_DIST_RAM

//`define DYNAMIC_FREQ

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

`define ASSERT_EQ(expected, actual) \
if (expected !== actual) begin \
  $error("%s:%d: expected is %s, but actual is %s", `__FILE__, `__LINE__, $sformatf("%0d", expected), $sformatf("%0d", actual));\
  $finish();\
end
