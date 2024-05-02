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
    pathlib.Path(__file__).parent / "inc" / "params_fpga.h",
    "w",
) as f:
    f.writelines(
        """#ifndef PARAMS_FPGA_H
#define PARAMS_FPGA_H
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

#endif  // PARAMS_FPGA_H
"""
    )
