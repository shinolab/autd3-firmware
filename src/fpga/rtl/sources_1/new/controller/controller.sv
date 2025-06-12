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
    output var settings::debug_settings_t DEBUG_SETTINGS,
    output var FORCE_FAN,
    output var GPIO_IN[4]
);

  localparam bit [7:0] FunctionBits = (1'b0 << params::FuncDynamicFreqBit) | (1'b0 << params::FuncEmulatorBit);

  logic [15:0] ctl_flags;

  logic we;
  logic [7:0] addr;
  logic [15:0] din;
  logic [15:0] dout;

  assign cnt_bus.WE = we;
  assign cnt_bus.ADDR = addr;
  assign cnt_bus.DIN = din;
  assign dout = cnt_bus.DOUT;

  assign FORCE_FAN = ctl_flags[params::CTL_FLAG_BIT_FORCE_FAN];
  assign GPIO_IN[0] = ctl_flags[params::CTL_FLAG_BIT_GPIO_IN_0];
  assign GPIO_IN[1] = ctl_flags[params::CTL_FLAG_BIT_GPIO_IN_1];
  assign GPIO_IN[2] = ctl_flags[params::CTL_FLAG_BIT_GPIO_IN_2];
  assign GPIO_IN[3] = ctl_flags[params::CTL_FLAG_BIT_GPIO_IN_3];

  typedef enum logic [6:0] {
    REQ_WR_VER_MINOR,
    REQ_WR_VER,
    WAIT_WR_VER_0_REQ_RD_CTL_FLAG,
    WR_VER_MINOR_WAIT_RD_CTL_FLAG_BIT_0,
    WR_VER_WAIT_RD_CTL_FLAG_BIT_1,
    WAIT_0,
    WAIT_1,
    REQ_MOD_REQ_RD_SEGMENT,
    REQ_MOD_TRANSITION_MODE,
    REQ_MOD_TRANSITION_VALUE_0,
    REQ_MOD_TRANSITION_VALUE_1_RD_MOD_REQ_RD_SEGMENT,
    REQ_MOD_TRANSITION_VALUE_2_RD_MOD_TRANSITION_MODE,
    REQ_MOD_TRANSITION_VALUE_3_RD_MOD_TRANSITION_VALUE_0,
    REQ_MOD_CYCLE0_RD_MOD_TRANSITION_VALUE_1,
    REQ_MOD_CYCLE1_RD_MOD_TRANSITION_VALUE_2,
    REQ_MOD_FREQ_DIV0_RD_MOD_TRANSITION_VALUE_3,
    REQ_MOD_FREQ_DIV1_RD_MOD_CYCLE0,
    REQ_MOD_REP0_RD_MOD_CYCLE1,
    REQ_MOD_REP1_RD_MOD_FREQ_DIV0,
    RD_MOD_FREQ_DIV1,
    RD_MOD_REP0,
    RD_MOD_REP1,
    MOD_CLR_UPDATE_SETTINGS_BIT,
    REQ_STM_REQ_RD_SEGMENT,
    REQ_STM_TRANSITION_MODE,
    REQ_STM_TRANSITION_VALUE_0,
    REQ_STM_TRANSITION_VALUE_1_RD_STM_REQ_RD_SEGMENT,
    REQ_STM_TRANSITION_VALUE_2_RD_STM_TRANSITION_MODE,
    REQ_STM_TRANSITION_VALUE_3_RD_STM_TRANSITION_VALUE_0,
    REQ_STM_MODE0_RD_STM_TRANSITION_VALUE_1,
    REQ_STM_MODE1_RD_STM_TRANSITION_VALUE_2,
    REQ_STM_CYCLE0_RD_STM_TRANSITION_VALUE_3,
    REQ_STM_CYCLE1_RD_STM_MODE0,
    REQ_STM_FREQ_DIV0_RD_STM_MODE1,
    REQ_STM_FREQ_DIV1_RD_STM_CYCLE0,
    REQ_STM_SOUND_SPEED0_RD_STM_CYCLE1,
    REQ_STM_SOUND_SPEED1_RD_STM_FREQ_DIV0,
    REQ_STM_REP0_RD_STM_FREQ_DIV1,
    REQ_STM_REP1_RD_STM_SOUND_SPEED0,
    REQ_STM_NUM_FOCI0_RD_STM_SOUND_SPEED1,
    REQ_STM_NUM_FOCI1_RD_STM_REP0,
    RD_STM_REP1,
    RD_STM_NUM_FOCI0,
    RD_STM_NUM_FOCI1,
    STM_CLR_UPDATE_SETTINGS_BIT,
    REQ_SILENCER_FLAG,
    REQ_SILENCER_UPDATE_RATE_INTENSITY,
    REQ_SILENCER_UPDATE_RATE_PHASE,
    REQ_SILENCER_COMPLETION_STEPS_INTENSITY_RD_SILENCER_FLAG,
    REQ_SILENCER_COMPLETION_STEPS_PHASE_RD_SILENCER_UPDATE_RATE_INTENSITY,
    RD_SILENCER_UPDATE_RATE_PHASE,
    RD_SILENCER_COMPLETION_STEPS_INTENSITY,
    RD_SILENCER_COMPLETION_STEPS_PHASE,
    SILENCER_CLR_UPDATE_SETTINGS_BIT,
    REQ_DEBUG_VALUE0_0,
    REQ_DEBUG_VALUE0_1,
    REQ_DEBUG_VALUE0_2,
    REQ_DEBUG_VALUE0_3_RD_DEBUG_VALUE0_0,
    REQ_DEBUG_VALUE1_0_RD_DEBUG_VALUE0_1,
    REQ_DEBUG_VALUE1_1_RD_DEBUG_VALUE0_2,
    REQ_DEBUG_VALUE1_2_RD_DEBUG_VALUE0_3,
    REQ_DEBUG_VALUE1_3_RD_DEBUG_VALUE1_0,
    REQ_DEBUG_VALUE2_0_RD_DEBUG_VALUE1_1,
    REQ_DEBUG_VALUE2_1_RD_DEBUG_VALUE1_2,
    REQ_DEBUG_VALUE2_2_RD_DEBUG_VALUE1_3,
    REQ_DEBUG_VALUE2_3_RD_DEBUG_VALUE2_0,
    REQ_DEBUG_VALUE3_0_RD_DEBUG_VALUE2_1,
    REQ_DEBUG_VALUE3_1_RD_DEBUG_VALUE2_2,
    REQ_DEBUG_VALUE3_2_RD_DEBUG_VALUE2_3,
    REQ_DEBUG_VALUE3_3_RD_DEBUG_VALUE3_0,
    RD_DEBUG_VALUE3_1,
    RD_DEBUG_VALUE3_2,
    RD_DEBUG_VALUE3_3,
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
        addr <= params::ADDR_VERSION_NUM_MINOR;

        state <= REQ_WR_VER;
      end
      REQ_WR_VER: begin
        din   <= {FunctionBits, params::VersionNumMajor};
        addr  <= params::ADDR_VERSION_NUM_MAJOR;

        state <= WAIT_WR_VER_0_REQ_RD_CTL_FLAG;
      end
      WAIT_WR_VER_0_REQ_RD_CTL_FLAG: begin
        we <= 1'b0;
        addr <= params::ADDR_CTL_FLAG;

        state <= WR_VER_MINOR_WAIT_RD_CTL_FLAG_BIT_0;
      end
      WR_VER_MINOR_WAIT_RD_CTL_FLAG_BIT_0: begin
        state <= WR_VER_WAIT_RD_CTL_FLAG_BIT_1;
      end
      WR_VER_WAIT_RD_CTL_FLAG_BIT_1: begin
        state <= WAIT_0;
      end

      WAIT_0: begin
        we   <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din  <= {8'h00, 1'h0  /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO};

        if (ctl_flags[params::CTL_FLAG_BIT_MOD_SET]) begin
          ctl_flags <= ctl_flags & ~(1 << params::CTL_FLAG_BIT_MOD_SET);
          state <= REQ_MOD_REQ_RD_SEGMENT;
        end else if (ctl_flags[params::CTL_FLAG_BIT_STM_SET]) begin
          ctl_flags <= ctl_flags & ~(1 << params::CTL_FLAG_BIT_STM_SET);
          state <= REQ_STM_REQ_RD_SEGMENT;
        end else if (ctl_flags[params::CTL_FLAG_BIT_SILENCER_SET]) begin
          ctl_flags <= ctl_flags & ~(1 << params::CTL_FLAG_BIT_SILENCER_SET);
          state <= REQ_SILENCER_FLAG;
        end else if (ctl_flags[params::CTL_FLAG_BIT_DEBUG_SET]) begin
          ctl_flags <= ctl_flags & ~(1 << params::CTL_FLAG_BIT_DEBUG_SET);
          state <= REQ_DEBUG_VALUE0_0;
        end else if (ctl_flags[params::CTL_FLAG_BIT_SYNC_SET]) begin
          ctl_flags <= ctl_flags & ~(1 << params::CTL_FLAG_BIT_SYNC_SET);
          state <= REQ_ECAT_SYNC_TIME_0;
        end else begin
          ctl_flags <= dout;
          state <= WAIT_1;
        end
      end
      WAIT_1: begin
        we <= 1'b0;
        addr <= params::ADDR_CTL_FLAG;
        state <= WAIT_0;
      end

      REQ_MOD_REQ_RD_SEGMENT: begin
        we <= 1'b0;
        addr <= params::ADDR_MOD_REQ_RD_SEGMENT;
        state <= REQ_MOD_TRANSITION_MODE;
      end
      REQ_MOD_TRANSITION_MODE: begin
        addr  <= params::ADDR_MOD_TRANSITION_MODE;
        state <= REQ_MOD_TRANSITION_VALUE_0;
      end
      REQ_MOD_TRANSITION_VALUE_0: begin
        addr  <= params::ADDR_MOD_TRANSITION_VALUE_0;
        state <= REQ_MOD_TRANSITION_VALUE_1_RD_MOD_REQ_RD_SEGMENT;
      end
      REQ_MOD_TRANSITION_VALUE_1_RD_MOD_REQ_RD_SEGMENT: begin
        addr <= params::ADDR_MOD_TRANSITION_VALUE_1;
        MOD_SETTINGS.REQ_RD_SEGMENT <= dout[0];
        state <= REQ_MOD_TRANSITION_VALUE_2_RD_MOD_TRANSITION_MODE;
      end
      REQ_MOD_TRANSITION_VALUE_2_RD_MOD_TRANSITION_MODE: begin
        addr <= params::ADDR_MOD_TRANSITION_VALUE_2;
        MOD_SETTINGS.TRANSITION_MODE <= dout[7:0];
        state <= REQ_MOD_TRANSITION_VALUE_3_RD_MOD_TRANSITION_VALUE_0;
      end
      REQ_MOD_TRANSITION_VALUE_3_RD_MOD_TRANSITION_VALUE_0: begin
        addr <= params::ADDR_MOD_TRANSITION_VALUE_3;
        MOD_SETTINGS.TRANSITION_VALUE[15:0] <= dout;
        state <= REQ_MOD_CYCLE0_RD_MOD_TRANSITION_VALUE_1;
      end
      REQ_MOD_CYCLE0_RD_MOD_TRANSITION_VALUE_1: begin
        addr <= params::ADDR_MOD_CYCLE0;
        MOD_SETTINGS.TRANSITION_VALUE[31:16] <= dout;
        state <= REQ_MOD_CYCLE1_RD_MOD_TRANSITION_VALUE_2;
      end
      REQ_MOD_CYCLE1_RD_MOD_TRANSITION_VALUE_2: begin
        addr <= params::ADDR_MOD_CYCLE1;
        MOD_SETTINGS.TRANSITION_VALUE[47:32] <= dout;
        state <= REQ_MOD_FREQ_DIV0_RD_MOD_TRANSITION_VALUE_3;
      end
      REQ_MOD_FREQ_DIV0_RD_MOD_TRANSITION_VALUE_3: begin
        addr <= params::ADDR_MOD_FREQ_DIV0;
        MOD_SETTINGS.TRANSITION_VALUE[63:48] <= dout;
        state <= REQ_MOD_FREQ_DIV1_RD_MOD_CYCLE0;
      end
      REQ_MOD_FREQ_DIV1_RD_MOD_CYCLE0: begin
        addr <= params::ADDR_MOD_FREQ_DIV1;
        MOD_SETTINGS.CYCLE[0] <= dout;
        state <= REQ_MOD_REP0_RD_MOD_CYCLE1;
      end
      REQ_MOD_REP0_RD_MOD_CYCLE1: begin
        addr <= params::ADDR_MOD_REP0;
        MOD_SETTINGS.CYCLE[1] <= dout;
        state <= REQ_MOD_REP1_RD_MOD_FREQ_DIV0;
      end
      REQ_MOD_REP1_RD_MOD_FREQ_DIV0: begin
        addr <= params::ADDR_MOD_REP1;
        MOD_SETTINGS.FREQ_DIV[0] <= dout;
        state <= RD_MOD_FREQ_DIV1;
      end
      RD_MOD_FREQ_DIV1: begin
        MOD_SETTINGS.FREQ_DIV[1] <= dout;
        we <= 1'b1;
        addr <= params::ADDR_CTL_FLAG;
        din <= ctl_flags;
        state <= RD_MOD_REP0;
      end
      RD_MOD_REP0: begin
        MOD_SETTINGS.REP[0] <= dout;
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {8'h00, 1'h0  /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO};
        state <= RD_MOD_REP1;
      end
      RD_MOD_REP1: begin
        MOD_SETTINGS.REP[1] <= dout;
        MOD_SETTINGS.UPDATE <= 1'b1;
        we <= 1'b0;
        addr <= params::ADDR_CTL_FLAG;
        state <= MOD_CLR_UPDATE_SETTINGS_BIT;
      end
      MOD_CLR_UPDATE_SETTINGS_BIT: begin
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {8'h00, 1'h0  /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO};
        ctl_flags <= dout;
        MOD_SETTINGS.UPDATE <= 1'b0;
        state <= WAIT_1;
      end

      REQ_STM_REQ_RD_SEGMENT: begin
        we <= 1'b0;
        addr <= params::ADDR_STM_REQ_RD_SEGMENT;
        state <= REQ_STM_TRANSITION_MODE;
      end
      REQ_STM_TRANSITION_MODE: begin
        addr  <= params::ADDR_STM_TRANSITION_MODE;
        state <= REQ_STM_TRANSITION_VALUE_0;
      end
      REQ_STM_TRANSITION_VALUE_0: begin
        addr  <= params::ADDR_STM_TRANSITION_VALUE_0;
        state <= REQ_STM_TRANSITION_VALUE_1_RD_STM_REQ_RD_SEGMENT;
      end
      REQ_STM_TRANSITION_VALUE_1_RD_STM_REQ_RD_SEGMENT: begin
        addr <= params::ADDR_STM_TRANSITION_VALUE_1;
        STM_SETTINGS.REQ_RD_SEGMENT <= dout[0];
        state <= REQ_STM_TRANSITION_VALUE_2_RD_STM_TRANSITION_MODE;
      end
      REQ_STM_TRANSITION_VALUE_2_RD_STM_TRANSITION_MODE: begin
        addr <= params::ADDR_STM_TRANSITION_VALUE_2;
        STM_SETTINGS.TRANSITION_MODE <= dout[7:0];
        state <= REQ_STM_TRANSITION_VALUE_3_RD_STM_TRANSITION_VALUE_0;
      end
      REQ_STM_TRANSITION_VALUE_3_RD_STM_TRANSITION_VALUE_0: begin
        addr <= params::ADDR_STM_TRANSITION_VALUE_3;
        STM_SETTINGS.TRANSITION_VALUE[15:0] <= dout;
        state <= REQ_STM_MODE0_RD_STM_TRANSITION_VALUE_1;
      end
      REQ_STM_MODE0_RD_STM_TRANSITION_VALUE_1: begin
        addr <= params::ADDR_STM_MODE0;
        STM_SETTINGS.TRANSITION_VALUE[31:16] <= dout;
        state <= REQ_STM_MODE1_RD_STM_TRANSITION_VALUE_2;
      end
      REQ_STM_MODE1_RD_STM_TRANSITION_VALUE_2: begin
        addr <= params::ADDR_STM_MODE1;
        STM_SETTINGS.TRANSITION_VALUE[47:32] <= dout;
        state <= REQ_STM_CYCLE0_RD_STM_TRANSITION_VALUE_3;
      end
      REQ_STM_CYCLE0_RD_STM_TRANSITION_VALUE_3: begin
        addr <= params::ADDR_STM_CYCLE0;
        STM_SETTINGS.TRANSITION_VALUE[63:48] <= dout;
        state <= REQ_STM_CYCLE1_RD_STM_MODE0;
      end
      REQ_STM_CYCLE1_RD_STM_MODE0: begin
        addr <= params::ADDR_STM_CYCLE1;
        STM_SETTINGS.MODE[0] <= dout[0];
        state <= REQ_STM_FREQ_DIV0_RD_STM_MODE1;
      end
      REQ_STM_FREQ_DIV0_RD_STM_MODE1: begin
        addr <= params::ADDR_STM_FREQ_DIV0;
        STM_SETTINGS.MODE[1] <= dout[0];
        state <= REQ_STM_FREQ_DIV1_RD_STM_CYCLE0;
      end
      REQ_STM_FREQ_DIV1_RD_STM_CYCLE0: begin
        addr <= params::ADDR_STM_FREQ_DIV1;
        STM_SETTINGS.CYCLE[0] <= dout;
        state <= REQ_STM_SOUND_SPEED0_RD_STM_CYCLE1;
      end
      REQ_STM_SOUND_SPEED0_RD_STM_CYCLE1: begin
        addr <= params::ADDR_STM_SOUND_SPEED0;
        STM_SETTINGS.CYCLE[1] <= dout;
        state <= REQ_STM_SOUND_SPEED1_RD_STM_FREQ_DIV0;
      end
      REQ_STM_SOUND_SPEED1_RD_STM_FREQ_DIV0: begin
        addr <= params::ADDR_STM_SOUND_SPEED1;
        STM_SETTINGS.FREQ_DIV[0] <= dout;
        state <= REQ_STM_REP0_RD_STM_FREQ_DIV1;
      end
      REQ_STM_REP0_RD_STM_FREQ_DIV1: begin
        addr <= params::ADDR_STM_REP0;
        STM_SETTINGS.FREQ_DIV[1] <= dout;
        state <= REQ_STM_REP1_RD_STM_SOUND_SPEED0;
      end
      REQ_STM_REP1_RD_STM_SOUND_SPEED0: begin
        addr <= params::ADDR_STM_REP1;
        STM_SETTINGS.SOUND_SPEED[0] <= dout;
        state <= REQ_STM_NUM_FOCI0_RD_STM_SOUND_SPEED1;
      end
      REQ_STM_NUM_FOCI0_RD_STM_SOUND_SPEED1: begin
        addr <= params::ADDR_STM_NUM_FOCI0;
        STM_SETTINGS.SOUND_SPEED[1] <= dout;
        state <= REQ_STM_NUM_FOCI1_RD_STM_REP0;
      end
      REQ_STM_NUM_FOCI1_RD_STM_REP0: begin
        addr <= params::ADDR_STM_NUM_FOCI1;
        STM_SETTINGS.REP[0] <= dout;
        state <= RD_STM_REP1;
      end
      RD_STM_REP1: begin
        STM_SETTINGS.REP[1] <= dout;
        we <= 1'b1;
        addr <= params::ADDR_CTL_FLAG;
        din <= ctl_flags;
        state <= RD_STM_NUM_FOCI0;
      end
      RD_STM_NUM_FOCI0: begin
        STM_SETTINGS.NUM_FOCI[0] <= dout[7:0];
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {8'h00, 1'h0  /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO};
        state <= RD_STM_NUM_FOCI1;
      end
      RD_STM_NUM_FOCI1: begin
        STM_SETTINGS.NUM_FOCI[1] <= dout[7:0];
        STM_SETTINGS.UPDATE <= 1'b1;
        we <= 1'b0;
        addr <= params::ADDR_CTL_FLAG;
        state <= STM_CLR_UPDATE_SETTINGS_BIT;
      end
      STM_CLR_UPDATE_SETTINGS_BIT: begin
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {8'h00, 1'h0  /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO};
        ctl_flags <= dout;
        STM_SETTINGS.UPDATE <= 1'b0;
        state <= WAIT_1;
      end

      REQ_SILENCER_FLAG: begin
        we <= 1'b0;
        addr <= params::ADDR_SILENCER_FLAG;
        state <= REQ_SILENCER_UPDATE_RATE_INTENSITY;
      end
      REQ_SILENCER_UPDATE_RATE_INTENSITY: begin
        addr  <= params::ADDR_SILENCER_UPDATE_RATE_INTENSITY;
        state <= REQ_SILENCER_UPDATE_RATE_PHASE;
      end
      REQ_SILENCER_UPDATE_RATE_PHASE: begin
        addr  <= params::ADDR_SILENCER_UPDATE_RATE_PHASE;
        state <= REQ_SILENCER_COMPLETION_STEPS_INTENSITY_RD_SILENCER_FLAG;
      end
      REQ_SILENCER_COMPLETION_STEPS_INTENSITY_RD_SILENCER_FLAG: begin
        addr <= params::ADDR_SILENCER_COMPLETION_STEPS_INTENSITY;
        SILENCER_SETTINGS.FLAG <= dout[7:0];
        state <= REQ_SILENCER_COMPLETION_STEPS_PHASE_RD_SILENCER_UPDATE_RATE_INTENSITY;
      end
      REQ_SILENCER_COMPLETION_STEPS_PHASE_RD_SILENCER_UPDATE_RATE_INTENSITY: begin
        addr <= params::ADDR_SILENCER_COMPLETION_STEPS_PHASE;
        SILENCER_SETTINGS.UPDATE_RATE_INTENSITY <= dout;
        state <= RD_SILENCER_UPDATE_RATE_PHASE;
      end
      RD_SILENCER_UPDATE_RATE_PHASE: begin
        SILENCER_SETTINGS.UPDATE_RATE_PHASE <= dout;
        we <= 1'b1;
        addr <= params::ADDR_CTL_FLAG;
        din <= ctl_flags;
        state <= RD_SILENCER_COMPLETION_STEPS_INTENSITY;
      end
      RD_SILENCER_COMPLETION_STEPS_INTENSITY: begin
        SILENCER_SETTINGS.COMPLETION_STEPS_INTENSITY <= dout;
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {8'h00, 1'h0  /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO};
        state <= RD_SILENCER_COMPLETION_STEPS_PHASE;
      end
      RD_SILENCER_COMPLETION_STEPS_PHASE: begin
        SILENCER_SETTINGS.COMPLETION_STEPS_PHASE <= dout;
        SILENCER_SETTINGS.UPDATE <= 1'b1;
        we <= 1'b0;
        addr <= params::ADDR_CTL_FLAG;
        state <= SILENCER_CLR_UPDATE_SETTINGS_BIT;
      end
      SILENCER_CLR_UPDATE_SETTINGS_BIT: begin
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {8'h00, 1'h0  /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO};
        ctl_flags <= dout;
        SILENCER_SETTINGS.UPDATE <= 1'b0;
        state <= WAIT_1;
      end

      REQ_DEBUG_VALUE0_0: begin
        we <= 1'b0;
        addr <= params::ADDR_DEBUG_VALUE0_0;
        state <= REQ_DEBUG_VALUE0_1;
      end
      REQ_DEBUG_VALUE0_1: begin
        addr  <= params::ADDR_DEBUG_VALUE0_1;
        state <= REQ_DEBUG_VALUE0_2;
      end
      REQ_DEBUG_VALUE0_2: begin
        addr  <= params::ADDR_DEBUG_VALUE0_2;
        state <= REQ_DEBUG_VALUE0_3_RD_DEBUG_VALUE0_0;
      end
      REQ_DEBUG_VALUE0_3_RD_DEBUG_VALUE0_0: begin
        addr <= params::ADDR_DEBUG_VALUE0_3;
        DEBUG_SETTINGS.VALUE[0][15:0] <= dout;
        state <= REQ_DEBUG_VALUE1_0_RD_DEBUG_VALUE0_1;
      end
      REQ_DEBUG_VALUE1_0_RD_DEBUG_VALUE0_1: begin
        addr <= params::ADDR_DEBUG_VALUE1_0;
        DEBUG_SETTINGS.VALUE[0][31:16] <= dout;
        state <= REQ_DEBUG_VALUE1_1_RD_DEBUG_VALUE0_2;
      end
      REQ_DEBUG_VALUE1_1_RD_DEBUG_VALUE0_2: begin
        addr <= params::ADDR_DEBUG_VALUE1_1;
        DEBUG_SETTINGS.VALUE[0][47:32] <= dout;
        state <= REQ_DEBUG_VALUE1_2_RD_DEBUG_VALUE0_3;
      end
      REQ_DEBUG_VALUE1_2_RD_DEBUG_VALUE0_3: begin
        addr <= params::ADDR_DEBUG_VALUE1_2;
        DEBUG_SETTINGS.VALUE[0][63:48] <= dout;
        state <= REQ_DEBUG_VALUE1_3_RD_DEBUG_VALUE1_0;
      end
      REQ_DEBUG_VALUE1_3_RD_DEBUG_VALUE1_0: begin
        addr <= params::ADDR_DEBUG_VALUE1_3;
        DEBUG_SETTINGS.VALUE[1][15:0] <= dout;
        state <= REQ_DEBUG_VALUE2_0_RD_DEBUG_VALUE1_1;
      end
      REQ_DEBUG_VALUE2_0_RD_DEBUG_VALUE1_1: begin
        addr <= params::ADDR_DEBUG_VALUE2_0;
        DEBUG_SETTINGS.VALUE[1][31:16] <= dout;
        state <= REQ_DEBUG_VALUE2_1_RD_DEBUG_VALUE1_2;
      end
      REQ_DEBUG_VALUE2_1_RD_DEBUG_VALUE1_2: begin
        addr <= params::ADDR_DEBUG_VALUE2_1;
        DEBUG_SETTINGS.VALUE[1][47:32] <= dout;
        state <= REQ_DEBUG_VALUE2_2_RD_DEBUG_VALUE1_3;
      end
      REQ_DEBUG_VALUE2_2_RD_DEBUG_VALUE1_3: begin
        addr <= params::ADDR_DEBUG_VALUE2_2;
        DEBUG_SETTINGS.VALUE[1][63:48] <= dout;
        state <= REQ_DEBUG_VALUE2_3_RD_DEBUG_VALUE2_0;
      end
      REQ_DEBUG_VALUE2_3_RD_DEBUG_VALUE2_0: begin
        addr <= params::ADDR_DEBUG_VALUE2_3;
        DEBUG_SETTINGS.VALUE[2][15:0] <= dout;
        state <= REQ_DEBUG_VALUE3_0_RD_DEBUG_VALUE2_1;
      end
      REQ_DEBUG_VALUE3_0_RD_DEBUG_VALUE2_1: begin
        addr <= params::ADDR_DEBUG_VALUE3_0;
        DEBUG_SETTINGS.VALUE[2][31:16] <= dout;
        state <= REQ_DEBUG_VALUE3_1_RD_DEBUG_VALUE2_2;
      end
      REQ_DEBUG_VALUE3_1_RD_DEBUG_VALUE2_2: begin
        addr <= params::ADDR_DEBUG_VALUE3_1;
        DEBUG_SETTINGS.VALUE[2][47:32] <= dout;
        state <= REQ_DEBUG_VALUE3_2_RD_DEBUG_VALUE2_3;
      end
      REQ_DEBUG_VALUE3_2_RD_DEBUG_VALUE2_3: begin
        addr <= params::ADDR_DEBUG_VALUE3_2;
        DEBUG_SETTINGS.VALUE[2][63:48] <= dout;
        state <= REQ_DEBUG_VALUE3_3_RD_DEBUG_VALUE3_0;
      end
      REQ_DEBUG_VALUE3_3_RD_DEBUG_VALUE3_0: begin
        addr <= params::ADDR_DEBUG_VALUE3_3;
        DEBUG_SETTINGS.VALUE[3][15:0] <= dout;
        state <= RD_DEBUG_VALUE3_1;
      end
      RD_DEBUG_VALUE3_1: begin
        DEBUG_SETTINGS.VALUE[3][31:16] <= dout;
        we <= 1'b1;
        addr <= params::ADDR_CTL_FLAG;
        din <= ctl_flags;
        state <= RD_DEBUG_VALUE3_2;
      end
      RD_DEBUG_VALUE3_2: begin
        DEBUG_SETTINGS.VALUE[3][47:32] <= dout;
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {8'h00, 1'h0  /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO};
        state <= RD_DEBUG_VALUE3_3;
      end
      RD_DEBUG_VALUE3_3: begin
        DEBUG_SETTINGS.VALUE[3][63:48] <= dout;
        DEBUG_SETTINGS.UPDATE <= 1'b1;
        we <= 1'b0;
        addr <= params::ADDR_CTL_FLAG;
        state <= DEBUG_CLR_UPDATE_SETTINGS_BIT;
      end
      DEBUG_CLR_UPDATE_SETTINGS_BIT: begin
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {8'h00, 1'h0  /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO};
        ctl_flags <= dout;
        DEBUG_SETTINGS.UPDATE <= 1'b0;
        state <= WAIT_1;
      end

      REQ_ECAT_SYNC_TIME_0: begin
        we <= 1'b0;
        addr <= params::ADDR_ECAT_SYNC_TIME_0;
        state <= REQ_ECAT_SYNC_TIME_1;
      end
      REQ_ECAT_SYNC_TIME_1: begin
        addr  <= params::ADDR_ECAT_SYNC_TIME_1;
        state <= REQ_ECAT_SYNC_TIME_2;
      end
      REQ_ECAT_SYNC_TIME_2: begin
        addr  <= params::ADDR_ECAT_SYNC_TIME_2;
        state <= REQ_ECAT_SYNC_TIME_3_RD_ECAT_SYNC_TIME_0;
      end
      REQ_ECAT_SYNC_TIME_3_RD_ECAT_SYNC_TIME_0: begin
        addr <= params::ADDR_ECAT_SYNC_TIME_3;
        SYNC_SETTINGS.ECAT_SYNC_TIME[15:0] <= dout;
        state <= RD_ECAT_SYNC_TIME_1;
      end
      RD_ECAT_SYNC_TIME_1: begin
        SYNC_SETTINGS.ECAT_SYNC_TIME[31:16] <= dout;
        we <= 1'b1;
        addr <= params::ADDR_CTL_FLAG;
        din <= ctl_flags;
        state <= RD_ECAT_SYNC_TIME_2;
      end
      RD_ECAT_SYNC_TIME_2: begin
        SYNC_SETTINGS.ECAT_SYNC_TIME[47:32] <= dout;
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {8'h00, 1'h0  /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO};
        state <= RD_ECAT_SYNC_TIME_3;
      end
      RD_ECAT_SYNC_TIME_3: begin
        SYNC_SETTINGS.ECAT_SYNC_TIME[63:48] <= dout;
        SYNC_SETTINGS.UPDATE <= 1'b1;
        we <= 1'b0;
        addr <= params::ADDR_CTL_FLAG;
        state <= SYNC_CLR_UPDATE_SETTINGS_BIT;
      end
      SYNC_CLR_UPDATE_SETTINGS_BIT: begin
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {8'h00, 1'h0  /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO};
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
    MOD_SETTINGS.TRANSITION_MODE = params::TRANSITION_MODE_SYNC_IDX;
    MOD_SETTINGS.TRANSITION_VALUE = 64'd0;
    MOD_SETTINGS.CYCLE[0] = 16'd1;
    MOD_SETTINGS.CYCLE[1] = 16'd1;
    MOD_SETTINGS.FREQ_DIV[0] = 16'd10;
    MOD_SETTINGS.FREQ_DIV[1] = 16'd10;
    MOD_SETTINGS.REP[0] = 16'hFFFF;
    MOD_SETTINGS.REP[1] = 16'hFFFF;
    STM_SETTINGS.UPDATE = 1'b0;
    STM_SETTINGS.REQ_RD_SEGMENT = 1'd0;
    STM_SETTINGS.TRANSITION_MODE = params::TRANSITION_MODE_SYNC_IDX;
    STM_SETTINGS.TRANSITION_VALUE = 64'd0;
    STM_SETTINGS.MODE[0] = params::STM_MODE_GAIN;
    STM_SETTINGS.MODE[1] = params::STM_MODE_GAIN;
    STM_SETTINGS.CYCLE[0] = 16'd0;
    STM_SETTINGS.CYCLE[1] = 16'd0;
    STM_SETTINGS.FREQ_DIV[0] = 16'hFFFF;
    STM_SETTINGS.FREQ_DIV[1] = 16'hFFFF;
    STM_SETTINGS.SOUND_SPEED[0] = 16'd0;
    STM_SETTINGS.SOUND_SPEED[1] = 16'd0;
    STM_SETTINGS.REP[0] = 16'hFFFF;
    STM_SETTINGS.REP[1] = 16'hFFFF;
    STM_SETTINGS.NUM_FOCI[0] = 1;
    STM_SETTINGS.NUM_FOCI[1] = 1;
    SILENCER_SETTINGS.UPDATE = 1'b0;
    SILENCER_SETTINGS.FLAG = 8'd0;
    SILENCER_SETTINGS.UPDATE_RATE_INTENSITY = 16'd256;
    SILENCER_SETTINGS.UPDATE_RATE_PHASE = 16'd256;
    SILENCER_SETTINGS.COMPLETION_STEPS_INTENSITY = 16'd10;
    SILENCER_SETTINGS.COMPLETION_STEPS_PHASE = 16'd40;
    DEBUG_SETTINGS.UPDATE = 1'b0;
    DEBUG_SETTINGS.VALUE[0] = {params::GPIO_O_TYPE_NONE, 56'd0};
    DEBUG_SETTINGS.VALUE[1] = {params::GPIO_O_TYPE_NONE, 56'd0};
    DEBUG_SETTINGS.VALUE[2] = {params::GPIO_O_TYPE_NONE, 56'd0};
    DEBUG_SETTINGS.VALUE[3] = {params::GPIO_O_TYPE_NONE, 56'd0};
    SYNC_SETTINGS.UPDATE = 1'b0;
    SYNC_SETTINGS.ECAT_SYNC_TIME = 64'd0;
  end

endmodule
