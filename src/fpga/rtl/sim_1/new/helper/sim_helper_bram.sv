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

  task automatic write_cnt(logic [4:0] sel, logic [7:0] addr, logic [15:0] data);
    bram_write(params::BRAM_SELECT_CONTROLLER, {2'b00, 1'b0, sel, addr}, data);
  endtask

  task automatic write_duty_table(input logic [7:0] value[65536]);
    logic [1:0] page = 0;
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_DUTY_TABLE_WR_PAGE, {14'h0000, page});
    for (int i = 0; i < 32768; i++) begin
      bram_write(params::BRAM_SELECT_CONTROLLER, {2'b00, 1'b1, i[12:0]}, {value[2*i+1], value[2*i]
                 });
      if (i % 8192 == 8191) begin
        page = page + 1;
        bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_DUTY_TABLE_WR_PAGE, {14'h0000, page
                   });
      end
    end
  endtask

  task automatic write_mod(input logic segment, input logic [7:0] mod_data[], int cnt);
    bram_write(params::BRAM_SELECT_CONTROLLER, params::ADDR_MOD_MEM_WR_SEGMENT, {15'h000, segment});
    for (int i = 0; i < (cnt + 1) / 2; i++) begin
      bram_write(params::BRAM_SELECT_MOD, i, {mod_data[2*i+1], mod_data[2*i]});
    end
  endtask

  task automatic write_intensity_phase(input logic segment, logic [7:0] intensity[DEPTH],
                                       logic [7:0] phase[DEPTH]);
    for (int i = 0; i < DEPTH; i++) begin
      bram_write(params::BRAM_SELECT_NORMAL, {7'h00, segment, i[7:0]}, {intensity[i], phase[i]});
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

  task automatic write_stm_focus(input logic segment, input logic [17:0] x[],
                                 input logic [17:0] y[], input logic [17:0] z[],
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

  // task automatic set_ctl_reg(logic force_fan, logic sync);
  //   automatic
  //   logic [15:0]
  //   ctl_reg = (sync << CTL_FLAG_SYNC_BIT) | (force_fan << CTL_FLAG_FORCE_FAN_BIT);
  //   bram_write(BRAM_SELECT_CONTROLLER, ADDR_CTL_FLAG, ctl_reg);
  // endtask

  // task automatic write_ecat_sync_time(logic [63:0] ecat_sync_time);
  //   bram_write(BRAM_SELECT_CONTROLLER, ADDR_EC_SYNC_TIME_0, ecat_sync_time[15:0]);
  //   bram_write(BRAM_SELECT_CONTROLLER, ADDR_EC_SYNC_TIME_1, ecat_sync_time[31:16]);
  //   bram_write(BRAM_SELECT_CONTROLLER, ADDR_EC_SYNC_TIME_2, ecat_sync_time[47:32]);
  //   bram_write(BRAM_SELECT_CONTROLLER, ADDR_EC_SYNC_TIME_3, ecat_sync_time[63:48]);
  // endtask

  // task automatic write_mod_cycle(logic [15:0] mod_cycle);
  //   bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_CYCLE, mod_cycle);
  // endtask

  // task automatic write_mod_freq_div(logic [31:0] mod_freq_div);
  //   bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_FREQ_DIV_0, mod_freq_div[15:0]);
  //   bram_write(BRAM_SELECT_CONTROLLER, ADDR_MOD_FREQ_DIV_1, mod_freq_div[31:16]);
  // endtask

  // task automatic write_silencer_update_rate(logic [15:0] intensity, logic [15:0] phase);
  //   bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_UPDATE_RATE_INTENSITY, intensity);
  //   bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_UPDATE_RATE_PHASE, phase);
  // endtask

  // task automatic write_silencer_completion_steps(logic [15:0] intensity, logic [15:0] phase);
  //   bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_COMPLETION_STEPS_INTENSITY, intensity);
  //   bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_COMPLETION_STEPS_PHASE, phase);
  // endtask

  // task automatic set_silencer_ctl_flag(logic fixed_completion_step);
  //   automatic
  //   logic [15:0]
  //   ctl_reg = fixed_completion_step << SILENCER_CTL_FLAG_FIXED_COMPLETION_STEPS;
  //   bram_write(BRAM_SELECT_CONTROLLER, ADDR_SILENCER_CTL_FLAG, ctl_reg);
  // endtask

  // task automatic write_stm_cycle(logic [15:0] stm_cycle);
  //   bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_CYCLE, stm_cycle);
  // endtask

  // task automatic write_stm_freq_div(logic [31:0] stm_freq_div);
  //   bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_FREQ_DIV_0, stm_freq_div[15:0]);
  //   bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_FREQ_DIV_1, stm_freq_div[31:16]);
  // endtask

  // task automatic write_sound_speed(logic [31:0] sound_speed);
  //   bram_write(BRAM_SELECT_CONTROLLER, ADDR_SOUND_SPEED_0, sound_speed[15:0]);
  //   bram_write(BRAM_SELECT_CONTROLLER, ADDR_SOUND_SPEED_1, sound_speed[31:16]);
  // endtask

  // task automatic write_stm_start_idx(logic [15:0] stm_start_idx);
  //   bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_START_IDX, stm_start_idx);
  // endtask

  // task automatic write_stm_finish_idx(logic [15:0] stm_finish_idx);
  //   bram_write(BRAM_SELECT_CONTROLLER, ADDR_STM_FINISH_IDX, stm_finish_idx);
  // endtask


  initial begin
    CPU_WE0_N = 1'b1;
    bram_addr = 1'b0;
    CPU_CKIO  = 1'b0;
  end

  //  always #6.65 CPU_CKIO = ~CPU_CKIO;
  always #0.1 CPU_CKIO = ~CPU_CKIO;  // to speed up simulation

endmodule
