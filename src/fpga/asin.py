import pathlib

import numpy as np

path = pathlib.Path(__file__).parent / "asin.coe"

T = 256
DEPTH = 8
N = 2**DEPTH
FULL = 255

with open(path, "w") as f:
    f.write("memory_initialization_radix = 16 ;\n")
    f.write("memory_initialization_vector =\n")
    for i in range(N):
        if i >= FULL:
            v = T // 2
        else:
            v = int(np.round(np.arcsin(i / FULL) / np.pi * 2 * T / 2))
        if i == N - 1:
            f.write(f"{v:02x};\n")
        else:
            f.write(f"{v:02x},\n")
