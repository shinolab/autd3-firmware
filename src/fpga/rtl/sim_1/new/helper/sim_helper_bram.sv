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
  logic CPU_CN;
  logic CPU_WE0_N;
  logic [15:0] CPU_DATA_READ;
  logic [15:0] bus_data_reg = 16'bzzzzzzzzzzzzzzzz;
  assign CPU_DATA = bus_data_reg;

  memory_bus_if memory_bus ();
  assign memory_bus.BUS_CLK = CPU_CKIO;
  assign memory_bus.EN = ~CPU_CN;
  assign memory_bus.WE = ~CPU_WE0_N;
  assign memory_bus.BRAM_SELECT = CPU_ADDR[16:15];
  assign memory_bus.BRAM_ADDR = CPU_ADDR[14:1];
  assign memory_bus.DATA_IN = CPU_DATA;

  task automatic bram_write(input logic [1:0] select, input logic [13:0] addr,
                            input logic [15:0] data_in);
    @(posedge CPU_CKIO);
    bram_addr <= {select, addr};
    CPU_CN <= 0;
    bus_data_reg <= data_in;
    @(posedge CPU_CKIO);
    @(negedge CPU_CKIO);

    CPU_WE0_N <= 0;
    repeat (2) @(posedge CPU_CKIO);

    @(negedge CPU_CKIO);
    CPU_WE0_N <= 1;
  endtask

  task automatic config_clk(logic [37:0] CLKOUT0_FRAC, logic [37:0] DIVCLK,
                            logic [37:0] CLKFBOUT_FRAC, logic [39:0] LOCK,
                            logic [9:0] DIGITAL_FILT);

    logic [38:0] rom[32] = '{32{'0}};

    logic [37:0] CLKOUT_UNUSED = 38'h0000400041;

    rom[0] = {7'h28, 16'h0000, 16'hFFFF};

    rom[1] = {7'h09, 16'h8000, CLKOUT0_FRAC[31:16]};
    rom[2] = {7'h08, 16'h1000, CLKOUT0_FRAC[15:0]};

    rom[3] = {7'h0A, 16'h1000, CLKOUT_UNUSED[15:0]};
    rom[4] = {7'h0B, 16'hFC00, CLKOUT_UNUSED[31:16]};

    rom[5] = {7'h0C, 16'h1000, CLKOUT_UNUSED[15:0]};
    rom[6] = {7'h0D, 16'hFC00, CLKOUT_UNUSED[31:16]};

    rom[7] = {7'h0E, 16'h1000, CLKOUT_UNUSED[15:0]};
    rom[8] = {7'h0F, 16'hFC00, CLKOUT_UNUSED[31:16]};

    rom[9] = {7'h10, 16'h1000, CLKOUT_UNUSED[15:0]};
    rom[10] = {7'h11, 16'hFC00, CLKOUT_UNUSED[31:16]};

    rom[11] = {7'h06, 16'h1000, CLKOUT_UNUSED[15:0]};
    rom[12] = {7'h07, 16'hC000, CLKOUT_UNUSED[31:30], CLKOUT0_FRAC[35:32], CLKOUT_UNUSED[25:16]};

    rom[13] = {7'h12, 16'h1000, 16'h0000};
    rom[14] = {7'h13, 16'hC000, CLKOUT_UNUSED[31:30], CLKFBOUT_FRAC[35:32], CLKOUT_UNUSED[25:16]};

    rom[15] = {7'h16, 16'hC000, {2'h0, DIVCLK[23:22], DIVCLK[11:0]}};

    rom[16] = {7'h14, 16'h1000, CLKFBOUT_FRAC[15:0]};
    rom[17] = {7'h15, 16'h8000, CLKFBOUT_FRAC[31:16]};

    rom[18] = {7'h18, 16'hFC00, {6'h00, LOCK[29:20]}};
    rom[19] = {7'h19, 16'h8000, {1'b0, LOCK[34:30], LOCK[9:0]}};
    rom[20] = {7'h1A, 16'h8000, {1'b0, LOCK[39:35], LOCK[19:10]}};

    rom[21] = {
      7'h4E, 16'h66FF, DIGITAL_FILT[9], 2'h0, DIGITAL_FILT[8:7], 2'h0, DIGITAL_FILT[6], 8'h00
    };
    rom[22] = {
      7'h4F,
      16'h666F,
      DIGITAL_FILT[5],
      2'h0,
      DIGITAL_FILT[4:3],
      2'h0,
      DIGITAL_FILT[2:1],
      2'h0,
      DIGITAL_FILT[0],
      4'h0
    };

    rom[31] = 1;

    for (int i = 0; i < 32; i++) begin
      bram_write(params::BRAM_SELECT_CONTROLLER, {
                 2'b00, params::BRAM_CNT_SELECT_CLOCK, 1'b0, i[4:0], 2'b00}, rom[i][15:0]);
      bram_write(params::BRAM_SELECT_CONTROLLER, {
                 2'b00, params::BRAM_CNT_SELECT_CLOCK, 1'b0, i[4:0], 2'b01}, rom[i][31:16]);
      bram_write(params::BRAM_SELECT_CONTROLLER, {
                 2'b00, params::BRAM_CNT_SELECT_CLOCK, 1'b0, i[4:0], 2'b10}, {9'd0, rom[i][38:32]});
    end

  endtask

  task automatic write_cnt(logic [7:0] addr, logic [15:0] data);
    bram_write(params::BRAM_SELECT_CONTROLLER, {2'b00, params::BRAM_CNT_SELECT_MAIN, addr}, data);
  endtask

  task automatic write_pwe_table(input logic [7:0] value[256]);
    for (int i = 0; i < 128; i++) begin
      bram_write(params::BRAM_SELECT_PWE_TABLE, i[6:0], {value[2*i+1], value[2*i]});
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

  task automatic write_stm_focus(input logic segment, input logic signed [17:0] x[][8],
                                 input logic signed [17:0] y[][8], input logic signed [17:0] z[][8],
                                 input logic [7:0] intensity_and_offsets[][8], int cnt, int n);
    logic [ 3:0] page = 0;
    logic [13:0] base_addr = 0;
    logic [13:0] addr = 0;
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_MEM_WR_SEGMENT, {15'h000, segment});
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_MEM_WR_PAGE, {12'h000, page});
    for (int i = 0; i < cnt; i++) begin
      base_addr = i << 5;
      for (int j = 0; j < n; j++) begin
        addr = base_addr + 4 * j;
        bram_write(params::BRAM_SELECT_STM, addr, x[i][j][15:0]);
        bram_write(params::BRAM_SELECT_STM, addr + 1, {y[i][j][13:0], x[i][j][17:16]});
        bram_write(params::BRAM_SELECT_STM, addr + 2, {z[i][j][11:0], y[i][j][17:14]});
        bram_write(params::BRAM_SELECT_STM, addr + 3, {
                   2'd0, intensity_and_offsets[i][j], z[i][j][17:12]});
      end
      if (i % 512 == 511) begin
        page = page + 1;
        bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_MEM_WR_PAGE, {12'h000, page});
      end
    end
  endtask

  task automatic write_mod_settings(input settings::mod_settings_t settings);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_MOD_REQ_RD_SEGMENT,
               settings.REQ_RD_SEGMENT);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_MOD_TRANSITION_MODE,
               settings.TRANSITION_MODE);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_MOD_TRANSITION_VALUE_0,
               settings.TRANSITION_VALUE[15:0]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_MOD_TRANSITION_VALUE_1,
               settings.TRANSITION_VALUE[31:16]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_MOD_TRANSITION_VALUE_2,
               settings.TRANSITION_VALUE[47:32]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_MOD_TRANSITION_VALUE_3,
               settings.TRANSITION_VALUE[63:48]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_MOD_CYCLE0, settings.CYCLE[0]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_MOD_FREQ_DIV0, settings.FREQ_DIV[0]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_MOD_CYCLE1, settings.CYCLE[1]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_MOD_FREQ_DIV1, settings.FREQ_DIV[1]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_MOD_REP0, settings.REP[0]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_MOD_REP1, settings.REP[1]);
  endtask

  task automatic write_stm_settings(input settings::stm_settings_t settings);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_MODE0, settings.MODE[0]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_MODE1, settings.MODE[1]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_REQ_RD_SEGMENT,
               settings.REQ_RD_SEGMENT);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_TRANSITION_MODE,
               settings.TRANSITION_MODE);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_TRANSITION_VALUE_0,
               settings.TRANSITION_VALUE[15:0]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_TRANSITION_VALUE_1,
               settings.TRANSITION_VALUE[31:16]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_TRANSITION_VALUE_2,
               settings.TRANSITION_VALUE[47:32]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_TRANSITION_VALUE_3,
               settings.TRANSITION_VALUE[63:48]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_CYCLE0, settings.CYCLE[0]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_FREQ_DIV0, settings.FREQ_DIV[0]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_CYCLE1, settings.CYCLE[1]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_FREQ_DIV1, settings.FREQ_DIV[1]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_REP0, settings.REP[0]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_REP1, settings.REP[1]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_SOUND_SPEED0,
               settings.SOUND_SPEED[0]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_STM_SOUND_SPEED1,
               settings.SOUND_SPEED[1]);
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

  task automatic write_debug_settings(input settings::debug_settings_t settings);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_DEBUG_TYPE0, settings.TYPE[0]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_DEBUG_TYPE1, settings.TYPE[1]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_DEBUG_TYPE2, settings.TYPE[2]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_DEBUG_TYPE3, settings.TYPE[3]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_DEBUG_VALUE0, settings.VALUE[0]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_DEBUG_VALUE1, settings.VALUE[1]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_DEBUG_VALUE2, settings.VALUE[2]);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_DEBUG_VALUE3, settings.VALUE[3]);
  endtask

  initial begin
    CPU_WE0_N = 1'b1;
    bram_addr = 1'b0;
    CPU_CKIO  = 1'b0;
  end

  //  always #6.65 CPU_CKIO = ~CPU_CKIO;
  always #0.1 CPU_CKIO = ~CPU_CKIO;  // to speed up simulation

endmodule
