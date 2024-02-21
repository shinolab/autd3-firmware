import math
import pathlib
from itertools import chain

mod_params = (
    "MOD",
    [
        ("MOD_REQ_RD_SEGMENT", 1, "REQ_RD_SEGMENT"),
        ("MOD_CYCLE_0", 15, "CYCLE_0"),
        ("MOD_FREQ_DIV_0_0", 16, "FREQ_DIV_0[15:0]"),
        ("MOD_FREQ_DIV_0_1", 16, "FREQ_DIV_0[31:16]"),
        ("MOD_CYCLE_1", 15, "CYCLE_1"),
        ("MOD_FREQ_DIV_1_0", 16, "FREQ_DIV_1[15:0]"),
        ("MOD_FREQ_DIV_1_1", 16, "FREQ_DIV_1[31:16]"),
        ("MOD_REP_0_0", 16, "REP_0[15:0]"),
        ("MOD_REP_0_1", 16, "REP_0[31:16]"),
        ("MOD_REP_1_0", 16, "REP_1[15:0]"),
        ("MOD_REP_1_1", 16, "REP_1[31:16]"),
    ],
)

stm_params = (
    "STM",
    [
        ("STM_MODE_0", 1, "MODE_0"),
        ("STM_MODE_1", 1, "MODE_1"),
        ("STM_REQ_RD_SEGMENT", 1, "REQ_RD_SEGMENT"),
        ("STM_CYCLE_0", 16, "CYCLE_0"),
        ("STM_FREQ_DIV_0_0", 16, "FREQ_DIV_0[15:0]"),
        ("STM_FREQ_DIV_0_1", 16, "FREQ_DIV_0[31:16]"),
        ("STM_CYCLE_1", 16, "CYCLE_1"),
        ("STM_FREQ_DIV_1_0", 16, "FREQ_DIV_1[15:0]"),
        ("STM_FREQ_DIV_1_1", 16, "FREQ_DIV_1[31:16]"),
        ("STM_SOUND_SPEED_0_0", 16, "SOUND_SPEED_0[15:0]"),
        ("STM_SOUND_SPEED_0_1", 16, "SOUND_SPEED_0[31:16]"),
        ("STM_SOUND_SPEED_1_0", 16, "SOUND_SPEED_1[15:0]"),
        ("STM_SOUND_SPEED_1_1", 16, "SOUND_SPEED_1[31:16]"),
        ("STM_REP_0_0", 16, "REP_0[15:0]"),
        ("STM_REP_0_1", 16, "REP_0[31:16]"),
        ("STM_REP_1_0", 16, "REP_1[15:0]"),
        ("STM_REP_1_1", 16, "REP_1[31:16]"),
    ],
)

silencer_params = (
    "SILENCER",
    [
        ("SILENCER_MODE", 1, "MODE"),
        (
            "SILENCER_UPDATE_RATE_INTENSITY",
            16,
            "UPDATE_RATE_INTENSITY",
        ),
        ("SILENCER_UPDATE_RATE_PHASE", 16, "UPDATE_RATE_PHASE"),
        (
            "SILENCER_COMPLETION_STEPS_INTENSITY",
            16,
            "COMPLETION_STEPS_INTENSITY",
        ),
        (
            "SILENCER_COMPLETION_STEPS_PHASE",
            16,
            "COMPLETION_STEPS_PHASE",
        ),
    ],
)

pwe_params = (
    "PULSE_WIDTH_ENCODER",
    [
        (
            "PULSE_WIDTH_ENCODER_FULL_WIDTH_START",
            16,
            "FULL_WIDTH_START",
        ),
        ("PULSE_WIDTH_ENCODER_DUMMY_0", -1, ""),
        ("PULSE_WIDTH_ENCODER_DUMMY_1", -1, ""),
    ],
)

debug_params = (
    "DEBUG",
    [
        ("DEBUG_OUT_IDX", 8, "OUTPUT_IDX"),
        ("DEBUG_DUMMY_0", -1, ""),
        ("DEBUG_DUMMY_1", -1, ""),
    ],
)

sync_params = (
    "SYNC",
    [
        ("ECAT_SYNC_TIME_0", 16, "ECAT_SYNC_TIME[15:0]"),
        ("ECAT_SYNC_TIME_1", 16, "ECAT_SYNC_TIME[31:16]"),
        ("ECAT_SYNC_TIME_2", 16, "ECAT_SYNC_TIME[47:32]"),
        ("ECAT_SYNC_TIME_3", 16, "ECAT_SYNC_TIME[63:48]"),
    ],
)

all_params = [
    mod_params,
    stm_params,
    silencer_params,
    pwe_params,
    debug_params,
    sync_params,
]


