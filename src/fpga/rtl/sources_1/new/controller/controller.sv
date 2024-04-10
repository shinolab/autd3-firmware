`timescale 1ns / 1ps
module controller (
    input wire CLK,
    input wire THERMO,
    input wire STM_SEGMENT,
    input wire MOD_SEGMENT,
    input wire [15:0] STM_CYCLE,
    cnt_bus_if.out_port cnt_bus,
    output var settings::mod_settings_t MOD_SETTINGS,
    output var settings::stm_settings_t STM_SETTINGS,
    output var settings::silencer_settings_t SILENCER_SETTINGS,
    output var settings::sync_settings_t SYNC_SETTINGS,
    output var settings::pulse_width_encoder_settings_t PULSE_WIDTH_ENCODER_SETTINGS,
    output var settings::debug_settings_t DEBUG_SETTINGS,
    output var FORCE_FAN
);

  logic [15:0] ctl_flags;

  logic we;
  logic [7:0] addr;
  logic [15:0] din;
  logic [15:0] dout;

  assign cnt_bus.WE = we;
  assign cnt_bus.ADDR = addr;
  assign cnt_bus.DIN = din;
  assign dout = cnt_bus.DOUT;

  assign FORCE_FAN = ctl_flags[params::CtlFlagForceFanBit];

  typedef enum logic [6:0] {
    REQ_WR_VER_MINOR,
    REQ_WR_VER,
    WAIT_WR_VER_0_REQ_RD_CTL_FLAG,
    WR_VER_MINOR_WAIT_RD_CTL_FLAG_0,
    WR_VER_WAIT_RD_CTL_FLAG_1,
    WAIT_0,
    WAIT_1,
    REQ_MOD_REQ_RD_SEGMENT,
    REQ_MOD_CYCLE0,
    REQ_MOD_FREQ_DIV0_0,
    REQ_MOD_FREQ_DIV0_1_RD_MOD_REQ_RD_SEGMENT,
    REQ_MOD_CYCLE1_RD_MOD_CYCLE0,
    REQ_MOD_FREQ_DIV1_0_RD_MOD_FREQ_DIV0_0,
    REQ_MOD_FREQ_DIV1_1_RD_MOD_FREQ_DIV0_1,
    REQ_MOD_REP0_0_RD_MOD_CYCLE1,
    REQ_MOD_REP0_1_RD_MOD_FREQ_DIV1_0,
    REQ_MOD_REP1_0_RD_MOD_FREQ_DIV1_1,
    REQ_MOD_REP1_1_RD_MOD_REP0_0,
    RD_MOD_REP0_1,
    RD_MOD_REP1_0,
    RD_MOD_REP1_1,
    MOD_CLR_UPDATE_SETTINGS_BIT,
    REQ_STM_MODE0,
    REQ_STM_MODE1,
    REQ_STM_REQ_RD_SEGMENT,
    REQ_STM_CYCLE0_RD_STM_MODE0,
    REQ_STM_FREQ_DIV0_0_RD_STM_MODE1,
    REQ_STM_FREQ_DIV0_1_RD_STM_REQ_RD_SEGMENT,
    REQ_STM_CYCLE1_RD_STM_CYCLE0,
    REQ_STM_FREQ_DIV1_0_RD_STM_FREQ_DIV0_0,
    REQ_STM_FREQ_DIV1_1_RD_STM_FREQ_DIV0_1,
    REQ_STM_SOUND_SPEED0_0_RD_STM_CYCLE1,
    REQ_STM_SOUND_SPEED0_1_RD_STM_FREQ_DIV1_0,
    REQ_STM_SOUND_SPEED1_0_RD_STM_FREQ_DIV1_1,
    REQ_STM_SOUND_SPEED1_1_RD_STM_SOUND_SPEED0_0,
    REQ_STM_REP0_0_RD_STM_SOUND_SPEED0_1,
    REQ_STM_REP0_1_RD_STM_SOUND_SPEED1_0,
    REQ_STM_REP1_0_RD_STM_SOUND_SPEED1_1,
    REQ_STM_REP1_1_RD_STM_REP0_0,
    RD_STM_REP0_1,
    RD_STM_REP1_0,
    RD_STM_REP1_1,
    STM_CLR_UPDATE_SETTINGS_BIT,
    REQ_SILENCER_MODE,
    REQ_SILENCER_UPDATE_RATE_INTENSITY,
    REQ_SILENCER_UPDATE_RATE_PHASE,
    REQ_SILENCER_COMPLETION_STEPS_INTENSITY_RD_SILENCER_MODE,
    REQ_SILENCER_COMPLETION_STEPS_PHASE_RD_SILENCER_UPDATE_RATE_INTENSITY,
    RD_SILENCER_UPDATE_RATE_PHASE,
    RD_SILENCER_COMPLETION_STEPS_INTENSITY,
    RD_SILENCER_COMPLETION_STEPS_PHASE,
    SILENCER_CLR_UPDATE_SETTINGS_BIT,
    REQ_PULSE_WIDTH_ENCODER_FULL_WIDTH_START,
    REQ_PULSE_WIDTH_ENCODER_DUMMY0,
    REQ_PULSE_WIDTH_ENCODER_DUMMY1,
    RD_PULSE_WIDTH_ENCODER_FULL_WIDTH_START,
    PULSE_WIDTH_ENCODER_CLR_UPDATE_SETTINGS_BIT,
    REQ_DEBUG_TYPE0,
    REQ_DEBUG_VALUE0,
    REQ_DEBUG_TYPE1,
    REQ_DEBUG_VALUE1_RD_DEBUG_TYPE0,
    REQ_DEBUG_TYPE2_RD_DEBUG_VALUE0,
    REQ_DEBUG_VALUE2_RD_DEBUG_TYPE1,
    REQ_DEBUG_TYPE3_RD_DEBUG_VALUE1,
    REQ_DEBUG_VALUE3_RD_DEBUG_TYPE2,
    RD_DEBUG_VALUE2,
    RD_DEBUG_TYPE3,
    RD_DEBUG_VALUE3,
    DEBUG_CLR_UPDATE_SETTINGS_BIT,
    REQ_ECAT_SYNC_TIME_0,
    REQ_ECAT_SYNC_TIME_1,
    REQ_ECAT_SYNC_TIME_2,
    REQ_ECAT_SYNC_TIME_3_RD_ECAT_SYNC_TIME_0,
    RD_ECAT_SYNC_TIME_1,
    RD_ECAT_SYNC_TIME_2,
    RD_ECAT_SYNC_TIME_3,
    SYNC_CLR_UPDATE_SETTINGS_BIT
  } state_t;

  state_t state = REQ_WR_VER_MINOR;

  always_ff @(posedge CLK) begin
    case (state)
      REQ_WR_VER_MINOR: begin
        we <= 1'b1;

        din <= {8'd0, params::VersionNumMinor};
        addr <= params::AddrVersionNumMinor;

        state <= REQ_WR_VER;
      end
      REQ_WR_VER: begin
        din   <= {8'h00, params::VersionNumMajor};
        addr  <= params::AddrVersionNumMajor;

        state <= WAIT_WR_VER_0_REQ_RD_CTL_FLAG;
      end
      WAIT_WR_VER_0_REQ_RD_CTL_FLAG: begin
        we <= 1'b0;
        addr <= params::AddrCtlFlag;

        state <= WR_VER_MINOR_WAIT_RD_CTL_FLAG_0;
      end
      WR_VER_MINOR_WAIT_RD_CTL_FLAG_0: begin
        state <= WR_VER_WAIT_RD_CTL_FLAG_1;
      end
      WR_VER_WAIT_RD_CTL_FLAG_1: begin
        state <= WAIT_0;
      end

      WAIT_0: begin
        we <= 1'b1;
        addr <= params::AddrFPGAState;
        din <= {
          8'h00, 1'h0  /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO
        };

        if (ctl_flags[params::CtlFlagModSetBit]) begin
          ctl_flags <= ctl_flags & ~(1 << params::CtlFlagModSetBit);
          state <= REQ_MOD_REQ_RD_SEGMENT;
        end else if (ctl_flags[params::CtlFlagSTMSetBit]) begin
          ctl_flags <= ctl_flags & ~(1 << params::CtlFlagSTMSetBit);
          state <= REQ_STM_MODE0;
        end else if (ctl_flags[params::CtlFlagSilencerSetBit]) begin
          ctl_flags <= ctl_flags & ~(1 << params::CtlFlagSilencerSetBit);
          state <= REQ_SILENCER_MODE;
        end else if (ctl_flags[params::CtlFlagPulseWidthEncoderSetBit]) begin
          ctl_flags <= ctl_flags & ~(1 << params::CtlFlagPulseWidthEncoderSetBit);
          state <= REQ_PULSE_WIDTH_ENCODER_FULL_WIDTH_START;
        end else if (ctl_flags[params::CtlFlagDebugSetBit]) begin
          ctl_flags <= ctl_flags & ~(1 << params::CtlFlagDebugSetBit);
          state <= REQ_DEBUG_TYPE0;
        end else if (ctl_flags[params::CtlFlagSyncSetBit]) begin
          ctl_flags <= ctl_flags & ~(1 << params::CtlFlagSyncSetBit);
          state <= REQ_ECAT_SYNC_TIME_0;
        end else begin
          ctl_flags <= dout;
          state <= WAIT_1;
        end
      end
      WAIT_1: begin
        we <= 1'b0;
        addr <= params::AddrCtlFlag;
        state <= WAIT_0;
      end

      REQ_MOD_REQ_RD_SEGMENT: begin
        we <= 1'b0;
        addr <= params::AddrModReqRdSegment;
        state <= REQ_MOD_CYCLE0;
      end
      REQ_MOD_CYCLE0: begin
        addr  <= params::AddrModCycle0;
        state <= REQ_MOD_FREQ_DIV0_0;
      end
      REQ_MOD_FREQ_DIV0_0: begin
        addr  <= params::AddrModFreqDiv0_0;
        state <= REQ_MOD_FREQ_DIV0_1_RD_MOD_REQ_RD_SEGMENT;
      end
      REQ_MOD_FREQ_DIV0_1_RD_MOD_REQ_RD_SEGMENT: begin
        addr <= params::AddrModFreqDiv0_1;
        MOD_SETTINGS.REQ_RD_SEGMENT <= dout[0];
        state <= REQ_MOD_CYCLE1_RD_MOD_CYCLE0;
      end
      REQ_MOD_CYCLE1_RD_MOD_CYCLE0: begin
        addr <= params::AddrModCycle1;
        MOD_SETTINGS.CYCLE_0 <= dout[14:0];
        state <= REQ_MOD_FREQ_DIV1_0_RD_MOD_FREQ_DIV0_0;
      end
      REQ_MOD_FREQ_DIV1_0_RD_MOD_FREQ_DIV0_0: begin
        addr <= params::AddrModFreqDiv1_0;
        MOD_SETTINGS.FREQ_DIV_0[15:0] <= dout;
        state <= REQ_MOD_FREQ_DIV1_1_RD_MOD_FREQ_DIV0_1;
      end
      REQ_MOD_FREQ_DIV1_1_RD_MOD_FREQ_DIV0_1: begin
        addr <= params::AddrModFreqDiv1_1;
        MOD_SETTINGS.FREQ_DIV_0[31:16] <= dout;
        state <= REQ_MOD_REP0_0_RD_MOD_CYCLE1;
      end
      REQ_MOD_REP0_0_RD_MOD_CYCLE1: begin
        addr <= params::AddrModRep0_0;
        MOD_SETTINGS.CYCLE_1 <= dout[14:0];
        state <= REQ_MOD_REP0_1_RD_MOD_FREQ_DIV1_0;
      end
      REQ_MOD_REP0_1_RD_MOD_FREQ_DIV1_0: begin
        addr <= params::AddrModRep0_1;
        MOD_SETTINGS.FREQ_DIV_1[15:0] <= dout;
        state <= REQ_MOD_REP1_0_RD_MOD_FREQ_DIV1_1;
      end
      REQ_MOD_REP1_0_RD_MOD_FREQ_DIV1_1: begin
        addr <= params::AddrModRep1_0;
        MOD_SETTINGS.FREQ_DIV_1[31:16] <= dout;
        state <= REQ_MOD_REP1_1_RD_MOD_REP0_0;
      end
      REQ_MOD_REP1_1_RD_MOD_REP0_0: begin
        addr <= params::AddrModRep1_1;
        MOD_SETTINGS.REP_0[15:0] <= dout;
        state <= RD_MOD_REP0_1;
      end
      RD_MOD_REP0_1: begin
        MOD_SETTINGS.REP_0[31:16] <= dout;
        we <= 1'b1;
        addr <= params::AddrCtlFlag;
        din <= ctl_flags;
        state <= RD_MOD_REP1_0;
      end
      RD_MOD_REP1_0: begin
        MOD_SETTINGS.REP_1[15:0] <= dout;
        we <= 1'b1;
        addr <= params::AddrFPGAState;
        din <= {
          8'h00, 1'h0  /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO
        };
        state <= RD_MOD_REP1_1;
      end
      RD_MOD_REP1_1: begin
        MOD_SETTINGS.REP_1[31:16] <= dout;
        MOD_SETTINGS.UPDATE <= 1'b1;
        we <= 1'b0;
        addr <= params::AddrCtlFlag;
        state <= MOD_CLR_UPDATE_SETTINGS_BIT;
      end
      MOD_CLR_UPDATE_SETTINGS_BIT: begin
        we <= 1'b1;
        addr <= params::AddrFPGAState;
        din <= {
          8'h00, 1'h0  /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO
        };
        ctl_flags <= dout;
        MOD_SETTINGS.UPDATE <= 1'b0;
        state <= WAIT_1;
      end

      REQ_STM_MODE0: begin
        we <= 1'b0;
        addr <= params::AddrSTMMode0;
        state <= REQ_STM_MODE1;
      end
      REQ_STM_MODE1: begin
        addr  <= params::AddrSTMMode1;
        state <= REQ_STM_REQ_RD_SEGMENT;
      end
      REQ_STM_REQ_RD_SEGMENT: begin
        addr  <= params::AddrSTMReqRdSegment;
        state <= REQ_STM_CYCLE0_RD_STM_MODE0;
      end
      REQ_STM_CYCLE0_RD_STM_MODE0: begin
        addr <= params::AddrSTMCycle0;
        STM_SETTINGS.MODE_0 <= dout[0];
        state <= REQ_STM_FREQ_DIV0_0_RD_STM_MODE1;
      end
      REQ_STM_FREQ_DIV0_0_RD_STM_MODE1: begin
        addr <= params::AddrSTMFreqDiv0_0;
        STM_SETTINGS.MODE_1 <= dout[0];
        state <= REQ_STM_FREQ_DIV0_1_RD_STM_REQ_RD_SEGMENT;
      end
      REQ_STM_FREQ_DIV0_1_RD_STM_REQ_RD_SEGMENT: begin
        addr <= params::AddrSTMFreqDiv0_1;
        STM_SETTINGS.REQ_RD_SEGMENT <= dout[0];
        state <= REQ_STM_CYCLE1_RD_STM_CYCLE0;
      end
      REQ_STM_CYCLE1_RD_STM_CYCLE0: begin
        addr <= params::AddrSTMCycle1;
        STM_SETTINGS.CYCLE_0 <= dout;
        state <= REQ_STM_FREQ_DIV1_0_RD_STM_FREQ_DIV0_0;
      end
      REQ_STM_FREQ_DIV1_0_RD_STM_FREQ_DIV0_0: begin
        addr <= params::AddrSTMFreqDiv1_0;
        STM_SETTINGS.FREQ_DIV_0[15:0] <= dout;
        state <= REQ_STM_FREQ_DIV1_1_RD_STM_FREQ_DIV0_1;
      end
      REQ_STM_FREQ_DIV1_1_RD_STM_FREQ_DIV0_1: begin
        addr <= params::AddrSTMFreqDiv1_1;
        STM_SETTINGS.FREQ_DIV_0[31:16] <= dout;
        state <= REQ_STM_SOUND_SPEED0_0_RD_STM_CYCLE1;
      end
      REQ_STM_SOUND_SPEED0_0_RD_STM_CYCLE1: begin
        addr <= params::AddrSTMSoundSpeed0_0;
        STM_SETTINGS.CYCLE_1 <= dout;
        state <= REQ_STM_SOUND_SPEED0_1_RD_STM_FREQ_DIV1_0;
      end
      REQ_STM_SOUND_SPEED0_1_RD_STM_FREQ_DIV1_0: begin
        addr <= params::AddrSTMSoundSpeed0_1;
        STM_SETTINGS.FREQ_DIV_1[15:0] <= dout;
        state <= REQ_STM_SOUND_SPEED1_0_RD_STM_FREQ_DIV1_1;
      end
      REQ_STM_SOUND_SPEED1_0_RD_STM_FREQ_DIV1_1: begin
        addr <= params::AddrSTMSoundSpeed1_0;
        STM_SETTINGS.FREQ_DIV_1[31:16] <= dout;
        state <= REQ_STM_SOUND_SPEED1_1_RD_STM_SOUND_SPEED0_0;
      end
      REQ_STM_SOUND_SPEED1_1_RD_STM_SOUND_SPEED0_0: begin
        addr <= params::AddrSTMSoundSpeed1_1;
        STM_SETTINGS.SOUND_SPEED_0[15:0] <= dout;
        state <= REQ_STM_REP0_0_RD_STM_SOUND_SPEED0_1;
      end
      REQ_STM_REP0_0_RD_STM_SOUND_SPEED0_1: begin
        addr <= params::AddrSTMRep0_0;
        STM_SETTINGS.SOUND_SPEED_0[31:16] <= dout;
        state <= REQ_STM_REP0_1_RD_STM_SOUND_SPEED1_0;
      end
      REQ_STM_REP0_1_RD_STM_SOUND_SPEED1_0: begin
        addr <= params::AddrSTMRep0_1;
        STM_SETTINGS.SOUND_SPEED_1[15:0] <= dout;
        state <= REQ_STM_REP1_0_RD_STM_SOUND_SPEED1_1;
      end
      REQ_STM_REP1_0_RD_STM_SOUND_SPEED1_1: begin
        addr <= params::AddrSTMRep1_0;
        STM_SETTINGS.SOUND_SPEED_1[31:16] <= dout;
        state <= REQ_STM_REP1_1_RD_STM_REP0_0;
      end
      REQ_STM_REP1_1_RD_STM_REP0_0: begin
        addr <= params::AddrSTMRep1_1;
        STM_SETTINGS.REP_0[15:0] <= dout;
        state <= RD_STM_REP0_1;
      end
      RD_STM_REP0_1: begin
        STM_SETTINGS.REP_0[31:16] <= dout;
        we <= 1'b1;
        addr <= params::AddrCtlFlag;
        din <= ctl_flags;
        state <= RD_STM_REP1_0;
      end
      RD_STM_REP1_0: begin
        STM_SETTINGS.REP_1[15:0] <= dout;
        we <= 1'b1;
        addr <= params::AddrFPGAState;
        din <= {
          8'h00, 1'h0  /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO
        };
        state <= RD_STM_REP1_1;
      end
      RD_STM_REP1_1: begin
        STM_SETTINGS.REP_1[31:16] <= dout;
        STM_SETTINGS.UPDATE <= 1'b1;
        we <= 1'b0;
        addr <= params::AddrCtlFlag;
        state <= STM_CLR_UPDATE_SETTINGS_BIT;
      end
      STM_CLR_UPDATE_SETTINGS_BIT: begin
        we <= 1'b1;
        addr <= params::AddrFPGAState;
        din <= {
          8'h00, 1'h0  /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO
        };
        ctl_flags <= dout;
        STM_SETTINGS.UPDATE <= 1'b0;
        state <= WAIT_1;
      end

      REQ_SILENCER_MODE: begin
        we <= 1'b0;
        addr <= params::AddrSilencerMode;
        state <= REQ_SILENCER_UPDATE_RATE_INTENSITY;
      end
      REQ_SILENCER_UPDATE_RATE_INTENSITY: begin
        addr  <= params::AddrSilencerUpdateRateIntensity;
        state <= REQ_SILENCER_UPDATE_RATE_PHASE;
      end
      REQ_SILENCER_UPDATE_RATE_PHASE: begin
        addr  <= params::AddrSilencerUpdateRatePhase;
        state <= REQ_SILENCER_COMPLETION_STEPS_INTENSITY_RD_SILENCER_MODE;
      end
      REQ_SILENCER_COMPLETION_STEPS_INTENSITY_RD_SILENCER_MODE: begin
        addr <= params::AddrSilencerCompletionStepsIntensity;
        SILENCER_SETTINGS.MODE <= dout[0];
        state <= REQ_SILENCER_COMPLETION_STEPS_PHASE_RD_SILENCER_UPDATE_RATE_INTENSITY;
      end
      REQ_SILENCER_COMPLETION_STEPS_PHASE_RD_SILENCER_UPDATE_RATE_INTENSITY: begin
        addr <= params::AddrSilencerCompletionStepsPhase;
        SILENCER_SETTINGS.UPDATE_RATE_INTENSITY <= dout;
        state <= RD_SILENCER_UPDATE_RATE_PHASE;
      end
      RD_SILENCER_UPDATE_RATE_PHASE: begin
        SILENCER_SETTINGS.UPDATE_RATE_PHASE <= dout;
        we <= 1'b1;
        addr <= params::AddrCtlFlag;
        din <= ctl_flags;
        state <= RD_SILENCER_COMPLETION_STEPS_INTENSITY;
      end
      RD_SILENCER_COMPLETION_STEPS_INTENSITY: begin
        SILENCER_SETTINGS.COMPLETION_STEPS_INTENSITY <= dout;
        we <= 1'b1;
        addr <= params::AddrFPGAState;
        din <= {
          8'h00, 1'h0  /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO
        };
        state <= RD_SILENCER_COMPLETION_STEPS_PHASE;
      end
      RD_SILENCER_COMPLETION_STEPS_PHASE: begin
        SILENCER_SETTINGS.COMPLETION_STEPS_PHASE <= dout;
        SILENCER_SETTINGS.UPDATE <= 1'b1;
        we <= 1'b0;
        addr <= params::AddrCtlFlag;
        state <= SILENCER_CLR_UPDATE_SETTINGS_BIT;
      end
      SILENCER_CLR_UPDATE_SETTINGS_BIT: begin
        we <= 1'b1;
        addr <= params::AddrFPGAState;
        din <= {
          8'h00, 1'h0  /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO
        };
        ctl_flags <= dout;
        SILENCER_SETTINGS.UPDATE <= 1'b0;
        state <= WAIT_1;
      end

      REQ_PULSE_WIDTH_ENCODER_FULL_WIDTH_START: begin
        we <= 1'b0;
        addr <= params::AddrPulseWidthEncoderFullWidthStart;
        state <= REQ_PULSE_WIDTH_ENCODER_DUMMY0;
      end
      REQ_PULSE_WIDTH_ENCODER_DUMMY0: begin
        we <= 1'b1;
        addr <= params::AddrCtlFlag;
        din <= ctl_flags;
        state <= REQ_PULSE_WIDTH_ENCODER_DUMMY1;
      end
      REQ_PULSE_WIDTH_ENCODER_DUMMY1: begin
        we <= 1'b1;
        addr <= params::AddrFPGAState;
        din <= {
          8'h00, 1'h0  /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO
        };
        state <= RD_PULSE_WIDTH_ENCODER_FULL_WIDTH_START;
      end
      RD_PULSE_WIDTH_ENCODER_FULL_WIDTH_START: begin
        PULSE_WIDTH_ENCODER_SETTINGS.FULL_WIDTH_START <= dout;
        PULSE_WIDTH_ENCODER_SETTINGS.UPDATE <= 1'b1;
        we <= 1'b0;
        addr <= params::AddrCtlFlag;
        state <= PULSE_WIDTH_ENCODER_CLR_UPDATE_SETTINGS_BIT;
      end
      PULSE_WIDTH_ENCODER_CLR_UPDATE_SETTINGS_BIT: begin
        we <= 1'b1;
        addr <= params::AddrFPGAState;
        din <= {
          8'h00, 1'h0  /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO
        };
        ctl_flags <= dout;
        PULSE_WIDTH_ENCODER_SETTINGS.UPDATE <= 1'b0;
        state <= WAIT_1;
      end

      REQ_DEBUG_TYPE0: begin
        we <= 1'b0;
        addr <= params::AddrDebugType0;
        state <= REQ_DEBUG_VALUE0;
      end
      REQ_DEBUG_VALUE0: begin
        addr  <= params::AddrDebugValue0;
        state <= REQ_DEBUG_TYPE1;
      end
      REQ_DEBUG_TYPE1: begin
        addr  <= params::AddrDebugType1;
        state <= REQ_DEBUG_VALUE1_RD_DEBUG_TYPE0;
      end
      REQ_DEBUG_VALUE1_RD_DEBUG_TYPE0: begin
        addr <= params::AddrDebugValue1;
        DEBUG_SETTINGS.TYPE[0] <= dout[7:0];
        state <= REQ_DEBUG_TYPE2_RD_DEBUG_VALUE0;
      end
      REQ_DEBUG_TYPE2_RD_DEBUG_VALUE0: begin
        addr <= params::AddrDebugType2;
        DEBUG_SETTINGS.VALUE[0] <= dout;
        state <= REQ_DEBUG_VALUE2_RD_DEBUG_TYPE1;
      end
      REQ_DEBUG_VALUE2_RD_DEBUG_TYPE1: begin
        addr <= params::AddrDebugValue2;
        DEBUG_SETTINGS.TYPE[1] <= dout[7:0];
        state <= REQ_DEBUG_TYPE3_RD_DEBUG_VALUE1;
      end
      REQ_DEBUG_TYPE3_RD_DEBUG_VALUE1: begin
        addr <= params::AddrDebugType3;
        DEBUG_SETTINGS.VALUE[1] <= dout;
        state <= REQ_DEBUG_VALUE3_RD_DEBUG_TYPE2;
      end
      REQ_DEBUG_VALUE3_RD_DEBUG_TYPE2: begin
        addr <= params::AddrDebugValue3;
        DEBUG_SETTINGS.TYPE[2] <= dout[7:0];
        state <= RD_DEBUG_VALUE2;
      end
      RD_DEBUG_VALUE2: begin
        DEBUG_SETTINGS.VALUE[2] <= dout;
        we <= 1'b1;
        addr <= params::AddrCtlFlag;
        din <= ctl_flags;
        state <= RD_DEBUG_TYPE3;
      end
      RD_DEBUG_TYPE3: begin
        DEBUG_SETTINGS.TYPE[3] <= dout[7:0];
        we <= 1'b1;
        addr <= params::AddrFPGAState;
        din <= {
          8'h00, 1'h0  /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO
        };
        state <= RD_DEBUG_VALUE3;
      end
      RD_DEBUG_VALUE3: begin
        DEBUG_SETTINGS.VALUE[3] <= dout;
        DEBUG_SETTINGS.UPDATE <= 1'b1;
        we <= 1'b0;
        addr <= params::AddrCtlFlag;
        state <= DEBUG_CLR_UPDATE_SETTINGS_BIT;
      end
      DEBUG_CLR_UPDATE_SETTINGS_BIT: begin
        we <= 1'b1;
        addr <= params::AddrFPGAState;
        din <= {
          8'h00, 1'h0  /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO
        };
        ctl_flags <= dout;
        DEBUG_SETTINGS.UPDATE <= 1'b0;
        state <= WAIT_1;
      end

      REQ_ECAT_SYNC_TIME_0: begin
        we <= 1'b0;
        addr <= params::AddrECATSyncTime_0;
        state <= REQ_ECAT_SYNC_TIME_1;
      end
      REQ_ECAT_SYNC_TIME_1: begin
        addr  <= params::AddrECATSyncTime_1;
        state <= REQ_ECAT_SYNC_TIME_2;
      end
      REQ_ECAT_SYNC_TIME_2: begin
        addr  <= params::AddrECATSyncTime_2;
        state <= REQ_ECAT_SYNC_TIME_3_RD_ECAT_SYNC_TIME_0;
      end
      REQ_ECAT_SYNC_TIME_3_RD_ECAT_SYNC_TIME_0: begin
        addr <= params::AddrECATSyncTime_3;
        SYNC_SETTINGS.ECAT_SYNC_TIME[15:0] <= dout;
        state <= RD_ECAT_SYNC_TIME_1;
      end
      RD_ECAT_SYNC_TIME_1: begin
        SYNC_SETTINGS.ECAT_SYNC_TIME[31:16] <= dout;
        we <= 1'b1;
        addr <= params::AddrCtlFlag;
        din <= ctl_flags;
        state <= RD_ECAT_SYNC_TIME_2;
      end
      RD_ECAT_SYNC_TIME_2: begin
        SYNC_SETTINGS.ECAT_SYNC_TIME[47:32] <= dout;
        we <= 1'b1;
        addr <= params::AddrFPGAState;
        din <= {
          8'h00, 1'h0  /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO
        };
        state <= RD_ECAT_SYNC_TIME_3;
      end
      RD_ECAT_SYNC_TIME_3: begin
        SYNC_SETTINGS.ECAT_SYNC_TIME[63:48] <= dout;
        SYNC_SETTINGS.UPDATE <= 1'b1;
        we <= 1'b0;
        addr <= params::AddrCtlFlag;
        state <= SYNC_CLR_UPDATE_SETTINGS_BIT;
      end
      SYNC_CLR_UPDATE_SETTINGS_BIT: begin
        we <= 1'b1;
        addr <= params::AddrFPGAState;
        din <= {
          8'h00, 1'h0  /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO
        };
        ctl_flags <= dout;
        SYNC_SETTINGS.UPDATE <= 1'b0;
        state <= WAIT_1;
      end

      default: state <= WAIT_0;
    endcase
  end

  initial begin
    MOD_SETTINGS.UPDATE = 1'b0;
    MOD_SETTINGS.REQ_RD_SEGMENT = 1'd0;
    MOD_SETTINGS.CYCLE_0 = 15'd1;
    MOD_SETTINGS.FREQ_DIV_0 = 32'd5120;
    MOD_SETTINGS.CYCLE_1 = 15'd1;
    MOD_SETTINGS.FREQ_DIV_1 = 32'd5120;
    MOD_SETTINGS.REP_0 = 32'hFFFFFFFF;
    MOD_SETTINGS.REP_1 = 32'hFFFFFFFF;
    STM_SETTINGS.UPDATE = 1'b0;
    STM_SETTINGS.MODE_0 = params::STMModeGain;
    STM_SETTINGS.MODE_1 = params::STMModeGain;
    STM_SETTINGS.REQ_RD_SEGMENT = 1'd0;
    STM_SETTINGS.CYCLE_0 = 16'd0;
    STM_SETTINGS.FREQ_DIV_0 = 32'hFFFFFFFF;
    STM_SETTINGS.CYCLE_1 = 16'd0;
    STM_SETTINGS.FREQ_DIV_1 = 32'hFFFFFFFF;
    STM_SETTINGS.SOUND_SPEED_0 = 32'd0;
    STM_SETTINGS.SOUND_SPEED_1 = 32'd0;
    STM_SETTINGS.REP_0 = 32'hFFFFFFFF;
    STM_SETTINGS.REP_1 = 32'hFFFFFFFF;
    SILENCER_SETTINGS.UPDATE = 1'b0;
    SILENCER_SETTINGS.MODE = params::SilencerModeFixedCompletionSteps;
    SILENCER_SETTINGS.UPDATE_RATE_INTENSITY = 16'd256;
    SILENCER_SETTINGS.UPDATE_RATE_PHASE = 16'd256;
    SILENCER_SETTINGS.COMPLETION_STEPS_INTENSITY = 16'd10;
    SILENCER_SETTINGS.COMPLETION_STEPS_PHASE = 16'd40;
    PULSE_WIDTH_ENCODER_SETTINGS.UPDATE = 1'b0;
    PULSE_WIDTH_ENCODER_SETTINGS.FULL_WIDTH_START = 16'd65025;
    DEBUG_SETTINGS.UPDATE = 1'b0;
    DEBUG_SETTINGS.TYPE[0] = params::DBG_NONE;
    DEBUG_SETTINGS.VALUE[0] = 16'd0;
    DEBUG_SETTINGS.TYPE[1] = params::DBG_NONE;
    DEBUG_SETTINGS.VALUE[1] = 16'd0;
    DEBUG_SETTINGS.TYPE[2] = params::DBG_NONE;
    DEBUG_SETTINGS.VALUE[2] = 16'd0;
    DEBUG_SETTINGS.TYPE[3] = params::DBG_NONE;
    DEBUG_SETTINGS.VALUE[3] = 16'd0;
    SYNC_SETTINGS.UPDATE = 1'b0;
    SYNC_SETTINGS.ECAT_SYNC_TIME = 64'd0;
  end

endmodule
