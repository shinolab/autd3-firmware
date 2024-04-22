import pathlib
import re


def to_upper(name):
    name = re.sub("(.)([A-Z][a-z]+)", r"\1_\2", name)
    name = re.sub("([a-z0-9])([A-Z])", r"\1_\2", name)
    return name.upper()


class Const:
    name: str
    value: str

    def __init__(self: "Const", name: str, value: str) -> None:
        self.name = name
        self.value = value


class Enum:
    name: str
    consts: list[Const]

    def __init__(self: "Enum", name: str, consts: list[Const]) -> None:
        self.name = name
        self.consts = consts


cpu_enums = [
    Enum(
        "params_t",
        [
            Const("NANOSECONDS", "1"),
            Const("MICROSECONDS", "NANOSECONDS * 1000"),
            Const("MILLISECONDS", "MICROSECONDS * 1000"),
            Const("SYS_TIME_TRANSITION_MARGIN", "1 * MILLISECONDS"),
        ],
    ),
    Enum(
        "tag_t",
        [
            Const("TAG_CLEAR", "0x01"),
            Const("TAG_SYNC", "0x02"),
            Const("TAG_FIRM_INFO", "0x03"),
            Const("TAG_MODULATION", "0x10"),
            Const("TAG_MODULATION_CHANGE_SEGMENT", "0x11"),
            Const("TAG_SILENCER", "0x20"),
            Const("TAG_GAIN", "0x30"),
            Const("TAG_GAIN_CHANGE_SEGMENT", "0x31"),
            Const("TAG_FOCUS_STM", "0x40"),
            Const("TAG_GAIN_STM", "0x41"),
            Const("TAG_FOCUS_STM_CHANGE_SEGMENT", "0x42"),
            Const("TAG_GAIN_STM_CHANGE_SEGMENT", "0x43"),
            Const("TAG_FORCE_FAN", "0x60"),
            Const("TAG_READS_FPGA_STATE", "0x61"),
            Const("TAG_CONFIG_PULSE_WIDTH_ENCODER", "0x70"),
            Const("TAG_PHASE_FILTER", "0x80"),
            Const("TAG_DEBUG", "0xF0"),
        ],
    ),
    Enum(
        "info_type_t",
        [
            Const("INFO_TYPE_CPU_VERSION_MAJOR", "0x01"),
            Const("INFO_TYPE_CPU_VERSION_MINOR", "0x02"),
            Const("INFO_TYPE_FPGA_VERSION_MAJOR", "0x03"),
            Const("INFO_TYPE_FPGA_VERSION_MINOR", "0x04"),
            Const("INFO_TYPE_FPGA_FUNCTIONS", "0x05"),
            Const("INFO_TYPE_CLEAR", "0x06"),
        ],
    ),
    Enum(
        "gain_flag_t",
        [
            Const("GAIN_FLAG_UPDATE", "1 << 0"),
            Const("GAIN_FLAG_SEGMENT", "1 << 1"),
        ],
    ),
    Enum(
        "modulation_flag_t",
        [
            Const("MODULATION_FLAG_BEGIN", "1 << 0"),
            Const("MODULATION_FLAG_END", "1 << 1"),
            Const("MODULATION_FLAG_UPDATE", "1 << 2"),
            Const("MODULATION_FLAG_SEGMENT", "1 << 3"),
        ],
    ),
    Enum(
        "focus_stm_flag_t",
        [
            Const("FOCUS_STM_FLAG_BEGIN", "1 << 0"),
            Const("FOCUS_STM_FLAG_END", "1 << 1"),
            Const("FOCUS_STM_FLAG_UPDATE", "1 << 2"),
            Const("FOCUS_STM_FLAG_SEGMENT", "1 << 3"),
        ],
    ),
    Enum(
        "gain_stm_flag_t",
        [
            Const("GAIN_STM_FLAG_BEGIN", "1 << 0"),
            Const("GAIN_STM_FLAG_END", "1 << 1"),
            Const("GAIN_STM_FLAG_UPDATE", "1 << 2"),
            Const("GAIN_STM_FLAG_SEGMENT", "1 << 3"),
        ],
    ),
    Enum(
        "gain_stm_mode_t",
        [
            Const("GAIN_STM_MODE_INTENSITY_PHASE_FULL", "0"),
            Const("GAIN_STM_MODE_PHASE_FULL", "1"),
            Const("GAIN_STM_MODE_PHASE_HALF", "2"),
        ],
    ),
    Enum(
        "pulse_width_encoder_flag_t",
        [
            Const("PULSE_WIDTH_ENCODER_FLAG_BEGIN", "1 << 0"),
            Const("PULSE_WIDTH_ENCODER_FLAG_END", "1 << 1"),
        ],
    ),
    Enum(
        "silencer_flag_t",
        [
            Const("SILENCER_FLAG_MODE", "1 << 0"),
            Const("SILENCER_FLAG_STRICT_MODE", "1 << 1"),
        ],
    ),
    Enum(
        "err_t",
        [
            Const("NO_ERR", "0x00"),
            Const("ERR_BIT", "0x80"),
            Const("ERR_NOT_SUPPORTED_TAG", "ERR_BIT | 0x00"),
            Const("ERR_INVALID_MSG_ID", "ERR_BIT | 0x01"),
            Const("ERR_FREQ_DIV_TOO_SMALL", "ERR_BIT | 0x02"),
            Const("ERR_COMPLETION_STEPS_TOO_LARGE", "ERR_BIT | 0x03"),
            Const("ERR_INVALID_INFO_TYPE", "ERR_BIT | 0x04"),
            Const("ERR_INVALID_GAIN_STM_MODE", "ERR_BIT | 0x05"),
            Const("ERR_INVALID_MODE", "ERR_BIT | 0x07"),
            Const("ERR_INVALID_SEGMENT_TRANSITION", "ERR_BIT | 0x08"),
            Const("ERR_INVALID_PWE_DATA_SIZE", "ERR_BIT | 0x09"),
            Const("ERR_PWE_INCOMPLETE_DATA", "ERR_BIT | 0x0A"),
            Const("ERR_MISS_TRANSITION_TIME", "ERR_BIT | 0x0B"),
        ],
    ),
]