class State:
    def __init__(self, name, req_param, req_bits, param, bits, dst):
        self.name = name
        self.req_param = req_param
        self.req_bits = req_bits
        self.param = param
        self.bits = bits
        self.dst = dst


path = (
    pathlib.Path(__file__).parent
    / "rtl"
    / "sources_1"
    / "new"
    / "controller"
    / "controller.sv"
)


def enum_name(req_param, param):
    name = f"REQ_{req_param}" if req_param != "" else ""
    if param != "":
        name = f"{name}_RD_{param}" if name != "" else f"RD_{param}"
    return name


def gen_states(prefix, params):
    states = []
    for (req_param, req_bits, _), (param, bits, dst) in zip(
        params + [("", 0, "")] * 3, [("", 0, "")] * 3 + params
    ):
        if bits >= 0:
            states.append(
                State(
                    enum_name(req_param, param), req_param, req_bits, param, bits, dst
                )
            )
    states.append(State(f"{prefix}_CLR_UPDATE_SETTINGS_BIT", "", -1, "", -1, ""))
    return states


all_states = dict(
    zip(
        (params[0] for params in all_params),
        (gen_states(params[0], params[1]) for params in all_params),
    )
)

with open(path, "w") as f:
    f.writelines(
        f"""`timescale 1ns / 1ps
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

  assign FORCE_FAN = ctl_flags[params::CTL_FLAG_FORCE_FAN_BIT];

  typedef enum logic [{int(math.ceil(math.log2(7 + len(list(chain.from_iterable(all_states.values()))))))-1}:0] {{
    REQ_WR_VER_MINOR,
    REQ_WR_VER,
    WAIT_WR_VER_0_REQ_RD_CTL_FLAG,
    WR_VER_MINOR_WAIT_RD_CTL_FLAG_0,
    WR_VER_WAIT_RD_CTL_FLAG_1,
    WAIT_0,
    WAIT_1,
{",\n".join([f"    {state.name}" for state in chain.from_iterable(all_states.values())])}
  }} state_t;

  state_t state = REQ_WR_VER_MINOR;
"""
    )

    f.writelines(
        """
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
        din  <= {8'h00, 1'h0 /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO};

       """
    )

    for name, params in all_params:
        f.writelines(
            f""" if (ctl_flags[params::CTL_FLAG_{name}_SET_BIT]) begin
          ctl_flags <= ctl_flags & ~(1 << params::CTL_FLAG_{name}_SET_BIT);
          state <= {all_states[name][0].name};
        end else"""
        )

    f.writelines(
        """ begin
          ctl_flags <= dout;
          state <= WAIT_1;
        end
      end
      WAIT_1: begin
        we <= 1'b0;
        addr <= params::ADDR_CTL_FLAG;
        state <= WAIT_0;
      end
"""
    )

    for name, states in all_states.items():
        for i, state in enumerate(states):
            f.writelines(
                f"""
      {state.name}: begin"""
            )

            if i == 0:
                f.writelines(
                    """
        we <= 1'b0;"""
                )

            if state.req_param != "" and state.req_bits != -1:
                f.writelines(
                    f"""
        addr <= params::ADDR_{state.req_param};"""
                )

            if state.param != "":
                f.writelines(
                    f"""
        {name}_SETTINGS.{state.dst} <= dout{"" if state.bits == 16 else "[0]" if state.bits == 1 else f"[{state.bits-1}:0]"};"""
                )

            if i == len(states) - 4:
                f.writelines(
                    """
        we <= 1'b1;
        addr <= params::ADDR_CTL_FLAG;
        din <= ctl_flags;"""
                )

            if i == len(states) - 3:
                f.writelines(
                    """
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din  <= {8'h00, 1'h0 /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO};"""
                )

            if i == len(states) - 2:
                f.writelines(
                    f"""
        {name}_SETTINGS.UPDATE <= 1'b1;
        we <= 1'b0;
        addr <= params::ADDR_CTL_FLAG;"""
                )

            if i + 1 < len(states):
                f.writelines(
                    f"""
        state <= {states[i+1].name};"""
                )

            if i == len(states) - 1:
                f.writelines(
                    f"""
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din  <= {{8'h00, 1'h0 /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO}};
        ctl_flags <= dout;
        {name}_SETTINGS.UPDATE <= 1'b0;
        state <= WAIT_1;"""
                )

            f.writelines(
                """
      end"""
            )
        f.writelines("\n")

    f.writelines(
        """
      default: state <= WAIT_0;
    endcase
  end
"""
    )

    f.writelines(
        """
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
"""
    )

    f.writelines(
        """
endmodule
"""
    )
