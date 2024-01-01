#!/usr/bin/env python3

"""
File: build.py
Project: autd3-firmware
Created Date: 31/12/2023
Author: Shun Suzuki
-----
Last Modified: 31/12/2023
Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
-----
Copyright (c) 2023 Shun Suzuki. All rights reserved.

"""

import argparse
import contextlib
import os
import platform
import shutil
import subprocess
import sys
from typing import List, Optional

from packaging import version


def err(msg: str):
    print("\033[91mERR \033[0m: " + msg)


def warn(msg: str):
    print("\033[93mWARN\033[0m: " + msg)


def info(msg: str):
    print("\033[92mINFO\033[0m: " + msg)


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
        if version.parse(platform.python_version()) >= version.parse("3.12"):
            shutil.rmtree(path, onexc=onexc)
        else:
            shutil.rmtree(path, onerror=onexc)
    except FileNotFoundError:
        pass


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

        # help
        parser_help = subparsers.add_parser("help", help="see `help -h`")
        parser_help.add_argument("command", help="command name which help is shown")
        parser_help.set_defaults(handler=command_help)

        args = parser.parse_args()
        if hasattr(args, "handler"):
            args.handler(args)
        else:
            parser.print_help()
