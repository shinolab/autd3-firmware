package settings;

  typedef struct {
    logic REQ_RD_SEGMENT;
    logic [14:0] CYCLE_0;
    logic [31:0] FREQ_DIV_0;
    logic [14:0] CYCLE_1;
    logic [31:0] FREQ_DIV_1;
    logic [31:0] REP;
  } mod_settings_t;

  typedef struct {
    logic MODE;
    logic REQ_RD_SEGMENT;
    logic [15:0] CYCLE_0;
    logic [31:0] FREQ_DIV_0;
    logic [15:0] CYCLE_1;
    logic [31:0] FREQ_DIV_1;
    logic [31:0] REP;
    logic [31:0] SOUND_SPEED;
  } stm_settings_t;

  typedef struct {
    logic        MODE;
    logic [15:0] UPDATE_RATE_INTENSITY;
    logic [15:0] UPDATE_RATE_PHASE;
    logic [15:0] COMPLETION_STEPS_INTENSITY;
    logic [15:0] COMPLETION_STEPS_PHASE;
  } silencer_settings_t;

  typedef struct {
    logic SET;
    logic [63:0] ECAT_SYNC_TIME;
  } sync_settings_t;

  typedef struct {logic [7:0] OUTPUT_IDX;} debug_settings_t;

endpackage
