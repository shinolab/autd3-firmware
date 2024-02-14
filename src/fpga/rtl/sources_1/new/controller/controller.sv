`timescale 1ns / 1ps
module controller (
    input wire CLK,
    input wire THERMO,
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

  assign FORCE_FAN = ctl_flags[params::CTL_FLAG_FORCE_FAN_BIT];

  typedef enum logic [6:0] {
    REQ_WR_VER_MINOR,
    REQ_WR_VER,
    WAIT_WR_VER_0_REQ_RD_CTL_FLAG,
    WR_VER_MINOR_WAIT_RD_CTL_FLAG_0,
    WR_VER_WAIT_RD_CTL_FLAG_1,
    WAIT_0,
    WAIT_1,
    REQ_MOD_REQ_RD_SEGMENT,
    REQ_MOD_CYCLE_0,
    REQ_MOD_FREQ_DIV_0_0,
    REQ_MOD_FREQ_DIV_0_1_RD_MOD_REQ_RD_SEGMENT,
    REQ_MOD_CYCLE_1_RD_MOD_CYCLE_0,
    REQ_MOD_FREQ_DIV_1_0_RD_MOD_FREQ_DIV_0_0,
    REQ_MOD_FREQ_DIV_1_1_RD_MOD_FREQ_DIV_0_1,
    REQ_MOD_REP_0_0_RD_MOD_CYCLE_1,
    REQ_MOD_REP_0_1_RD_MOD_FREQ_DIV_1_0,
    REQ_MOD_REP_1_0_RD_MOD_FREQ_DIV_1_1,
    REQ_MOD_REP_1_1_RD_MOD_REP_0_0,
    RD_MOD_REP_0_1,
    RD_MOD_REP_1_0,
    RD_MOD_REP_1_1,
    MOD_CLR_UPDATE_SETTINGS_BIT,
    REQ_STM_MODE_0,
    REQ_STM_MODE_1,
    REQ_STM_REQ_RD_SEGMENT,
    REQ_STM_CYCLE_0_RD_STM_MODE_0,
    REQ_STM_FREQ_DIV_0_0_RD_STM_MODE_1,
    REQ_STM_FREQ_DIV_0_1_RD_STM_REQ_RD_SEGMENT,
    REQ_STM_CYCLE_1_RD_STM_CYCLE_0,
    REQ_STM_FREQ_DIV_1_0_RD_STM_FREQ_DIV_0_0,
    REQ_STM_FREQ_DIV_1_1_RD_STM_FREQ_DIV_0_1,
    REQ_STM_SOUND_SPEED_0_0_RD_STM_CYCLE_1,
    REQ_STM_SOUND_SPEED_0_1_RD_STM_FREQ_DIV_1_0,
    REQ_STM_SOUND_SPEED_1_0_RD_STM_FREQ_DIV_1_1,
    REQ_STM_SOUND_SPEED_1_1_RD_STM_SOUND_SPEED_0_0,
    REQ_STM_REP_0_0_RD_STM_SOUND_SPEED_0_1,
    REQ_STM_REP_0_1_RD_STM_SOUND_SPEED_1_0,
    REQ_STM_REP_1_0_RD_STM_SOUND_SPEED_1_1,
    REQ_STM_REP_1_1_RD_STM_REP_0_0,
    RD_STM_REP_0_1,
    RD_STM_REP_1_0,
    RD_STM_REP_1_1,
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
    REQ_PULSE_WIDTH_ENCODER_DUMMY_0,
    REQ_PULSE_WIDTH_ENCODER_DUMMY_1,
    RD_PULSE_WIDTH_ENCODER_FULL_WIDTH_START,
    PULSE_WIDTH_ENCODER_CLR_UPDATE_SETTINGS_BIT,
    REQ_DEBUG_OUT_IDX,
    REQ_DEBUG_DUMMY_0,
    REQ_DEBUG_DUMMY_1,
    RD_DEBUG_OUT_IDX,
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

        din <= {8'd0, params::VERSION_NUM_MINOR};
        addr <= params::ADDR_VERSION_NUM_MINOR;

        state <= REQ_WR_VER;
      end
      REQ_WR_VER: begin
        din   <= {8'h00, params::VERSION_NUM};
        addr  <= params::ADDR_VERSION_NUM_MAJOR;

        state <= WAIT_WR_VER_0_REQ_RD_CTL_FLAG;
      end
      WAIT_WR_VER_0_REQ_RD_CTL_FLAG: begin
        we <= 1'b0;
        addr <= params::ADDR_CTL_FLAG;

        state <= WR_VER_MINOR_WAIT_RD_CTL_FLAG_0;
      end
      WR_VER_MINOR_WAIT_RD_CTL_FLAG_0: begin
        state <= WR_VER_WAIT_RD_CTL_FLAG_1;
      end
      WR_VER_WAIT_RD_CTL_FLAG_1: begin
        state <= WAIT_0;
      end

      WAIT_0: begin
        we   <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din  <= {{15'h00, THERMO}};

        if (ctl_flags[params::CTL_FLAG_MOD_SET_BIT]) begin
          ctl_flags <= ctl_flags & ~(1 << params::CTL_FLAG_MOD_SET_BIT);
          state <= REQ_MOD_REQ_RD_SEGMENT;
        end else if (ctl_flags[params::CTL_FLAG_STM_SET_BIT]) begin
          ctl_flags <= ctl_flags & ~(1 << params::CTL_FLAG_STM_SET_BIT);
          state <= REQ_STM_MODE_0;
        end else if (ctl_flags[params::CTL_FLAG_SILENCER_SET_BIT]) begin
          ctl_flags <= ctl_flags & ~(1 << params::CTL_FLAG_SILENCER_SET_BIT);
          state <= REQ_SILENCER_MODE;
        end else if (ctl_flags[params::CTL_FLAG_PULSE_WIDTH_ENCODER_SET_BIT]) begin
          ctl_flags <= ctl_flags & ~(1 << params::CTL_FLAG_PULSE_WIDTH_ENCODER_SET_BIT);
          state <= REQ_PULSE_WIDTH_ENCODER_FULL_WIDTH_START;
        end else if (ctl_flags[params::CTL_FLAG_DEBUG_SET_BIT]) begin
          ctl_flags <= ctl_flags & ~(1 << params::CTL_FLAG_DEBUG_SET_BIT);
          state <= REQ_DEBUG_OUT_IDX;
        end else if (ctl_flags[params::CTL_FLAG_SYNC_SET_BIT]) begin
          ctl_flags <= ctl_flags & ~(1 << params::CTL_FLAG_SYNC_SET_BIT);
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
        state <= REQ_MOD_CYCLE_0;
      end
      REQ_MOD_CYCLE_0: begin
        addr <= params::ADDR_MOD_CYCLE_0;
        state <= REQ_MOD_FREQ_DIV_0_0;
      end
      REQ_MOD_FREQ_DIV_0_0: begin
        addr <= params::ADDR_MOD_FREQ_DIV_0_0;
        state <= REQ_MOD_FREQ_DIV_0_1_RD_MOD_REQ_RD_SEGMENT;
      end
      REQ_MOD_FREQ_DIV_0_1_RD_MOD_REQ_RD_SEGMENT: begin
        addr <= params::ADDR_MOD_FREQ_DIV_0_1;
        MOD_SETTINGS.REQ_RD_SEGMENT <= dout[0];
        state <= REQ_MOD_CYCLE_1_RD_MOD_CYCLE_0;
      end
      REQ_MOD_CYCLE_1_RD_MOD_CYCLE_0: begin
        addr <= params::ADDR_MOD_CYCLE_1;
        MOD_SETTINGS.CYCLE_0 <= dout[14:0];
        state <= REQ_MOD_FREQ_DIV_1_0_RD_MOD_FREQ_DIV_0_0;
      end
      REQ_MOD_FREQ_DIV_1_0_RD_MOD_FREQ_DIV_0_0: begin
        addr <= params::ADDR_MOD_FREQ_DIV_1_0;
        MOD_SETTINGS.FREQ_DIV_0[15:0] <= dout;
        state <= REQ_MOD_FREQ_DIV_1_1_RD_MOD_FREQ_DIV_0_1;
      end
      REQ_MOD_FREQ_DIV_1_1_RD_MOD_FREQ_DIV_0_1: begin
        addr <= params::ADDR_MOD_FREQ_DIV_1_1;
        MOD_SETTINGS.FREQ_DIV_0[31:16] <= dout;
        state <= REQ_MOD_REP_0_0_RD_MOD_CYCLE_1;
      end
      REQ_MOD_REP_0_0_RD_MOD_CYCLE_1: begin
        addr <= params::ADDR_MOD_REP_0_0;
        MOD_SETTINGS.CYCLE_1 <= dout[14:0];
        state <= REQ_MOD_REP_0_1_RD_MOD_FREQ_DIV_1_0;
      end
      REQ_MOD_REP_0_1_RD_MOD_FREQ_DIV_1_0: begin
        addr <= params::ADDR_MOD_REP_0_1;
        MOD_SETTINGS.FREQ_DIV_1[15:0] <= dout;
        state <= REQ_MOD_REP_1_0_RD_MOD_FREQ_DIV_1_1;
      end
      REQ_MOD_REP_1_0_RD_MOD_FREQ_DIV_1_1: begin
        addr <= params::ADDR_MOD_REP_1_0;
        MOD_SETTINGS.FREQ_DIV_1[31:16] <= dout;
        state <= REQ_MOD_REP_1_1_RD_MOD_REP_0_0;
      end
      REQ_MOD_REP_1_1_RD_MOD_REP_0_0: begin
        addr <= params::ADDR_MOD_REP_1_1;
        MOD_SETTINGS.REP_0[15:0] <= dout;
        state <= RD_MOD_REP_0_1;
      end
      RD_MOD_REP_0_1: begin
        MOD_SETTINGS.REP_0[31:16] <= dout;
        we <= 1'b1;
        addr <= params::ADDR_CTL_FLAG;
        din <= ctl_flags;
        state <= RD_MOD_REP_1_0;
      end
      RD_MOD_REP_1_0: begin
        MOD_SETTINGS.REP_1[15:0] <= dout;
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {15'h00, THERMO};
        state <= RD_MOD_REP_1_1;
      end
      RD_MOD_REP_1_1: begin
        MOD_SETTINGS.REP_1[31:16] <= dout;
        MOD_SETTINGS.UPDATE <= 1'b1;
        we <= 1'b0;
        addr <= params::ADDR_CTL_FLAG;
        state <= MOD_CLR_UPDATE_SETTINGS_BIT;
      end
      MOD_CLR_UPDATE_SETTINGS_BIT: begin
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {15'h00, THERMO};
        ctl_flags <= dout;
        MOD_SETTINGS.UPDATE <= 1'b0;
        state <= WAIT_1;
      end

      REQ_STM_MODE_0: begin
        we <= 1'b0;
        addr <= params::ADDR_STM_MODE_0;
        state <= REQ_STM_MODE_1;
      end
      REQ_STM_MODE_1: begin
        addr <= params::ADDR_STM_MODE_1;
        state <= REQ_STM_REQ_RD_SEGMENT;
      end
      REQ_STM_REQ_RD_SEGMENT: begin
        addr <= params::ADDR_STM_REQ_RD_SEGMENT;
        state <= REQ_STM_CYCLE_0_RD_STM_MODE_0;
      end
      REQ_STM_CYCLE_0_RD_STM_MODE_0: begin
        addr <= params::ADDR_STM_CYCLE_0;
        STM_SETTINGS.MODE_0 <= dout[0];
        state <= REQ_STM_FREQ_DIV_0_0_RD_STM_MODE_1;
      end
      REQ_STM_FREQ_DIV_0_0_RD_STM_MODE_1: begin
        addr <= params::ADDR_STM_FREQ_DIV_0_0;
        STM_SETTINGS.MODE_1 <= dout[0];
        state <= REQ_STM_FREQ_DIV_0_1_RD_STM_REQ_RD_SEGMENT;
      end
      REQ_STM_FREQ_DIV_0_1_RD_STM_REQ_RD_SEGMENT: begin
        addr <= params::ADDR_STM_FREQ_DIV_0_1;
        STM_SETTINGS.REQ_RD_SEGMENT <= dout[0];
        state <= REQ_STM_CYCLE_1_RD_STM_CYCLE_0;
      end
      REQ_STM_CYCLE_1_RD_STM_CYCLE_0: begin
        addr <= params::ADDR_STM_CYCLE_1;
        STM_SETTINGS.CYCLE_0 <= dout;
        state <= REQ_STM_FREQ_DIV_1_0_RD_STM_FREQ_DIV_0_0;
      end
      REQ_STM_FREQ_DIV_1_0_RD_STM_FREQ_DIV_0_0: begin
        addr <= params::ADDR_STM_FREQ_DIV_1_0;
        STM_SETTINGS.FREQ_DIV_0[15:0] <= dout;
        state <= REQ_STM_FREQ_DIV_1_1_RD_STM_FREQ_DIV_0_1;
      end
      REQ_STM_FREQ_DIV_1_1_RD_STM_FREQ_DIV_0_1: begin
        addr <= params::ADDR_STM_FREQ_DIV_1_1;
        STM_SETTINGS.FREQ_DIV_0[31:16] <= dout;
        state <= REQ_STM_SOUND_SPEED_0_0_RD_STM_CYCLE_1;
      end
      REQ_STM_SOUND_SPEED_0_0_RD_STM_CYCLE_1: begin
        addr <= params::ADDR_STM_SOUND_SPEED_0_0;
        STM_SETTINGS.CYCLE_1 <= dout;
        state <= REQ_STM_SOUND_SPEED_0_1_RD_STM_FREQ_DIV_1_0;
      end
      REQ_STM_SOUND_SPEED_0_1_RD_STM_FREQ_DIV_1_0: begin
        addr <= params::ADDR_STM_SOUND_SPEED_0_1;
        STM_SETTINGS.FREQ_DIV_1[15:0] <= dout;
        state <= REQ_STM_SOUND_SPEED_1_0_RD_STM_FREQ_DIV_1_1;
      end
      REQ_STM_SOUND_SPEED_1_0_RD_STM_FREQ_DIV_1_1: begin
        addr <= params::ADDR_STM_SOUND_SPEED_1_0;
        STM_SETTINGS.FREQ_DIV_1[31:16] <= dout;
        state <= REQ_STM_SOUND_SPEED_1_1_RD_STM_SOUND_SPEED_0_0;
      end
      REQ_STM_SOUND_SPEED_1_1_RD_STM_SOUND_SPEED_0_0: begin
        addr <= params::ADDR_STM_SOUND_SPEED_1_1;
        STM_SETTINGS.SOUND_SPEED_0[15:0] <= dout;
        state <= REQ_STM_REP_0_0_RD_STM_SOUND_SPEED_0_1;
      end
      REQ_STM_REP_0_0_RD_STM_SOUND_SPEED_0_1: begin
        addr <= params::ADDR_STM_REP_0_0;
        STM_SETTINGS.SOUND_SPEED_0[31:16] <= dout;
        state <= REQ_STM_REP_0_1_RD_STM_SOUND_SPEED_1_0;
      end
      REQ_STM_REP_0_1_RD_STM_SOUND_SPEED_1_0: begin
        addr <= params::ADDR_STM_REP_0_1;
        STM_SETTINGS.SOUND_SPEED_1[15:0] <= dout;
        state <= REQ_STM_REP_1_0_RD_STM_SOUND_SPEED_1_1;
      end
      REQ_STM_REP_1_0_RD_STM_SOUND_SPEED_1_1: begin
        addr <= params::ADDR_STM_REP_1_0;
        STM_SETTINGS.SOUND_SPEED_1[31:16] <= dout;
        state <= REQ_STM_REP_1_1_RD_STM_REP_0_0;
      end
      REQ_STM_REP_1_1_RD_STM_REP_0_0: begin
        addr <= params::ADDR_STM_REP_1_1;
        STM_SETTINGS.REP_0[15:0] <= dout;
        state <= RD_STM_REP_0_1;
      end
      RD_STM_REP_0_1: begin
        STM_SETTINGS.REP_0[31:16] <= dout;
        we <= 1'b1;
        addr <= params::ADDR_CTL_FLAG;
        din <= ctl_flags;
        state <= RD_STM_REP_1_0;
      end
      RD_STM_REP_1_0: begin
        STM_SETTINGS.REP_1[15:0] <= dout;
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {15'h00, THERMO};
        state <= RD_STM_REP_1_1;
      end
      RD_STM_REP_1_1: begin
        STM_SETTINGS.REP_1[31:16] <= dout;
        STM_SETTINGS.UPDATE <= 1'b1;
        we <= 1'b0;
        addr <= params::ADDR_CTL_FLAG;
        state <= STM_CLR_UPDATE_SETTINGS_BIT;
      end
      STM_CLR_UPDATE_SETTINGS_BIT: begin
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {15'h00, THERMO};
        ctl_flags <= dout;
        STM_SETTINGS.UPDATE <= 1'b0;
        state <= WAIT_1;
      end

      REQ_SILENCER_MODE: begin
        we <= 1'b0;
        addr <= params::ADDR_SILENCER_MODE;
        state <= REQ_SILENCER_UPDATE_RATE_INTENSITY;
      end
      REQ_SILENCER_UPDATE_RATE_INTENSITY: begin
        addr <= params::ADDR_SILENCER_UPDATE_RATE_INTENSITY;
        state <= REQ_SILENCER_UPDATE_RATE_PHASE;
      end
      REQ_SILENCER_UPDATE_RATE_PHASE: begin
        addr <= params::ADDR_SILENCER_UPDATE_RATE_PHASE;
        state <= REQ_SILENCER_COMPLETION_STEPS_INTENSITY_RD_SILENCER_MODE;
      end
      REQ_SILENCER_COMPLETION_STEPS_INTENSITY_RD_SILENCER_MODE: begin
        addr <= params::ADDR_SILENCER_COMPLETION_STEPS_INTENSITY;
        SILENCER_SETTINGS.MODE <= dout[0];
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
        din <= {15'h00, THERMO};
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
        din <= {15'h00, THERMO};
        ctl_flags <= dout;
        SILENCER_SETTINGS.UPDATE <= 1'b0;
        state <= WAIT_1;
      end

      REQ_PULSE_WIDTH_ENCODER_FULL_WIDTH_START: begin
        we <= 1'b0;
        addr <= params::ADDR_PULSE_WIDTH_ENCODER_FULL_WIDTH_START;
        state <= REQ_PULSE_WIDTH_ENCODER_DUMMY_0;
      end
      REQ_PULSE_WIDTH_ENCODER_DUMMY_0: begin
        we <= 1'b1;
        addr <= params::ADDR_CTL_FLAG;
        din <= ctl_flags;
        state <= REQ_PULSE_WIDTH_ENCODER_DUMMY_1;
      end
      REQ_PULSE_WIDTH_ENCODER_DUMMY_1: begin
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {15'h00, THERMO};
        state <= RD_PULSE_WIDTH_ENCODER_FULL_WIDTH_START;
      end
      RD_PULSE_WIDTH_ENCODER_FULL_WIDTH_START: begin
        PULSE_WIDTH_ENCODER_SETTINGS.FULL_WIDTH_START <= dout;
        PULSE_WIDTH_ENCODER_SETTINGS.UPDATE <= 1'b1;
        we <= 1'b0;
        addr <= params::ADDR_CTL_FLAG;
        state <= PULSE_WIDTH_ENCODER_CLR_UPDATE_SETTINGS_BIT;
      end
      PULSE_WIDTH_ENCODER_CLR_UPDATE_SETTINGS_BIT: begin
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {15'h00, THERMO};
        ctl_flags <= dout;
        PULSE_WIDTH_ENCODER_SETTINGS.UPDATE <= 1'b0;
        state <= WAIT_1;
      end

      REQ_DEBUG_OUT_IDX: begin
        we <= 1'b0;
        addr <= params::ADDR_DEBUG_OUT_IDX;
        state <= REQ_DEBUG_DUMMY_0;
      end
      REQ_DEBUG_DUMMY_0: begin
        we <= 1'b1;
        addr <= params::ADDR_CTL_FLAG;
        din <= ctl_flags;
        state <= REQ_DEBUG_DUMMY_1;
      end
      REQ_DEBUG_DUMMY_1: begin
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {15'h00, THERMO};
        state <= RD_DEBUG_OUT_IDX;
      end
      RD_DEBUG_OUT_IDX: begin
        DEBUG_SETTINGS.OUTPUT_IDX <= dout[7:0];
        DEBUG_SETTINGS.UPDATE <= 1'b1;
        we <= 1'b0;
        addr <= params::ADDR_CTL_FLAG;
        state <= DEBUG_CLR_UPDATE_SETTINGS_BIT;
      end
      DEBUG_CLR_UPDATE_SETTINGS_BIT: begin
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {15'h00, THERMO};
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
        addr <= params::ADDR_ECAT_SYNC_TIME_1;
        state <= REQ_ECAT_SYNC_TIME_2;
      end
      REQ_ECAT_SYNC_TIME_2: begin
        addr <= params::ADDR_ECAT_SYNC_TIME_2;
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
        din <= {15'h00, THERMO};
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
        din <= {15'h00, THERMO};
        ctl_flags <= dout;
        SYNC_SETTINGS.UPDATE <= 1'b0;
        state <= WAIT_1;
      end

      default: state <= WAIT_0;
    endcase
  end

  initial begin
    MOD_SETTINGS.UPDATE                           = 1'b0;
    MOD_SETTINGS.REQ_RD_SEGMENT                   = 1'b0;
    MOD_SETTINGS.CYCLE_0                          = 15'd1;
    MOD_SETTINGS.FREQ_DIV_0                       = 32'd5120;
    MOD_SETTINGS.CYCLE_1                          = 15'd1;
    MOD_SETTINGS.FREQ_DIV_1                       = 32'd5120;
    MOD_SETTINGS.REP_0                            = 32'hFFFFFFFF;
    MOD_SETTINGS.REP_1                            = 32'hFFFFFFFF;

    STM_SETTINGS.UPDATE                           = 1'b0;
    STM_SETTINGS.MODE_0                           = params::STM_MODE_GAIN;
    STM_SETTINGS.MODE_1                           = params::STM_MODE_GAIN;
    STM_SETTINGS.REQ_RD_SEGMENT                   = 1'b0;
    STM_SETTINGS.CYCLE_0                          = '0;
    STM_SETTINGS.FREQ_DIV_0                       = 32'hFFFFFFFF;
    STM_SETTINGS.CYCLE_1                          = '0;
    STM_SETTINGS.FREQ_DIV_1                       = 32'hFFFFFFFF;
    STM_SETTINGS.REP_0                            = 32'hFFFFFFFF;
    STM_SETTINGS.REP_1                            = 32'hFFFFFFFF;
    STM_SETTINGS.SOUND_SPEED_0                    = '0;
    STM_SETTINGS.SOUND_SPEED_1                    = '0;

    SILENCER_SETTINGS.UPDATE                      = 1'b0;
    SILENCER_SETTINGS.MODE                        = params::SILNCER_MODE_FIXED_COMPLETION_STEPS;
    SILENCER_SETTINGS.UPDATE_RATE_INTENSITY       = 16'd256;
    SILENCER_SETTINGS.UPDATE_RATE_PHASE           = 16'd256;
    SILENCER_SETTINGS.COMPLETION_STEPS_INTENSITY  = 16'd10;
    SILENCER_SETTINGS.COMPLETION_STEPS_PHASE      = 16'd40;

    SYNC_SETTINGS.UPDATE                          = 1'b0;
    SYNC_SETTINGS.ECAT_SYNC_TIME                  = '0;

    PULSE_WIDTH_ENCODER_SETTINGS.UPDATE           = 1'b0;
    PULSE_WIDTH_ENCODER_SETTINGS.FULL_WIDTH_START = 16'd65025;

    DEBUG_SETTINGS.UPDATE                         = 1'b0;
    DEBUG_SETTINGS.OUTPUT_IDX                     = 8'hFF;
  end

endmodule