path = (
    pathlib.Path(__file__).parent.parent
    / "fpga"
    / "rtl"
    / "sources_1"
    / "new"
    / "headers"
    / "params.svh"
)

consts = []
enums = []

with pathlib.Path.open(
    pathlib.Path(__file__).parent.parent
    / "fpga"
    / "rtl"
    / "sources_1"
    / "new"
    / "headers"
    / "params.svh",
    "r",
) as f:
    lines = f.readlines()
    read_enum = False
    enum_name = ""
    enum_consts = []
    for line in lines:
        line = line.strip()
        localparam = re.match(
            r"localparam (.+) (\w+) = (\d+|\d+'[bhd][\da-fA-F]+|\d+.\d+);", line
        )
        if localparam:
            consts.append(Const(to_upper(localparam.group(2)), localparam.group(3)))
        elif line.startswith("typedef enum"):
            read_enum = True
            enum_consts = []
        elif read_enum:
            if line.startswith("}"):
                read_enum = False
                enum_name = re.match(r"} (\w+);", line).group(1)
                enums.append(Enum(enum_name, enum_consts))
            else:
                param = re.match(r"(\w+)\s+=\s+(\d+|\d+'[bhd][\da-fA-F]+),?$", line)
                if param:
                    enum_consts.append(Const(param.group(1), param.group(2)))


def to_hex(value: str) -> str:
    match = re.match(r"\d+'[bhd]([\da-fA-F]+)", value)
    if match:
        return f"0x{match.group(1)}"
    return value


with pathlib.Path.open(
    pathlib.Path(__file__).parent / "inc" / "params.h",
    "w",
) as f:
    f.writelines(
        """#ifndef PARAMS_H
#define PARAMS_H"""
    )

    for enum in cpu_enums:
        f.writelines(
            """
"""
        )
        for const in enum.consts:
            f.writelines(
                f"""
#define {const.name} ({to_hex(const.value)})"""
            )

    f.writelines(
        """

// Following are the parameters of FPGA
"""
    )

    for const in consts:
        f.writelines(
            f"""
#define {const.name} ({to_hex(const.value)})"""
        )

    for enum in enums:
        f.writelines(
            """
"""
        )
        for const in enum.consts:
            f.writelines(
                f"""
#define {const.name} ({to_hex(const.value)})"""
            )
            if enum.name.endswith("bit_t"):
                f.writelines(
                    f"""
#define {const.name.replace("_BIT", "")} (1 << {const.name})"""
                )

    f.writelines(
        """

#endif  // INC_PARAMS_H_
"""
    )
