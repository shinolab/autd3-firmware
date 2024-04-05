module debug #(
    parameter int DEPTH = 249
) (
    input wire CLK,
    settings::debug_settings_t DEBUG_SETTINGS,
    input wire [8:0] TIME_CNT,
    input wire PWM_OUT[DEPTH],
    output wire GPIO_OUT[4]
);

  logic base_sig;

  assign GPIO_OUT[0] = debug_signal(
      base_sig, PWM_OUT, DEBUG_SETTINGS.TYPE[0], DEBUG_SETTINGS.VALUE[0]
  );
  assign GPIO_OUT[1] = debug_signal(
      base_sig, PWM_OUT, DEBUG_SETTINGS.TYPE[1], DEBUG_SETTINGS.VALUE[1]
  );
  assign GPIO_OUT[2] = debug_signal(
      base_sig, PWM_OUT, DEBUG_SETTINGS.TYPE[2], DEBUG_SETTINGS.VALUE[2]
  );
  assign GPIO_OUT[3] = debug_signal(
      base_sig, PWM_OUT, DEBUG_SETTINGS.TYPE[3], DEBUG_SETTINGS.VALUE[3]
  );

  always_ff @(posedge CLK) begin
    base_sig <= TIME_CNT[8] == 1'b0;
  end

  function logic debug_signal(input base_sig, input pwm[DEPTH], input [7:0] dbg_type,
                              input [15:0] value);
    case (dbg_type)
      params::DBG_NONE: begin
        debug_signal = 1'b0;
      end
      params::DBG_BASE_SIG: begin
        debug_signal = base_sig;
      end
      params::DBG_PWM_OUT: begin
        debug_signal = pwm[value];
      end
      default: begin
        debug_signal = 1'b0;
      end
    endcase

  endfunction

endmodule
