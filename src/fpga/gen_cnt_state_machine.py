import math
import pathlib
import subprocess
from itertools import chain

BRAM_DATA_WIDTH = 16


class Param:
    addr: str
    width: int
    name: str
    default: int | str

    def __init__(
        self: "Param", addr: str, width: int, name: str, default: int | str
    ) -> None:
        self.addr = addr
        self.width = width
        self.name = name
        self.default = default

    @staticmethod
    def null() -> "Param":
        return Param("", 0, "", 0)


class Params:
    name: str
    params: list[Param]

    def __init__(self: "Params", name: str, params: list[Param]) -> None:
        self.name = name
        self.params = params


mod_params = Params(
    "MOD",
    [
        Param("MOD_REQ_RD_SEGMENT", 1, "REQ_RD_SEGMENT", 0),
        Param(
            "MOD_TRANSITION_MODE",
            8,
            "TRANSITION_MODE",
            "params::TRANSITION_MODE_SYNC_IDX",
        ),
        Param("MOD_TRANSITION_VALUE", 64, "TRANSITION_VALUE", 0),
        Param("MOD_CYCLE0", 15, "CYCLE[0]", 2 - 1),
        Param("MOD_CYCLE1", 15, "CYCLE[1]", 2 - 1),
        Param("MOD_FREQ_DIV0", 16, "FREQ_DIV[0]", 10),
        Param("MOD_FREQ_DIV1", 16, "FREQ_DIV[1]", 10),
        Param("MOD_REP0", 16, "REP[0]", "16'hFFFF"),
        Param("MOD_REP1", 16, "REP[1]", "16'hFFFF"),
    ],
)

stm_params = Params(
    "STM",
    [
        Param("STM_REQ_RD_SEGMENT", 1, "REQ_RD_SEGMENT", 0),
        Param(
            "STM_TRANSITION_MODE",
            8,
            "TRANSITION_MODE",
            "params::TRANSITION_MODE_SYNC_IDX",
        ),
        Param("STM_TRANSITION_VALUE", 64, "TRANSITION_VALUE", 0),
        Param("STM_MODE0", 1, "MODE[0]", "params::STM_MODE_GAIN"),
        Param("STM_MODE1", 1, "MODE[1]", "params::STM_MODE_GAIN"),
        Param("STM_CYCLE0", 13, "CYCLE[0]", 0),
        Param("STM_CYCLE1", 13, "CYCLE[1]", 0),
        Param("STM_FREQ_DIV0", 16, "FREQ_DIV[0]", "16'hFFFF"),
        Param("STM_FREQ_DIV1", 16, "FREQ_DIV[1]", "16'hFFFF"),
        Param("STM_SOUND_SPEED0", 16, "SOUND_SPEED[0]", 0),
        Param("STM_SOUND_SPEED1", 16, "SOUND_SPEED[1]", 0),
        Param("STM_REP0", 16, "REP[0]", "16'hFFFF"),
        Param("STM_REP1", 16, "REP[1]", "16'hFFFF"),
        Param("STM_NUM_FOCI0", 8, "NUM_FOCI[0]", "1"),
        Param("STM_NUM_FOCI1", 8, "NUM_FOCI[1]", "1"),
    ],
)

silencer_params = Params(
    "SILENCER",
    [
        Param(
            "SILENCER_FLAG",
            8,
            "FLAG",
            0,
        ),
        Param("SILENCER_UPDATE_RATE_INTENSITY", 16, "UPDATE_RATE_INTENSITY", 256),
        Param("SILENCER_UPDATE_RATE_PHASE", 16, "UPDATE_RATE_PHASE", 256),
        Param(
            "SILENCER_COMPLETION_STEPS_INTENSITY", 16, "COMPLETION_STEPS_INTENSITY", 10
        ),
        Param("SILENCER_COMPLETION_STEPS_PHASE", 16, "COMPLETION_STEPS_PHASE", 40),
    ],
)

debug_params = Params(
    "DEBUG",
    [
        Param("DEBUG_TYPE0", 8, "TYPE[0]", "params::DBG_NONE"),
        Param("DEBUG_VALUE0", 48, "VALUE[0]", 0),
        Param("DEBUG_TYPE1", 8, "TYPE[1]", "params::DBG_NONE"),
        Param("DEBUG_VALUE1", 48, "VALUE[1]", 0),
        Param("DEBUG_TYPE2", 8, "TYPE[2]", "params::DBG_NONE"),
        Param("DEBUG_VALUE2", 48, "VALUE[2]", 0),
        Param("DEBUG_TYPE3", 8, "TYPE[3]", "params::DBG_NONE"),
        Param("DEBUG_VALUE3", 48, "VALUE[3]", 0),
    ],
)

sync_params = Params(
    "SYNC",
    [
        Param("ECAT_SYNC_TIME", 64, "ECAT_SYNC_TIME", 0),
    ],
)

all_params: list[Params] = [
    mod_params,
    stm_params,
    silencer_params,
    debug_params,
    sync_params,
]


path = (
    pathlib.Path(__file__).parent
    / "rtl"
    / "sources_1"
    / "new"
    / "controller"
    / "controller.sv"
)


class State:
    def __init__(self: "State", name: str, req_param: Param, param: Param) -> None:
        self.name = name
        self.req_param = req_param
        self.param = param


