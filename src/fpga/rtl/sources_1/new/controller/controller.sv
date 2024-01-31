`timescale 1ns / 1ps
module controller #(
    parameter int DEPTH = 249
) (
    input var CLK,
    input var THERMO,
    output var FORCE_FAN,
    cpu_bus_if.ctl_port CPU_BUS,
    output var [63:0] ECAT_SYNC_TIME,
    output var SYNC_SET,
    output var OP_MODE,
    output var STM_GAIN_MODE,
    output var [15:0] CYCLE_M,
    output var [31:0] FREQ_DIV_M,
    output var [15:0] DELAY_M[DEPTH],
    output var [15:0] UPDATE_RATE_INTENSITY_S,
    output var [15:0] UPDATE_RATE_PHASE_S,
    output var FIXED_COMPLETION_STEPS,
    output var [15:0] COMPLETION_STEPS_INTENSITY,
    output var [15:0] COMPLETION_STEPS_PHASE,
    output var [15:0] CYCLE_STM,
    output var [31:0] FREQ_DIV_STM,
    output var [31:0] SOUND_SPEED,
    output var [15:0] STM_START_IDX,
    output var USE_STM_START_IDX,
    output var [15:0] STM_FINISH_IDX,
    output var USE_STM_FINISH_IDX,
    output var [7:0] DEBUG_OUTPUT_IDX
);

  `include "params.vh"

  logic bus_clk;
  logic ctl_ena;
  logic wea;
  logic [6:0] ctl_addr;
  logic [7:0] dly_addr;
  logic [15:0] cpu_data_in;
  logic [15:0] cpu_data_out;
  logic [6:0] addr;
  logic we;
  logic [15:0] din;
  logic [15:0] dout;

  logic dly_ena;
  logic [7:0] dly_cnt = 0;
  logic [7:0] dly_set = DEPTH - 2;
  logic [15:0] dly_dout;

  logic [15:0] ctl_flags;

  logic [63:0] ecat_sync_time;
  logic sync_set;

  logic [15:0] cycle_m;
  logic [31:0] freq_div_m;
  logic [15:0] delay_m[DEPTH];

  logic [15:0] update_rate_intensity_s;
  logic [15:0] update_rate_phase_s;
  logic [15:0] completion_steps_intensity;
  logic [15:0] completion_steps_phase;
  logic [15:0] ctl_flags_s;

  logic [15:0] cycle_stm;
  logic [31:0] freq_div_stm;
  logic [31:0] sound_speed;
  logic [15:0] stm_start_idx;
  logic [15:0] stm_finish_idx;

  logic [7:0] debug_output_idx;

  logic [2:0] ctl_page;

  assign ctl_page = CPU_BUS.BRAM_ADDR[10:8];
  assign bus_clk = CPU_BUS.BUS_CLK;
  assign ctl_ena = CPU_BUS.CTL_EN & (ctl_page == BRAM_SELECT_CONTROLLER_MAIN);
  assign wea = CPU_BUS.WE;
  assign ctl_addr = CPU_BUS.BRAM_ADDR[6:0];
  assign dly_ena = CPU_BUS.CTL_EN & (ctl_page == BRAM_SELECT_CONTROLLER_DELAY);
  assign dly_addr = CPU_BUS.BRAM_ADDR[7:0];
  assign cpu_data_in = CPU_BUS.DATA_IN;
  assign CPU_BUS.DATA_OUT = cpu_data_out;

  assign FORCE_FAN = ctl_flags[CTL_FLAG_FORCE_FAN_BIT] | ctl_flags[CTL_FLAG_FORCE_FAN_EX_BIT];
  assign OP_MODE = ctl_flags[CTL_FLAG_OP_MODE_BIT];
  assign STM_GAIN_MODE = ctl_flags[CTL_FLAG_STM_GAIN_MODE_BIT];
  assign USE_STM_START_IDX = ctl_flags[CTL_FLAG_USE_STM_START_IDX_BIT];
  assign USE_STM_FINISH_IDX = ctl_flags[CTL_FLAG_USE_STM_FINISH_IDX_BIT];

  assign ECAT_SYNC_TIME = ecat_sync_time;
  assign SYNC_SET = sync_set;
  assign CYCLE_M = cycle_m;
  assign FREQ_DIV_M = freq_div_m;
  assign UPDATE_RATE_INTENSITY_S = update_rate_intensity_s;
  assign UPDATE_RATE_PHASE_S = update_rate_phase_s;
  assign FIXED_COMPLETION_STEPS = ctl_flags_s[SILENCER_CTL_FLAG_FIXED_COMPLETION_STEPS];
  assign COMPLETION_STEPS_INTENSITY = completion_steps_intensity;
  assign COMPLETION_STEPS_PHASE = completion_steps_phase;
  assign CYCLE_STM = cycle_stm;
  assign FREQ_DIV_STM = freq_div_stm;
  assign SOUND_SPEED = sound_speed;
  assign STM_START_IDX = stm_start_idx;
  assign STM_FINISH_IDX = stm_finish_idx;
  assign DEBUG_OUTPUT_IDX = debug_output_idx;

  for (genvar i = 0; i < DEPTH; i++) begin : gen_cycle_delay
    assign DELAY_M[i] = delay_m[i];
  end

  BRAM_CONTROLLER ctl_bram (
      .clka (bus_clk),
      .ena  (ctl_ena),
      .wea  (wea),
      .addra(ctl_addr),
      .dina (cpu_data_in),
      .douta(cpu_data_out),
      .clkb (CLK),
      .web  (we),
      .addrb(addr),
      .dinb (din),
      .doutb(dout)
  );

  BRAM_DELAY dly_bram (
      .clka (bus_clk),
      .ena  (dly_ena),
      .wea  (wea),
      .addra(dly_addr),
      .dina (cpu_data_in),
      .douta(),
      .clkb (CLK),
      .web  (1'b0),
      .addrb(dly_cnt),
      .dinb (),
      .doutb(dly_dout)
  );

  typedef enum logic [4:0] {
    REQ_WR_VER_MINOR,
    REQ_WR_VER,
    WAIT_WR_VER_0_REQ_RD_CTL_FLAG,
    WR_VER_MINOR_WAIT_RD_CTL_FLAG_0,
    WR_VER_WAIT_RD_CTL_FLAG_1,

    RD_CTL_FLAG_REQ_RD_MOD_FREQ_DIV_0,
    WR_FPGA_STATE_REQ_RD_MOD_FREQ_DIV_1,
    RD_MOD_CYCLE_REQ_RD_DEBUG_OUTPUT,
    RD_MOD_FREQ_DIV_0_REQ_RD_SILENCER_UPDATE_RATE_INTENSITY,
    RD_MOD_FREQ_DIV_1_REQ_RD_SILENCER_UPDATE_RATE_PHASE,
    RD_DEBUG_OUTPUT_REQ_RD_SILENCER_COMPLETION_STEPS_INTENSITY,
    RD_SILENCER_UPDATE_RATE_INTENSITY_REQ_RD_SILENCER_COMPLETION_STEPS_PHASE,
    RD_SILENCER_UPDATE_RATE_PHASE_REQ_RD_SILENCER_CTL_FLAG,
    RD_SILENCER_COMPLETION_STEPS_INTENSITY_REQ_RD_STM_CYCLE,
    RD_SILENCER_COMPLETION_STEPS_PHASE_REQ_RD_STM_FREQ_DIV_0,
    RD_SILENCER_CTL_FLAG_REQ_RD_STM_FREQ_DIV_1,
    RD_STM_CYCLE_REQ_RD_SOUND_SPEED_0,
    RD_STM_FREQ_DIV_0_REQ_RD_SOUND_SPEED_1,
    RD_STM_FREQ_DIV_1_REQ_RD_STM_START_IDX,
    RD_SOUND_SPEED_0_REQ_RD_STM_FINISH_IDX,
    RD_SOUND_SPEED_1_REQ_RD_CTL_FLAG,
    RD_STM_START_IDX_REQ_WR_FPGA_STATE,
    RD_STM_FINISH_IDX_REQ_RD_MOD_CYCLE,

    REQ_RD_EC_SYNC_TIME_0,
    REQ_RD_EC_SYNC_TIME_1,
    REQ_RD_EC_SYNC_TIME_2,
    REQ_RD_EC_SYNC_TIME_3_RD_EC_SYNC_TIME_0,
    RD_EC_SYNC_TIME_1,
    RD_EC_SYNC_TIME_2,
    RD_EC_SYNC_TIME_3,
    CLR_SYNC_BIT
  } state_t;

  state_t state = REQ_WR_VER_MINOR;

  always_ff @(posedge CLK) begin
    case (state)
      ////////////////////////// initial //////////////////////////
      REQ_WR_VER_MINOR: begin
        we <= 1'b1;

        din <= {8'd0, VERSION_NUM_MINOR};
        addr <= ADDR_VERSION_NUM_MINOR;

        state <= REQ_WR_VER;
      end
      REQ_WR_VER: begin
        din   <= {8'h00, VERSION_NUM};
        addr  <= ADDR_VERSION_NUM_MAJOR;

        state <= WAIT_WR_VER_0_REQ_RD_CTL_FLAG;
      end
      WAIT_WR_VER_0_REQ_RD_CTL_FLAG: begin
        we <= 1'b0;
        addr <= ADDR_CTL_FLAG;

        state <= WR_VER_MINOR_WAIT_RD_CTL_FLAG_0;
      end
      WR_VER_MINOR_WAIT_RD_CTL_FLAG_0: begin
        state <= WR_VER_WAIT_RD_CTL_FLAG_1;
      end
      WR_VER_WAIT_RD_CTL_FLAG_1: begin
        state <= RD_CTL_FLAG_REQ_RD_MOD_FREQ_DIV_0;
      end
      ////////////////////////// initial //////////////////////////

      //////////////////////////// run ////////////////////////////
      RD_CTL_FLAG_REQ_RD_MOD_FREQ_DIV_0: begin
        ctl_flags <= dout;
        if (ctl_flags[CTL_FLAG_SYNC_BIT]) begin
          we <= 1'b1;
          addr <= ADDR_CTL_FLAG;
          din <= ctl_flags & ~(1 << CTL_FLAG_SYNC_BIT);

          state <= REQ_RD_EC_SYNC_TIME_0;
        end else begin
          addr  <= ADDR_MOD_FREQ_DIV_0;

          state <= WR_FPGA_STATE_REQ_RD_MOD_FREQ_DIV_1;
        end
      end
      WR_FPGA_STATE_REQ_RD_MOD_FREQ_DIV_1: begin
        addr  <= ADDR_MOD_FREQ_DIV_1;

        state <= RD_MOD_CYCLE_REQ_RD_DEBUG_OUTPUT;
      end
      RD_MOD_CYCLE_REQ_RD_DEBUG_OUTPUT: begin
        addr <= ADDR_DEBUG_OUT_IDX;

        cycle_m <= dout;

        state <= RD_MOD_FREQ_DIV_0_REQ_RD_SILENCER_UPDATE_RATE_INTENSITY;
      end
      RD_MOD_FREQ_DIV_0_REQ_RD_SILENCER_UPDATE_RATE_INTENSITY: begin
        addr <= ADDR_SILENCER_UPDATE_RATE_INTENSITY;

        freq_div_m[15:0] <= dout;

        state <= RD_MOD_FREQ_DIV_1_REQ_RD_SILENCER_UPDATE_RATE_PHASE;
      end
      RD_MOD_FREQ_DIV_1_REQ_RD_SILENCER_UPDATE_RATE_PHASE: begin
        addr <= ADDR_SILENCER_UPDATE_RATE_PHASE;

        freq_div_m[31:16] <= dout;

        state <= RD_DEBUG_OUTPUT_REQ_RD_SILENCER_COMPLETION_STEPS_INTENSITY;
      end
      RD_DEBUG_OUTPUT_REQ_RD_SILENCER_COMPLETION_STEPS_INTENSITY: begin
        addr <= ADDR_SILENCER_COMPLETION_STEPS_INTENSITY;

        debug_output_idx <= dout[7:0];

        state <= RD_SILENCER_UPDATE_RATE_INTENSITY_REQ_RD_SILENCER_COMPLETION_STEPS_PHASE;
      end
      RD_SILENCER_UPDATE_RATE_INTENSITY_REQ_RD_SILENCER_COMPLETION_STEPS_PHASE: begin
        addr <= ADDR_SILENCER_COMPLETION_STEPS_PHASE;

        update_rate_intensity_s <= dout;

        state <= RD_SILENCER_UPDATE_RATE_PHASE_REQ_RD_SILENCER_CTL_FLAG;
      end
      RD_SILENCER_UPDATE_RATE_PHASE_REQ_RD_SILENCER_CTL_FLAG: begin
        addr <= ADDR_SILENCER_CTL_FLAG;

        update_rate_phase_s <= dout;

        state <= RD_SILENCER_COMPLETION_STEPS_INTENSITY_REQ_RD_STM_CYCLE;
      end
      RD_SILENCER_COMPLETION_STEPS_INTENSITY_REQ_RD_STM_CYCLE: begin
        addr <= ADDR_STM_CYCLE;

        completion_steps_intensity <= dout;

        state <= RD_SILENCER_COMPLETION_STEPS_PHASE_REQ_RD_STM_FREQ_DIV_0;
      end
      RD_SILENCER_COMPLETION_STEPS_PHASE_REQ_RD_STM_FREQ_DIV_0: begin
        addr <= ADDR_STM_FREQ_DIV_0;

        completion_steps_phase <= dout;

        state <= RD_SILENCER_CTL_FLAG_REQ_RD_STM_FREQ_DIV_1;
      end
      RD_SILENCER_CTL_FLAG_REQ_RD_STM_FREQ_DIV_1: begin
        addr <= ADDR_STM_FREQ_DIV_1;

        ctl_flags_s <= dout;

        state <= RD_STM_CYCLE_REQ_RD_SOUND_SPEED_0;
      end
      RD_STM_CYCLE_REQ_RD_SOUND_SPEED_0: begin
        addr <= ADDR_SOUND_SPEED_0;

        cycle_stm <= dout;

        state <= RD_STM_FREQ_DIV_0_REQ_RD_SOUND_SPEED_1;
      end
      RD_STM_FREQ_DIV_0_REQ_RD_SOUND_SPEED_1: begin
        addr <= ADDR_SOUND_SPEED_1;

        freq_div_stm[15:0] <= dout;

        state <= RD_STM_FREQ_DIV_1_REQ_RD_STM_START_IDX;
      end
      RD_STM_FREQ_DIV_1_REQ_RD_STM_START_IDX: begin
        addr <= ADDR_STM_START_IDX;

        freq_div_stm[31:16] <= dout;

        state <= RD_SOUND_SPEED_0_REQ_RD_STM_FINISH_IDX;
      end
      RD_SOUND_SPEED_0_REQ_RD_STM_FINISH_IDX: begin
        addr <= ADDR_STM_FINISH_IDX;

        sound_speed[15:0] <= dout;

        state <= RD_SOUND_SPEED_1_REQ_RD_CTL_FLAG;
      end
      RD_SOUND_SPEED_1_REQ_RD_CTL_FLAG: begin
        addr <= ADDR_CTL_FLAG;

        sound_speed[31:16] <= dout;

        state <= RD_STM_START_IDX_REQ_WR_FPGA_STATE;
      end
      RD_STM_START_IDX_REQ_WR_FPGA_STATE: begin
        we <= 1'b1;
        addr <= ADDR_FPGA_STATE;
        din <= {15'h00, THERMO};
        stm_start_idx <= dout;

        state <= RD_STM_FINISH_IDX_REQ_RD_MOD_CYCLE;
      end
      RD_STM_FINISH_IDX_REQ_RD_MOD_CYCLE: begin
        we <= 1'b0;
        addr <= ADDR_MOD_CYCLE;

        stm_finish_idx <= dout;

        state <= RD_CTL_FLAG_REQ_RD_MOD_FREQ_DIV_0;
      end
      //////////////////////////// run ////////////////////////////

      //////////////////////// synchronize ////////////////////////
      REQ_RD_EC_SYNC_TIME_0: begin
        we <= 1'b0;

        addr <= ADDR_EC_SYNC_TIME_0;

        state <= REQ_RD_EC_SYNC_TIME_1;
      end
      REQ_RD_EC_SYNC_TIME_1: begin
        addr  <= ADDR_EC_SYNC_TIME_1;

        state <= REQ_RD_EC_SYNC_TIME_2;
      end
      REQ_RD_EC_SYNC_TIME_2: begin
        addr  <= ADDR_EC_SYNC_TIME_2;

        state <= REQ_RD_EC_SYNC_TIME_3_RD_EC_SYNC_TIME_0;
      end
      REQ_RD_EC_SYNC_TIME_3_RD_EC_SYNC_TIME_0: begin
        addr <= ADDR_EC_SYNC_TIME_3;

        ecat_sync_time[15:0] <= dout;

        state <= RD_EC_SYNC_TIME_1;
      end
      RD_EC_SYNC_TIME_1: begin
        addr <= ADDR_CTL_FLAG;

        ecat_sync_time[31:16] <= dout;

        state <= RD_EC_SYNC_TIME_2;
      end
      RD_EC_SYNC_TIME_2: begin
        ecat_sync_time[47:32] <= dout;

        state <= RD_EC_SYNC_TIME_3;
      end
      RD_EC_SYNC_TIME_3: begin
        ecat_sync_time[63:48] <= dout;

        sync_set <= 1'b1;

        state <= CLR_SYNC_BIT;
      end
      CLR_SYNC_BIT: begin
        ctl_flags <= dout;

        sync_set <= 1'b0;

        state <= RD_CTL_FLAG_REQ_RD_MOD_FREQ_DIV_0;
      end
      //////////////////////// synchronize ////////////////////////

      default: begin
      end
    endcase
  end

  always_ff @(posedge CLK) begin
    dly_cnt <= (dly_cnt == DEPTH - 1) ? 0 : dly_cnt + 1;
    dly_set <= (dly_set == DEPTH - 1) ? 0 : dly_set + 1;
    delay_m[dly_set] <= dly_dout;
  end

endmodule
