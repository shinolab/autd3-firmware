#!/usr/bin/env python3

import argparse
import contextlib
import glob
import os
import platform
import re
import shutil
import subprocess
import sys
from typing import List, Optional


def err(msg: str):
    print("\033[91mERR \033[0m: " + msg)


def warn(msg: str):
    print("\033[93mWARN\033[0m: " + msg)


def info(msg: str):
    print("\033[92mINFO\033[0m: " + msg)


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
                lambda x: x[0] == "DisplayName" and re.search("Vivado|Vitis", x[1]),
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


def rm_f(path):
    try:
        os.remove(path)
    except FileNotFoundError:
        pass


def onexc(func, path, exeption):
    import stat

    if not os.access(path, os.W_OK):
        os.chmod(path, stat.S_IWUSR)
        func(path)
    else:
        raise


def rmtree_f(path):
    try:
        shutil.rmtree(path, onerror=onexc)
    except FileNotFoundError:
        pass


def glob_norm(path, recursive):
    return [os.path.normpath(p) for p in glob.glob(path, recursive=recursive)]


def rm_glob_f(path, exclude=None, recursive=True):
    if exclude is not None:
        for f in list(
            set(glob_norm(path, recursive=recursive))
            - set(glob_norm(exclude, recursive=recursive))
        ):
            rm_f(f)
    else:
        for f in glob.glob(path, recursive=recursive):
            rm_f(f)


@contextlib.contextmanager
def working_dir(path):
    cwd = os.getcwd()
    os.chdir(path)
    try:
        yield
    finally:
        os.chdir(cwd)


class Config:
    _platform: str
    cmake_extra: Optional[List[str]]

    def __init__(self, args):
        self._platform = platform.system()

        if not self.is_windows() and not self.is_macos() and not self.is_linux():
            err(f'platform "{platform.system()}" is not supported.')
            sys.exit(-1)

        self.cmake_extra = (
            args.cmake_extra.split(" ")
            if hasattr(args, "cmake_extra") and args.cmake_extra is not None
            else None
        )

    def is_windows(self):
        return self._platform == "Windows"

    def is_macos(self):
        return self._platform == "Darwin"

    def is_linux(self):
        return self._platform == "Linux"

    def exe_ext(self):
        return ".exe" if self.is_windows() else ""


def cpu_test(args):
    config = Config(args)
    with working_dir("src/cpu/tests"):
        os.makedirs("build", exist_ok=True)
        with working_dir("build"):
            command = ["cmake", ".."]
            if config.cmake_extra is not None:
                for cmd in config.cmake_extra:
                    command.append(cmd)
            subprocess.run(command).check_returncode()
            command = ["cmake", "--build", ".", "--parallel", "8"]
            subprocess.run(command).check_returncode()

            target_dir = "."
            if config.is_windows():
                target_dir = "Debug"
            subprocess.run(
                [f"{target_dir}/test_autd3-firmware{config.exe_ext()}"]
            ).check_returncode()


def cpu_cov(args):
    config = Config(args)
    if not config.is_linux():
        err("Coverage is only supported on Linux.")
        return

    with working_dir("src/cpu/tests"):
        os.makedirs("build", exist_ok=True)
        with working_dir("build"):
            command = ["cmake", "..", "-DCOVERAGE=ON"]
            if config.cmake_extra is not None:
                for cmd in config.cmake_extra:
                    command.append(cmd)
            subprocess.run(command).check_returncode()
            command = ["cmake", "--build", ".", "--parallel", "8"]
            subprocess.run(command).check_returncode()

            target_dir = "."
            if config.is_windows():
                target_dir = "Debug"
            subprocess.run(
                [f"{target_dir}/test_autd3-firmware{config.exe_ext()}"]
            ).check_returncode()

            with working_dir("CMakeFiles/test_autd3-firmware.dir"):
                command = ["lcov", "-d", ".", "-c", "-o", "coverage.raw.info"]
                subprocess.run(command).check_returncode()
                command = [
                    "lcov",
                    "-r",
                    "coverage.raw.info",
                    "*/googletest/*",
                    "*/tests/*",
                    "*/c++/*",
                    "*/gcc/*",
                    "-o",
                    "coverage.info",
                ]
                subprocess.run(command).check_returncode()
                if args.html:
                    command = [
                        "genhtml",
                        "-o",
                        "html",
                        "--num-spaces",
                        "4",
                        "coverage.info",
                    ]
                    subprocess.run(command).check_returncode()


