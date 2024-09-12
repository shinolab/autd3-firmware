`timescale 1ns / 1ps
module debug #(
    parameter int DEPTH = 249
) (
    input wire CLK,
    settings::debug_settings_t DEBUG_SETTINGS,
    input wire [7:0] TIME_CNT,
    input wire [55:0] SYS_TIME,
    input wire PWM_OUT[DEPTH],
    input wire THERMO,
    input wire FORCE_FAN,
    input wire SYNC,
    input wire STM_SEGMENT,
    input wire MOD_SEGMENT,
    input wire [12:0] STM_IDX,
    input wire [14:0] MOD_IDX,
    input wire [12:0] STM_CYCLE,
    output wire GPIO_OUT[4]
);

  logic gpio_out[4];

  assign GPIO_OUT = gpio_out;

  always_ff @(posedge CLK) begin
    gpio_out[0] <= debug_signal(DEBUG_SETTINGS.VALUE[0][63:56], DEBUG_SETTINGS.VALUE[55:0]);
    gpio_out[1] <= debug_signal(DEBUG_SETTINGS.VALUE[1][63:56], DEBUG_SETTINGS.VALUE[55:0]);
    gpio_out[2] <= debug_signal(DEBUG_SETTINGS.VALUE[2][63:56], DEBUG_SETTINGS.VALUE[55:0]);
    gpio_out[3] <= debug_signal(DEBUG_SETTINGS.VALUE[3][63:56], DEBUG_SETTINGS.VALUE[55:0]);
  end

  function automatic logic debug_signal(input logic [7:0] dbg_type, input logic [55:0] value);
    case (dbg_type)
      params::DBG_NONE: begin
        debug_signal = 1'b0;
      end
      params::DBG_BASE_SIG: begin
        debug_signal = TIME_CNT[7] == 1'b0;
      end
      params::DBG_THERMO: begin
        debug_signal = THERMO;
      end
      params::DBG_FORCE_FAN: begin
        debug_signal = FORCE_FAN;
      end
      params::DBG_SYNC: begin
        debug_signal = SYNC;
      end
      params::DBG_MOD_SEGMENT: begin
        debug_signal = MOD_SEGMENT;
      end
      params::DBG_MOD_IDX: begin
        debug_signal = MOD_IDX == value[14:0];
      end
      params::DBG_STM_SEGMENT: begin
        debug_signal = STM_SEGMENT;
      end
      params::DBG_STM_IDX: begin
        debug_signal = STM_IDX == value[12:0];
      end
      params::DBG_IS_STM_MODE: begin
        debug_signal = STM_CYCLE != '0;
      end
      params::DBG_SYS_TIME_EQ: begin
        debug_signal = SYS_TIME[55:8] == value[55:8];
      end
      params::DBG_PWM_OUT: begin
        debug_signal = PWM_OUT[value[7:0]];
      end
      params::DBG_DIRECT: begin
        debug_signal = value[0];
      end
      default: begin
        debug_signal = 1'b0;
      end
    endcase
  endfunction

endmodule