def gen_states(params: Params) -> list[State]:
    def gen_state(req_param: Param, param: Param) -> State:
        name = f"REQ_{req_param.addr}" if req_param.addr != "" else ""
        if param.addr != "":
            name = f"{name}_RD_{param.addr}" if name != "" else f"RD_{param.addr}"
        return State(name, req_param, param)

    sub_params: list[Param] = []
    for param in params.params:
        if param.width <= BRAM_DATA_WIDTH:
            sub_params.append(param)
        else:
            n = param.width // BRAM_DATA_WIDTH
            sub_params.extend(
                [
                    Param(
                        f"{param.addr}_{i}",
                        min(BRAM_DATA_WIDTH, param.width - BRAM_DATA_WIDTH * i),
                        f"{param.name}[{min(param.width, BRAM_DATA_WIDTH*(i+1))-1}:{BRAM_DATA_WIDTH * i}]",
                        param.default,
                    )
                    for i in range(n)
                ],
            )
    states: list[State] = []
    for req_param, param in zip(
        sub_params + [Param.null()] * 3, [Param.null()] * 3 + sub_params, strict=True
    ):
        if param.width >= 0:
            states.append(gen_state(req_param, param))
    states.append(
        State(f"{params.name}_CLR_UPDATE_SETTINGS_BIT", Param.null(), Param.null())
    )
    return states


all_states: dict[str, list[State]] = dict(
    zip(
        (params.name for params in all_params),
        (gen_states(params) for params in all_params),
        strict=True,
    ),
)

with pathlib.Path.open(path, "w") as f:
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
    output var settings::debug_settings_t DEBUG_SETTINGS,
    output var FORCE_FAN,
    output var GPIO_IN[4]
);

  logic [15:0] ctl_flags;

  logic we;
  logic [7:0]  addr;
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

  typedef enum logic [{int(math.ceil(math.log2(7 + len(list(chain.from_iterable(all_states.values()))))))-1}:0] {{
    REQ_WR_VER_MINOR,
    REQ_WR_VER,
    WAIT_WR_VER_0_REQ_RD_CTL_FLAG,
    WR_VER_MINOR_WAIT_RD_CTL_FLAG_BIT_0,
    WR_VER_WAIT_RD_CTL_FLAG_BIT_1,
    WAIT_0,
    WAIT_1,
{",\n".join([f"    {state.name}" for state in chain.from_iterable(all_states.values())])}
  }} state_t;

  state_t state = REQ_WR_VER_MINOR;
""",
    )

    f.writelines(
        """
  always_ff @(posedge CLK) begin
    case (state)
      REQ_WR_VER_MINOR: begin
        we <= 1'b1;

        din <= {8'd0, params::VersionNumMinor};
        addr <= params::ADDR_VERSION_NUM_MINOR;

        state <= REQ_WR_VER;
      end
      REQ_WR_VER: begin
        din   <= {8'h00, params::VersionNumMajor};
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
        din  <= {8'h00, 1'h0 /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO};

       """,
    )

    for params in all_params:
        f.writelines(
            f""" if (ctl_flags[params::CTL_FLAG_BIT_{params.name}_SET]) begin
          ctl_flags <= ctl_flags & ~(1 << params::CTL_FLAG_BIT_{params.name}_SET);
          state <= {all_states[params.name][0].name};
        end else""",
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
""",
    )

    for name, states in all_states.items():
        for i, state in enumerate(states):
            param = state.param
            req_param = state.req_param
            f.writelines(
                f"""
      {state.name}: begin""",
            )

            if i == 0:
                f.writelines(
                    """
        we <= 1'b0;""",
                )

            if req_param.addr != "" and req_param.width != -1:
                f.writelines(
                    f"""
        addr <= params::ADDR_{req_param.addr};""",
                )

            if param.addr != "":
                r: str
                if param.width == BRAM_DATA_WIDTH:
                    r = ""
                elif param.width == 1:
                    r = "[0]"
                else:
                    r = f"[{param.width-1}:0]"
                f.writelines(
                    f"""
        {name}_SETTINGS.{param.name} <= dout{r};""",
                )

            if i == len(states) - 4:
                f.writelines(
                    """
        we <= 1'b1;
        addr <= params::ADDR_CTL_FLAG;
        din <= ctl_flags;""",
                )

            if i == len(states) - 3:
                f.writelines(
                    """
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din  <= {8'h00, 1'h0 /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO};""",
                )

            if i == len(states) - 2:
                f.writelines(
                    f"""
        {name}_SETTINGS.UPDATE <= 1'b1;
        we <= 1'b0;
        addr <= params::ADDR_CTL_FLAG;""",
                )

            if i + 1 < len(states):
                f.writelines(
                    f"""
        state <= {states[i+1].name};""",
                )

            if i == len(states) - 1:
                f.writelines(
                    f"""
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din  <= {{8'h00, 1'h0 /* reserved */, 3'h0, STM_CYCLE == '0, STM_SEGMENT, MOD_SEGMENT, THERMO}};
        ctl_flags <= dout;
        {name}_SETTINGS.UPDATE <= 1'b0;
        state <= WAIT_1;""",
                )

            f.writelines(
                """
      end""",
            )
        f.writelines("\n")

    f.writelines(
        """
      default: state <= WAIT_0;
    endcase
  end
""",
    )

    f.writelines(
        """
  initial begin""",
    )
    for params in all_params:
        f.writelines(
            f"""
    {params.name}_SETTINGS.UPDATE = 1'b0;""",
        )
        for param in params.params:
            if param.name == "":
                continue
            default_value = (
                param.default
                if isinstance(param.default, str)
                else f"{param.width}'d{param.default}"
            )
            f.writelines(
                f"""
    {params.name}_SETTINGS.{param.name} = {default_value};""",
            )
    f.writelines(
        """
  end
""",
    )

    f.writelines(
        """
endmodule
""",
    )

command = [
    "verible-verilog-format",
    str(path),
    "--column_limit=100",
    "--inplace",
]
subprocess.run(command, check=True).check_returncode()  # noqa: S603
