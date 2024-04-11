package settings;

  typedef struct {
    logic UPDATE;
    logic REQ_RD_SEGMENT;
    logic [7:0] TRANSITION_MODE;
    logic [63:0] TRANSITION_TIME;
    logic [14:0] CYCLE[2];
    logic [31:0] FREQ_DIV[2];
    logic [31:0] REP[2];
  } mod_settings_t;

  typedef struct {
    logic UPDATE;
    logic REQ_RD_SEGMENT;
    logic [7:0] TRANSITION_MODE;
    logic [63:0] TRANSITION_TIME;
    logic MODE[2];
    logic [15:0] CYCLE[2];
    logic [31:0] FREQ_DIV[2];
    logic [31:0] REP[2];
    logic [31:0] SOUND_SPEED[2];
  } stm_settings_t;

  typedef struct {
    logic        UPDATE;
    logic        MODE;
    logic [15:0] UPDATE_RATE_INTENSITY;
    logic [15:0] UPDATE_RATE_PHASE;
    logic [15:0] COMPLETION_STEPS_INTENSITY;
    logic [15:0] COMPLETION_STEPS_PHASE;
  } silencer_settings_t;

  typedef struct {
    logic UPDATE;
    logic [63:0] ECAT_SYNC_TIME;
  } sync_settings_t;

  typedef struct {
    logic UPDATE;
    logic [15:0] FULL_WIDTH_START;
  } pulse_width_encoder_settings_t;

  typedef struct {
    logic UPDATE;
    logic [7:0] TYPE[4];
    logic [15:0] VALUE[4];
  } debug_settings_t;

endpackage
