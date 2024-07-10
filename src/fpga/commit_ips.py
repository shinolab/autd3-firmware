import pathlib
import shutil

src = pathlib.Path(__file__).parent / "autd3-fpga.srcs" / "sources_1" / "ip"
dst = pathlib.Path(__file__).parent / "rtl" / "sources_1" / "ip"

shutil.copytree(src, dst, dirs_exist_ok=True)