def cpu_clear(_):
    with working_dir("."):
        rmtree_f("src/cpu/tests/build")


def fpga_clear(_):
    with working_dir("."):
        rm_glob_f("*.jou")
        rm_glob_f("*.log")
        rmtree_f(".Xil")

    with working_dir("./src/fpga"):
        rm_glob_f("*.jou")
        rm_glob_f("*.log")
        rm_glob_f("*.zip")
        rm_glob_f("*.prm")
        rm_glob_f("*.str")
        rm_glob_f("*.pb")
        rm_glob_f("*.xpr")
        rmtree_f("autd3-fpga.ip_user_files")
        rmtree_f("autd3-fpga.cache")
        rmtree_f("autd3-fpga.gen")
        rmtree_f("autd3-fpga.hw")
        rmtree_f("autd3-fpga.runs")
        rmtree_f("autd3-fpga.sim")
        rmtree_f("autd3-fpga.srcs")
        rmtree_f(".Xil")


def fpga_build(args):
    vivado_dir = args.vivado_dir

    with working_dir("./src/fpga"):
        info("Invoking Vivado...")
        if shutil.which("vivado") is None:
            if not vivado_dir:
                info("Vivado is not found in PATH. Looking for Vivado...")
                xilinx_path = find_vivado()
                if xilinx_path is None:
                    err("Vivado is not found. Install Vivado.")
                    sys.exit(1)
                vivado_path = os.path.join(xilinx_path, "Vivado")
                if not os.path.exists(vivado_path):
                    err("Vivado is not found. Install Vivado.")
                    sys.exit(1)
                vivados = [
                    d
                    for d in os.listdir(vivado_path)
                    if os.path.isdir(os.path.join(vivado_path, d))
                ]
                if not vivados:
                    err("Vivado is not found. Install Vivado.")
                    sys.exit(1)
                vivado_ver = vivados[0]
                info(f"Vivado {vivado_ver} found")
                vivado_dir = os.path.join(vivado_path, vivado_ver)

            vivado_bin = os.path.join(vivado_dir, "bin")
            vivado_lib = os.path.join(vivado_dir, "lib", "win64.o")
            os.environ["PATH"] += os.pathsep + vivado_bin + os.pathsep + vivado_lib

        command = "vivado -mode batch -source proj_gen.tcl"
        subprocess.run(command, shell=True)


def command_help(args):
    print(parser.parse_args([args.command, "--help"]))


if __name__ == "__main__":
    with working_dir(os.path.dirname(os.path.abspath(__file__))):
        parser = argparse.ArgumentParser(description="autd3 library build script")
        subparsers = parser.add_subparsers()

        parser_cpu = subparsers.add_parser("cpu", help="see `cpu -h`")
        subparsers_cpu = parser_cpu.add_subparsers()

        # test
        parser_cpu_test = subparsers_cpu.add_parser("test", help="see `build -h`")
        parser_cpu_test.add_argument("--cmake-extra", help="cmake extra args")
        parser_cpu_test.set_defaults(handler=cpu_test)

        # cov
        parser_cpu_cov = subparsers_cpu.add_parser("cov", help="see `build -h`")
        parser_cpu_cov.add_argument("--cmake-extra", help="cmake extra args")
        parser_cpu_cov.add_argument("--html", action="store_true", help="generate html")
        parser_cpu_cov.set_defaults(handler=cpu_cov)

        # clear
        parser_cpu_clear = subparsers_cpu.add_parser("clear", help="see `clear -h`")
        parser_cpu_clear.set_defaults(handler=cpu_clear)

        parser_fpga = subparsers.add_parser("fpga", help="see `fpga -h`")
        subparsers_fpga = parser_fpga.add_subparsers()

        # clear
        parser_fpga_clear = subparsers_fpga.add_parser("clear", help="see `clear -h`")
        parser_fpga_clear.set_defaults(handler=fpga_clear)

        # build
        parser_fpga_build = subparsers_fpga.add_parser("build", help="see `build -h`")
        parser_fpga_build.add_argument(
            "--vivado-dir", default=None, help="Vivado installation directory"
        )
        parser_fpga_build.set_defaults(handler=fpga_build)

        # help
        parser_help = subparsers.add_parser("help", help="see `help -h`")
        parser_help.add_argument("command", help="command name which help is shown")
        parser_help.set_defaults(handler=command_help)

        args = parser.parse_args()
        if hasattr(args, "handler"):
            args.handler(args)
        else:
            parser.print_help()
