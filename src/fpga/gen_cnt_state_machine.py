import math
import pathlib

params = [
    # MOD
    ("MOD_REQ_RD_SEGMENT", 1, "MOD_SETTINGS.REQ_RD_SEGMENT"),
    ("MOD_CYCLE_0", 15, "MOD_SETTINGS.CYCLE_0"),
    ("MOD_FREQ_DIV_0_0", 16, "MOD_SETTINGS.FREQ_DIV_0[15:0]"),
    ("MOD_FREQ_DIV_0_1", 16, "MOD_SETTINGS.FREQ_DIV_0[31:16]"),
    ("MOD_CYCLE_1", 15, "MOD_SETTINGS.CYCLE_1"),
    ("MOD_FREQ_DIV_1_0", 16, "MOD_SETTINGS.FREQ_DIV_1[15:0]"),
    ("MOD_FREQ_DIV_1_1", 16, "MOD_SETTINGS.FREQ_DIV_1[31:16]"),
    ("MOD_REP_0", 16, "MOD_SETTINGS.REP[15:0]"),
    ("MOD_REP_1", 16, "MOD_SETTINGS.REP[31:16]"),
    # STM
    ("STM_MODE", 1, "STM_SETTINGS.MODE"),
    ("STM_REQ_RD_SEGMENT", 1, "STM_SETTINGS.REQ_RD_SEGMENT"),
    ("STM_CYCLE_0", 16, "STM_SETTINGS.CYCLE_0"),
    ("STM_FREQ_DIV_0_0", 16, "STM_SETTINGS.FREQ_DIV_0[15:0]"),
    ("STM_FREQ_DIV_0_1", 16, "STM_SETTINGS.FREQ_DIV_0[31:16]"),
    ("STM_CYCLE_1", 16, "STM_SETTINGS.CYCLE_1"),
    ("STM_FREQ_DIV_1_0", 16, "STM_SETTINGS.FREQ_DIV_1[15:0]"),
    ("STM_FREQ_DIV_1_1", 16, "STM_SETTINGS.FREQ_DIV_1[31:16]"),
    ("STM_SOUND_SPEED_0", 16, "STM_SETTINGS.SOUND_SPEED[15:0]"),
    ("STM_SOUND_SPEED_1", 16, "STM_SETTINGS.SOUND_SPEED[31:16]"),
    ("STM_REP_0", 16, "STM_SETTINGS.REP[15:0]"),
    ("STM_REP_1", 16, "STM_SETTINGS.REP[31:16]"),
    # SILENCER
    ("SILENCER_MODE", 1, "SILENCER_SETTINGS.MODE"),
    ("SILENCER_UPDATE_RATE_INTENSITY", 16, "SILENCER_SETTINGS.UPDATE_RATE_INTENSITY"),
    ("SILENCER_UPDATE_RATE_PHASE", 16, "SILENCER_SETTINGS.UPDATE_RATE_PHASE"),
    (
        "SILENCER_COMPLETION_STEPS_INTENSITY",
        16,
        "SILENCER_SETTINGS.COMPLETION_STEPS_INTENSITY",
    ),
    ("SILENCER_COMPLETION_STEPS_PHASE", 16, "SILENCER_SETTINGS.COMPLETION_STEPS_PHASE"),
    # PULSE WIDTH ENCODER
    (
        "PULSE_WIDTH_ENCODER_FULL_WIDTH_START",
        16,
        "PULSE_WIDTH_ENCODER_SETTINGS.FULL_WIDTH_START",
    ),
    # DEBUG
    ("DEBUG_OUT_IDX", 8, "DEBUG_SETTINGS.OUTPUT_IDX"),
]

sync_params = [
    # STM
    ("ECAT_SYNC_TIME_0", 16, "SYNC_SETTINGS.ECAT_SYNC_TIME[15:0]"),
    ("ECAT_SYNC_TIME_1", 16, "SYNC_SETTINGS.ECAT_SYNC_TIME[31:16]"),
    ("ECAT_SYNC_TIME_2", 16, "SYNC_SETTINGS.ECAT_SYNC_TIME[47:32]"),
    ("ECAT_SYNC_TIME_3", 16, "SYNC_SETTINGS.ECAT_SYNC_TIME[63:48]"),
]

path = (
    pathlib.Path(__file__).parent
    / "rtl"
    / "sources_1"
    / "new"
    / "controller"
    / "controller.sv"
)

