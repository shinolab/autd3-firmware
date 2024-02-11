`timescale 1ns / 1ps
module controller #(
    parameter int DEPTH = 249
) (
    input var CLK,
    input var THERMO,
    cnt_bus_if.out_port cnt_bus,
    output var UPDATE_SETTINGS,
    output settings::mod_settings_t MOD_SETTINGS,
    output settings::stm_settings_t STM_SETTINGS,
    output settings::silencer_settings_t SILENCER_SETTINGS,
    output settings::sync_settings_t SYNC_SETTINGS,
    output settings::debug_settings_t DEBUG_SETTINGS,
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

  typedef enum logic [4:0] {
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
    REQ_MOD_REP_0_RD_MOD_CYCLE_1,
    REQ_MOD_REP_1_RD_MOD_FREQ_DIV_1_0,
    REQ_STM_MODE_RD_MOD_FREQ_DIV_1_1,
    REQ_STM_REQ_RD_SEGMENT_RD_MOD_REP_0,
    REQ_STM_CYCLE_0_RD_MOD_REP_1,
    REQ_STM_FREQ_DIV_0_0_RD_STM_MODE,
    REQ_STM_FREQ_DIV_0_1_RD_STM_REQ_RD_SEGMENT,
    REQ_STM_CYCLE_1_RD_STM_CYCLE_0,
    REQ_STM_FREQ_DIV_1_0_RD_STM_FREQ_DIV_0_0,
    REQ_STM_FREQ_DIV_1_1_RD_STM_FREQ_DIV_0_1,
    REQ_STM_SOUND_SPEED_0_RD_STM_CYCLE_1,
    REQ_STM_SOUND_SPEED_1_RD_STM_FREQ_DIV_1_0,
    REQ_STM_REP_0_RD_STM_FREQ_DIV_1_1,
    REQ_STM_REP_1_RD_STM_SOUND_SPEED_0,
    REQ_SILENCER_MODE_RD_STM_SOUND_SPEED_1,
    REQ_SILENCER_UPDATE_RATE_INTENSITY_RD_STM_REP_0,
    REQ_SILENCER_UPDATE_RATE_PHASE_RD_STM_REP_1,
    REQ_SILENCER_COMPLETION_STEPS_INTENSITY_RD_SILENCER_MODE,
    REQ_SILENCER_COMPLETION_STEPS_PHASE_RD_SILENCER_UPDATE_RATE_INTENSITY,
    REQ_DEBUG_OUT_IDX_RD_SILENCER_UPDATE_RATE_PHASE,
    RD_SILENCER_COMPLETION_STEPS_INTENSITY,
    RD_SILENCER_COMPLETION_STEPS_PHASE,
    RD_DEBUG_OUT_IDX,
    CLR_UPDATE_SETTINGS_BIT,

    REQ_ECAT_SYNC_TIME_0,
    REQ_ECAT_SYNC_TIME_1,
    REQ_ECAT_SYNC_TIME_2,
    REQ_ECAT_SYNC_TIME_3_RD_ECAT_SYNC_TIME_0,
    RD_ECAT_SYNC_TIME_1,
    RD_ECAT_SYNC_TIME_2,
    RD_ECAT_SYNC_TIME_3,
    CLR_SYNC_BIT
  } state_t;

  state_t state = REQ_WR_VER_MINOR;

  always_ff @(posedge CLK) begin
    case (state)
      ////////////////////////// initial //////////////////////////
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
      ////////////////////////// initial //////////////////////////

      //////////////////////////// wait ///////////////////////////
      WAIT_0: begin
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {15'h00, THERMO};
        ctl_flags <= dout;

        state <= WAIT_1;
      end
      WAIT_1: begin
        if (ctl_flags[params::CTL_FLAG_SYNC_BIT]) begin
          we <= 1'b1;
          addr <= params::ADDR_CTL_FLAG;
          din <= ctl_flags & ~(1 << params::CTL_FLAG_SYNC_BIT);

          state <= REQ_ECAT_SYNC_TIME_0;
        end else if (ctl_flags[params::CTL_FLAG_SET_BIT]) begin
          we <= 1'b0;
          state <= REQ_MOD_REQ_RD_SEGMENT;
        end else begin
          addr <= params::ADDR_CTL_FLAG;
          we <= 1'b0;
          state <= WAIT_0;
        end
      end
      //////////////////////////// wait ///////////////////////////

      //////////////////////////// load ///////////////////////////

      REQ_MOD_REQ_RD_SEGMENT: begin
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

        state <= REQ_MOD_REP_0_RD_MOD_CYCLE_1;
      end
      REQ_MOD_REP_0_RD_MOD_CYCLE_1: begin
        addr <= params::ADDR_MOD_REP_0;

        MOD_SETTINGS.CYCLE_1 <= dout[14:0];

        state <= REQ_MOD_REP_1_RD_MOD_FREQ_DIV_1_0;
      end
      REQ_MOD_REP_1_RD_MOD_FREQ_DIV_1_0: begin
        addr <= params::ADDR_MOD_REP_1;

        MOD_SETTINGS.FREQ_DIV_1[15:0] <= dout;

        state <= REQ_STM_MODE_RD_MOD_FREQ_DIV_1_1;
      end
      REQ_STM_MODE_RD_MOD_FREQ_DIV_1_1: begin
        addr <= params::ADDR_STM_MODE;

        MOD_SETTINGS.FREQ_DIV_1[31:16] <= dout;

        state <= REQ_STM_REQ_RD_SEGMENT_RD_MOD_REP_0;
      end
      REQ_STM_REQ_RD_SEGMENT_RD_MOD_REP_0: begin
        addr <= params::ADDR_STM_REQ_RD_SEGMENT;

        MOD_SETTINGS.REP[15:0] <= dout;

        state <= REQ_STM_CYCLE_0_RD_MOD_REP_1;
      end
      REQ_STM_CYCLE_0_RD_MOD_REP_1: begin
        addr <= params::ADDR_STM_CYCLE_0;

        MOD_SETTINGS.REP[31:16] <= dout;

        state <= REQ_STM_FREQ_DIV_0_0_RD_STM_MODE;
      end
      REQ_STM_FREQ_DIV_0_0_RD_STM_MODE: begin
        addr <= params::ADDR_STM_FREQ_DIV_0_0;

        STM_SETTINGS.MODE <= dout[0];

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

        state <= REQ_STM_SOUND_SPEED_0_RD_STM_CYCLE_1;
      end
      REQ_STM_SOUND_SPEED_0_RD_STM_CYCLE_1: begin
        addr <= params::ADDR_STM_SOUND_SPEED_0;

        STM_SETTINGS.CYCLE_1 <= dout;

        state <= REQ_STM_SOUND_SPEED_1_RD_STM_FREQ_DIV_1_0;
      end
      REQ_STM_SOUND_SPEED_1_RD_STM_FREQ_DIV_1_0: begin
        addr <= params::ADDR_STM_SOUND_SPEED_1;

        STM_SETTINGS.FREQ_DIV_1[15:0] <= dout;

        state <= REQ_STM_REP_0_RD_STM_FREQ_DIV_1_1;
      end
      REQ_STM_REP_0_RD_STM_FREQ_DIV_1_1: begin
        addr <= params::ADDR_STM_REP_0;

        STM_SETTINGS.FREQ_DIV_1[31:16] <= dout;

        state <= REQ_STM_REP_1_RD_STM_SOUND_SPEED_0;
      end
      REQ_STM_REP_1_RD_STM_SOUND_SPEED_0: begin
        addr <= params::ADDR_STM_REP_1;

        STM_SETTINGS.SOUND_SPEED[15:0] <= dout;

        state <= REQ_SILENCER_MODE_RD_STM_SOUND_SPEED_1;
      end
      REQ_SILENCER_MODE_RD_STM_SOUND_SPEED_1: begin
        addr <= params::ADDR_SILENCER_MODE;

        STM_SETTINGS.SOUND_SPEED[31:16] <= dout;

        state <= REQ_SILENCER_UPDATE_RATE_INTENSITY_RD_STM_REP_0;
      end
      REQ_SILENCER_UPDATE_RATE_INTENSITY_RD_STM_REP_0: begin
        addr <= params::ADDR_SILENCER_UPDATE_RATE_INTENSITY;

        STM_SETTINGS.REP[15:0] <= dout;

        state <= REQ_SILENCER_UPDATE_RATE_PHASE_RD_STM_REP_1;
      end
      REQ_SILENCER_UPDATE_RATE_PHASE_RD_STM_REP_1: begin
        addr <= params::ADDR_SILENCER_UPDATE_RATE_PHASE;

        STM_SETTINGS.REP[31:16] <= dout;

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

        state <= REQ_DEBUG_OUT_IDX_RD_SILENCER_UPDATE_RATE_PHASE;
      end
      REQ_DEBUG_OUT_IDX_RD_SILENCER_UPDATE_RATE_PHASE: begin
        addr <= params::ADDR_DEBUG_OUT_IDX;

        SILENCER_SETTINGS.UPDATE_RATE_PHASE <= dout;

        state <= RD_SILENCER_COMPLETION_STEPS_INTENSITY;
      end
      RD_SILENCER_COMPLETION_STEPS_INTENSITY: begin
        SILENCER_SETTINGS.COMPLETION_STEPS_INTENSITY <= dout;

        addr <= params::ADDR_CTL_FLAG;

        state <= RD_SILENCER_COMPLETION_STEPS_PHASE;
      end
      RD_SILENCER_COMPLETION_STEPS_PHASE: begin
        SILENCER_SETTINGS.COMPLETION_STEPS_PHASE <= dout;

        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {15'h00, THERMO};

        state <= RD_DEBUG_OUT_IDX;
      end
      RD_DEBUG_OUT_IDX: begin
        DEBUG_SETTINGS.OUTPUT_IDX <= dout[7:0];

        we <= 1'b0;
        addr <= params::ADDR_CTL_FLAG;

        UPDATE_SETTINGS <= 1'b1;

        state <= CLR_UPDATE_SETTINGS_BIT;
      end
      CLR_UPDATE_SETTINGS_BIT: begin
        UPDATE_SETTINGS <= 1'b0;

        ctl_flags <= dout;
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {15'h00, THERMO};

        state <= WAIT_1;
      end
      //////////////////////////// load ///////////////////////////

      //////////////////////// synchronize ////////////////////////
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

        addr <= params::ADDR_CTL_FLAG;

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

        we <= 1'b0;
        addr <= params::ADDR_CTL_FLAG;

        SYNC_SETTINGS.SET <= 1'b1;

        state <= CLR_SYNC_BIT;
      end
      CLR_SYNC_BIT: begin
        SYNC_SETTINGS.SET <= 1'b0;

        ctl_flags <= dout;
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {15'h00, THERMO};

        state <= WAIT_1;
      end
      //////////////////////// synchronize ////////////////////////
      default: begin
      end
    endcase
  end


endmodule
