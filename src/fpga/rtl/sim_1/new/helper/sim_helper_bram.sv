`timescale 1ns / 1ps
module sim_helper_bram #(
    parameter int DEPTH = 249
) ();

  // CPU
  logic [15:0] bram_addr;
  logic [16:0] CPU_ADDR;
  assign CPU_ADDR = {bram_addr, 1'b1};
  logic [15:0] CPU_DATA;
  logic CPU_CKIO;
  logic CPU_CS1_N;
  logic CPU_WE0_N;
  logic [15:0] CPU_DATA_READ;
  logic [15:0] bus_data_reg = 16'bzzzzzzzzzzzzzzzz;
  assign CPU_DATA = bus_data_reg;

  memory_bus_if memory_bus ();
  assign memory_bus.BUS_CLK = CPU_CKIO;
  assign memory_bus.EN = ~CPU_CS1_N;
  assign memory_bus.WE = ~CPU_WE0_N;
  assign memory_bus.BRAM_SELECT = CPU_ADDR[16:15];
  assign memory_bus.BRAM_ADDR = CPU_ADDR[14:1];
  assign memory_bus.DATA_IN = CPU_DATA;

  task automatic bram_write(input logic [1:0] select, input logic [13:0] addr,
                            input logic [15:0] data_in);
    @(posedge CPU_CKIO);
    bram_addr <= {select, addr};
    CPU_CS1_N <= 0;
    bus_data_reg <= data_in;
    @(posedge CPU_CKIO);
    @(negedge CPU_CKIO);

    CPU_WE0_N <= 0;
    repeat (2) @(posedge CPU_CKIO);

    @(negedge CPU_CKIO);
    CPU_WE0_N <= 1;
  endtask

  task automatic write_cnt(logic [7:0] addr, logic [15:0] data);
    bram_write(params::BRAM_SELECT_CONTROLLER, {2'b00, params::BRAM_CNT_SEL_MAIN, addr}, data);
  endtask

  task automatic write_phase_filter(logic [7:0] data[DEPTH]);
    automatic int i;
    for (i = 0; i < DEPTH / 2; i++) begin
      bram_write(params::BRAM_SELECT_CONTROLLER, {2'b00, params::BRAM_CNT_SEL_FILTER, 1'b0, i[6:0]},
                 {data[2*i+1], data[2*i]});
    end
    bram_write(params::BRAM_SELECT_CONTROLLER, {2'b00, params::BRAM_CNT_SEL_FILTER, 1'b0, i[6:0]}, {
               8'h00, data[DEPTH-1]});
  endtask

  task automatic write_duty_table(input logic [7:0] value[65536]);
    logic page = 0;
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_PULSE_WIDTH_ENCODER_TABLE_WR_PAGE, {
               15'h0000, page});
    for (int i = 0; i < 32768; i++) begin
      bram_write(params::BRAM_SELECT_DUTY_TABLE, i[13:0], {value[2*i+1], value[2*i]});
      if (i[13:0] === (1 << 14) - 1) begin
        page = page + 1;
        bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_PULSE_WIDTH_ENCODER_TABLE_WR_PAGE, {
                   15'h0000, page});
      end
    end
  endtask

  task automatic write_mod(input logic segment, input logic [7:0] mod_data[], int cnt);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_MOD_MEM_WR_SEGMENT, {15'h000, segment});
    for (int i = 0; i < (cnt + 1) / 2; i++) begin
      bram_write(params::BRAM_SELECT_MOD, i, {mod_data[2*i+1], mod_data[2*i]});
    end
  endtask

  task automatic write_stm_gain_intensity_phase(input logic segment,
                                                input logic [7:0] intensity[][DEPTH],
                                                input logic [7:0] phase[][DEPTH], int cnt);
    logic [5:0] offset = 0;
    logic [3:0] page = 0;
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_MEM_WR_SEGMENT, {15'h000, segment});
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_MEM_WR_PAGE, {12'h000, page});
    for (int j = 0; j < cnt; j++) begin
      for (int i = 0; i < DEPTH; i++) begin
        bram_write(params::BRAM_SELECT_STM, {2'b00, offset, i[7:0]}, {intensity[j][i], phase[j][i]
                   });
      end
      if (offset == 63) begin
        page = page + 1;
        bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_MEM_WR_PAGE, {12'h000, page});
        offset = 0;
      end else begin
        offset = offset + 1;
      end
    end
  endtask

  task automatic write_stm_focus(input logic segment, input logic signed [17:0] x[],
                                 input logic signed [17:0] y[], input logic signed [17:0] z[],
                                 input logic [7:0] intensity[], int cnt);
    logic [ 3:0] page = 0;
    logic [13:0] addr = 0;
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_MEM_WR_SEGMENT, {15'h000, segment});
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_MEM_WR_PAGE, {12'h000, page});
    for (int i = 0; i < cnt; i++) begin
      addr = i << 2;
      bram_write(params::BRAM_SELECT_STM, addr, x[i][15:0]);
      bram_write(params::BRAM_SELECT_STM, addr + 1, {y[i][13:0], x[i][17:16]});
      bram_write(params::BRAM_SELECT_STM, addr + 2, {z[i][11:0], y[i][17:14]});
      bram_write(params::BRAM_SELECT_STM, addr + 3, {2'd0, intensity[i], z[i][17:12]});
      if (i % 4096 == 4095) begin
        page = page + 1;
        bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_MEM_WR_PAGE, {12'h000, page});
      end
    end
  endtask

  task automatic write_mod_settings(input settings::mod_settings_t settings);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_MOD_REQ_RD_SEGMENT,
               settings.REQ_RD_SEGMENT);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_MOD_CYCLE_0, settings.CYCLE_0);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_MOD_FREQ_DIV_0_0,
               settings.FREQ_DIV_0[15:0]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_MOD_FREQ_DIV_0_1,
               settings.FREQ_DIV_0[31:16]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_MOD_CYCLE_1, settings.CYCLE_1);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_MOD_FREQ_DIV_1_0,
               settings.FREQ_DIV_1[15:0]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_MOD_FREQ_DIV_1_1,
               settings.FREQ_DIV_1[31:16]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_MOD_REP_0_0, settings.REP_0[15:0]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_MOD_REP_0_1, settings.REP_0[31:16]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_MOD_REP_1_0, settings.REP_1[15:0]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_MOD_REP_1_1, settings.REP_1[31:16]);
  endtask

  task automatic write_stm_settings(input settings::stm_settings_t settings);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_MODE_0, settings.MODE_0);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_MODE_1, settings.MODE_1);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_REQ_RD_SEGMENT,
               settings.REQ_RD_SEGMENT);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_CYCLE_0, settings.CYCLE_0);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_FREQ_DIV_0_0,
               settings.FREQ_DIV_0[15:0]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_FREQ_DIV_0_1,
               settings.FREQ_DIV_0[31:16]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_CYCLE_1, settings.CYCLE_1);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_FREQ_DIV_1_0,
               settings.FREQ_DIV_1[15:0]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_FREQ_DIV_1_1,
               settings.FREQ_DIV_1[31:16]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_REP_0_0, settings.REP_0[15:0]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_REP_0_1, settings.REP_0[31:16]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_REP_1_0, settings.REP_1[15:0]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_REP_1_1, settings.REP_1[31:16]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_SOUND_SPEED_0_0,
               settings.SOUND_SPEED_0[15:0]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_SOUND_SPEED_0_1,
               settings.SOUND_SPEED_0[31:16]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_SOUND_SPEED_1_0,
               settings.SOUND_SPEED_1[15:0]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_SOUND_SPEED_1_1,
               settings.SOUND_SPEED_1[31:16]);
  endtask

  task automatic write_silencer_settings(input settings::silencer_settings_t settings);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_SILENCER_MODE, settings.MODE);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_SILENCER_UPDATE_RATE_INTENSITY,
               settings.UPDATE_RATE_INTENSITY);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_SILENCER_UPDATE_RATE_PHASE,
               settings.UPDATE_RATE_PHASE);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_SILENCER_COMPLETION_STEPS_INTENSITY,
               settings.COMPLETION_STEPS_INTENSITY);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_SILENCER_COMPLETION_STEPS_PHASE,
               settings.COMPLETION_STEPS_PHASE);
  endtask

  task automatic write_sync_settings(input settings::sync_settings_t settings);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_ECAT_SYNC_TIME_0,
               settings.ECAT_SYNC_TIME[15:0]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_ECAT_SYNC_TIME_1,
               settings.ECAT_SYNC_TIME[31:16]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_ECAT_SYNC_TIME_2,
               settings.ECAT_SYNC_TIME[47:32]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_ECAT_SYNC_TIME_3,
               settings.ECAT_SYNC_TIME[63:48]);
  endtask

  task automatic write_pulse_width_encoder_settings(
      input settings::pulse_width_encoder_settings_t settings);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_PULSE_WIDTH_ENCODER_FULL_WIDTH_START,
               settings.FULL_WIDTH_START);
  endtask

  task automatic write_debug_settings(input settings::debug_settings_t settings);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_DEBUG_OUT_IDX, settings.OUTPUT_IDX);
  endtask

  initial begin
    CPU_WE0_N = 1'b1;
    bram_addr = 1'b0;
    CPU_CKIO  = 1'b0;
  end

  //  always #6.65 CPU_CKIO = ~CPU_CKIO;
  always #0.1 CPU_CKIO = ~CPU_CKIO;  // to speed up simulation

endmodule