enum_state_bits = int(
    math.ceil(math.log2(5 + 3 + len(params) + 1 + 3 + len(sync_params) + 1))
)

with open(path, "w") as f:
    f.writelines(
        f"""`timescale 1ns / 1ps
module controller (
    input wire CLK,
    input wire THERMO,
    cnt_bus_if.out_port cnt_bus,
    output var UPDATE_SETTINGS,
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

  typedef enum logic [{enum_state_bits-1}:0] {{
    REQ_WR_VER_MINOR,
    REQ_WR_VER,
    WAIT_WR_VER_0_REQ_RD_CTL_FLAG,
    WR_VER_MINOR_WAIT_RD_CTL_FLAG_0,
    WR_VER_WAIT_RD_CTL_FLAG_1,

    WAIT_0,
    WAIT_1,
"""
    )

    def enum_name(req_param, param):
        name = f"REQ_{req_param}" if req_param != "" else ""
        if param != "":
            name = f"{name}_RD_{param}" if name != "" else f"RD_{param}"
        return name

    states = []
    for (req_param, _, _), (param, _, _) in zip(
        params + [("", 0, "")] * 3, [("", 0, "")] * 3 + params
    ):
        name = enum_name(req_param, param)
        states.append(name)
        f.writelines(
            f"""
    {name},"""
        )
    f.writelines(
        """
    CLR_UPDATE_SETTINGS_BIT,
"""
    )

    sync_states = []
    for (req_param, _, _), (param, _, _) in zip(
        sync_params + [("", 0, "")] * 3, [("", 0, "")] * 3 + sync_params
    ):
        name = enum_name(req_param, param)
        sync_states.append(name)
        f.writelines(
            f"""
    {name},"""
        )
    f.writelines(
        """
    CLR_SYNC_BIT"""
    )

    f.writelines(
        """
  } state_t;

  state_t state = REQ_WR_VER_MINOR;
"""
    )

    f.writelines(
        """
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
"""
    )

    f.writelines(
        """
      //////////////////////////// wait ///////////////////////////"""
    )

    f.writelines(
        f"""
      WAIT_0: begin
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {{15'h00, THERMO}};
        ctl_flags <= dout;

        state <= WAIT_1;
      end
      WAIT_1: begin
        if (ctl_flags[params::CTL_FLAG_SYNC_BIT]) begin
          we <= 1'b1;
          addr <= params::ADDR_CTL_FLAG;
          din <= ctl_flags & ~(1 << params::CTL_FLAG_SYNC_BIT);

          state <= {sync_states[0]};
        end else if (ctl_flags[params::CTL_FLAG_SET_BIT]) begin
          we <= 1'b0;
          state <= {states[0]};
        end else begin
          addr <= params::ADDR_CTL_FLAG;
          we <= 1'b0;
          state <= WAIT_0;
        end
      end"""
    )

    f.writelines(
        """
      //////////////////////////// wait ///////////////////////////
"""
    )

    f.writelines(
        """
      //////////////////////////// load ///////////////////////////
"""
    )

    for i, ((req_param, _, _), (param, bits, dst)) in enumerate(
        zip(params + [("", 0, "")] * 3, [("", 0, "")] * 3 + params)
    ):
        f.writelines(
            f"""
      {states[i]}: begin"""
        )

        if req_param != "":
            f.writelines(
                f"""
        addr <= params::ADDR_{req_param};
"""
            )

        if param != "":
            f.writelines(
                f"""
        {dst} <= dout{"" if bits == 16 else "[0]" if bits == 1 else f"[{bits-1}:0]"};
"""
            )

        if i == len(states) - 3:
            f.writelines(
                """
        addr <= params::ADDR_CTL_FLAG;
"""
            )

        if i == len(states) - 2:
            f.writelines(
                """
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {15'h00, THERMO};
"""
            )

        if i == len(states) - 1:
            f.writelines(
                """
        we <= 1'b0;
        addr <= params::ADDR_CTL_FLAG;
"""
            )

        if i + 1 < len(states):
            f.writelines(
                f"""
        state <= {states[i+1]};"""
            )
        else:
            f.writelines(
                """
        UPDATE_SETTINGS <= 1'b1;

        state <= CLR_UPDATE_SETTINGS_BIT;"""
            )

        f.writelines(
            """
      end"""
        )

    f.writelines(
        """
      CLR_UPDATE_SETTINGS_BIT: begin
        UPDATE_SETTINGS <= 1'b0;

        ctl_flags <= dout;
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {15'h00, THERMO};

        state <= WAIT_1;
      end"""
    )

    f.writelines(
        """
      //////////////////////////// load ///////////////////////////
"""
    )

    f.writelines(
        """
      //////////////////////// synchronize ////////////////////////"""
    )
    for i, ((req_param, _, _), (param, _, dst)) in enumerate(
        zip(sync_params + [("", 0, "")] * 3, [("", 0, "")] * 3 + sync_params)
    ):
        f.writelines(
            f"""
      {sync_states[i]}: begin"""
        )

        if i == 0:
            f.writelines(
                """
        we <= 1'b0;"""
            )

        if req_param != "":
            f.writelines(
                f"""
        addr <= params::ADDR_{req_param};
"""
            )

        if param != "":
            f.writelines(
                f"""
        {dst} <= dout;
"""
            )

        if i == len(sync_states) - 3:
            f.writelines(
                """
        addr <= params::ADDR_CTL_FLAG;
"""
            )

        if i == len(sync_states) - 2:
            f.writelines(
                """
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {15'h00, THERMO};
"""
            )

        if i == len(sync_states) - 1:
            f.writelines(
                """
        we <= 1'b0;
        addr <= params::ADDR_CTL_FLAG;
"""
            )

        if i + 1 < len(sync_states):
            f.writelines(
                f"""
        state <= {sync_states[i+1]};"""
            )
        else:
            f.writelines(
                """
        SYNC_SETTINGS.SET <= 1'b1;

        state <= CLR_SYNC_BIT;"""
            )

        f.writelines(
            """
      end"""
        )

    f.writelines(
        """
      CLR_SYNC_BIT: begin
        SYNC_SETTINGS.SET <= 1'b0;

        ctl_flags <= dout;
        we <= 1'b1;
        addr <= params::ADDR_FPGA_STATE;
        din <= {15'h00, THERMO};

        state <= WAIT_1;
      end"""
    )

    f.writelines(
        """
      //////////////////////// synchronize ////////////////////////"""
    )

    f.writelines(
        """
      default: begin
      end
    endcase
  end
"""
    )

    f.writelines(
        """
  initial begin
    MOD_SETTINGS.REQ_RD_SEGMENT = 1'b0;
    MOD_SETTINGS.CYCLE_0 = 15'd1;
    MOD_SETTINGS.FREQ_DIV_0 = 32'd5120;
    MOD_SETTINGS.CYCLE_1 = 15'd1;
    MOD_SETTINGS.FREQ_DIV_1 = 32'd5120;
    MOD_SETTINGS.REP = 32'hFFFFFFFF;

    STM_SETTINGS.MODE = params::STM_MODE_GAIN;
    STM_SETTINGS.REQ_RD_SEGMENT = 1'b0;
    STM_SETTINGS.CYCLE_0 = '0;
    STM_SETTINGS.FREQ_DIV_0 = 32'hFFFFFFFF;
    STM_SETTINGS.CYCLE_1 = '0;
    STM_SETTINGS.FREQ_DIV_1 = 32'hFFFFFFFF;
    STM_SETTINGS.REP = 32'hFFFFFFFF;
    STM_SETTINGS.SOUND_SPEED = '0;

    SILENCER_SETTINGS.MODE                       = params::SILNCER_MODE_FIXED_COMPLETION_STEPS;
    SILENCER_SETTINGS.UPDATE_RATE_INTENSITY      = 16'd256;
    SILENCER_SETTINGS.UPDATE_RATE_PHASE          = 16'd256;
    SILENCER_SETTINGS.COMPLETION_STEPS_INTENSITY = 16'd10;
    SILENCER_SETTINGS.COMPLETION_STEPS_PHASE     = 16'd40;

    SYNC_SETTINGS.SET = 1'b0;
    SYNC_SETTINGS.ECAT_SYNC_TIME = '0;

    PULSE_WIDTH_ENCODER_SETTINGS.FULL_WIDTH_START = 16'd65025;

    DEBUG_SETTINGS.OUTPUT_IDX = 8'hFF;
  end
"""
    )

    f.writelines(
        """
endmodule
"""
    )
