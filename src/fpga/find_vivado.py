import os
import re
import shutil
import subprocess
import sys
from pathlib import Path


def find_vivado() -> str | None:
    import winreg

    try:
        key = winreg.OpenKey(
            winreg.HKEY_LOCAL_MACHINE,
            r"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        )
        subkey_n, _, _ = winreg.QueryInfoKey(key)

        install_location = None
        for i in range(subkey_n):
            subkey = winreg.OpenKey(key, winreg.EnumKey(key, i))
            _, vn, _ = winreg.QueryInfoKey(subkey)
            values: list[tuple[str, str, str]] = []
            for v in range(vn):
                values.append(winreg.EnumValue(subkey, v))
            for v in filter(
                lambda x: x[0] == "DisplayName"
                and re.search("Vivado|Vitis|(Xilinx Design Tools FPGAs)", x[1]),
                values,
            ):
                install_location = next(
                    filter(lambda x: x[0] == "InstallLocation", values)
                )[1]
            winreg.CloseKey(subkey)

        winreg.CloseKey(key)
        return install_location
    except WindowsError:
        return None


if shutil.which("vivado") is None:
    xilinx_path = find_vivado()
    if xilinx_path is None:
        print("Vivado not found in the system PATH or registry.")
        sys.exit(1)

    def vivado_2024_or_older(xilinx_path: str) -> Path | None:
        vivado_path = Path(xilinx_path) / "Vivado"
        if not vivado_path.exists():
            return None
        vivados = [d for d in vivado_path.glob("*") if d.is_dir()]
        if not vivados:
            return None
        return vivados[-1]

    def vivado_2025(xilinx_path: str) -> Path | None:
        vivados = []

        def _find_recurse(current_path: Path, current_depth: int, max_depth: int):
            if current_depth > max_depth:
                return None
            try:
                for item in current_path.iterdir():
                    if item.is_dir():
                        if item.name.lower() == "vivado":
                            vivados.append(item)
                        _find_recurse(item, current_depth + 1, max_depth)
            except PermissionError:
                pass

        _find_recurse(Path(xilinx_path), 0, 2)

        if not vivados:
            return None
        return vivados[-1]

    vivado_dir = vivado_2025(xilinx_path) or vivado_2024_or_older(xilinx_path)
    if vivado_dir is None:
        print("Vivado not found.")
        sys.exit(1)

    vivado_bin = vivado_dir / "bin"
    vivado_lib = vivado_dir / "lib" / "win64.o"
    os.environ["PATH"] += os.pathsep + str(vivado_bin) + os.pathsep + str(vivado_lib)


command = "vivado -mode batch -source proj_gen.tcl"
subprocess.run(command, shell=True).check_returncode()
