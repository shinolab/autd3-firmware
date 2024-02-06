package autd3;
  typedef struct {
    logic REQ_RD_SEGMENT;
    logic [14:0] CYCLE_0;
    logic [31:0] FREQ_DIV_0;
    logic [14:0] CYCLE_1;
    logic [31:0] FREQ_DIV_1;
    logic [31:0] REP;
  } mod_settings;
endpackage : autd3
