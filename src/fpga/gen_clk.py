import argparse
import pathlib
import re

DIVCLK_DIVIDE_MIN = 1
DIVCLK_DIVIDE_MAX = 106
MULT_MIN = 2.0
MULT_MAX = 64.0
DIV_MIN = 1.0
DIV_MAX = 128.0
INCREMENTS = 0.125
VCO_MIN = 600.0e6
VCO_MAX = 1600.0e6


def calculate_mult_div(frequency: float, base_frequency: float) -> tuple[int, float, float, float] | None:
    target_ratio = frequency / base_frequency

    best_div = None
    best_m = None
    best_d = None
    best_error = float("inf")

    for div in range(DIVCLK_DIVIDE_MIN, DIVCLK_DIVIDE_MAX + 1):
        for m in range(int(MULT_MIN / INCREMENTS), int(MULT_MAX / INCREMENTS) + 1):
            m_val = m * INCREMENTS
            vco = base_frequency * m_val / div
            if vco < VCO_MIN or vco > VCO_MAX:
                continue
            for d in range(int(DIV_MIN / INCREMENTS), int(DIV_MAX / INCREMENTS) + 1):
                d_val = d * INCREMENTS

                error = abs(target_ratio - (m_val / d_val))

                if error < best_error:
                    best_div = div
                    best_m = m_val
                    best_d = d_val
                    best_error = error

                if best_error == 0:
                    break

    if best_div is not None and best_m is not None and best_d is not None:
        return best_div, best_m, best_d, best_error
    return None


def run(args) -> None:
    frequency = args.frequency * 512
    base_frequency = args.base_frequency
    force = args.force

    clkin_period = 1 / base_frequency * 1e9

    res = calculate_mult_div(frequency, base_frequency)
    if res is None:
        raise ValueError("Cannot found a valid mult/div pair")
    clkdiv, mult, div, error = res
    if error != 0.00:
        if force:
            print(f"Actual frequency is {base_frequency * mult / div / 512:.3f} Hz")
        else:
            raise ValueError("Cannot found a valid mult/div pair. Use --force to ignore this error")

    ecat_sync_base_cnt: float = frequency * 0.0005
    if not ecat_sync_base_cnt.is_integer():
        raise ValueError(f"frequency ({args.frequency}) is invalid for synchronizer")
    with pathlib.Path.open(pathlib.Path(__file__).parent / "rtl" / "sources_1" / "new" / "headers" / "params.svh", "r") as f:
        content = f.read()
    with pathlib.Path.open(pathlib.Path(__file__).parent / "rtl" / "sources_1" / "new" / "headers" / "params.svh", "w") as f:
        result = re.sub(
            r"localparam real UltrasoundFrequency = (.+);",
            f"localparam real UltrasoundFrequency = {args.frequency};",
            content,
            flags=re.MULTILINE,
        )
        f.writelines(result)
    with pathlib.Path.open(pathlib.Path(__file__).parent / "rtl" / "sources_1" / "new" / "ultrasound_cnt_clk_gen.sv", "w") as f:
        f.writelines(
            f"""`timescale 1ns / 1ps
module ultrasound_cnt_clk_gen (
    input  wire clk_in1,
    input  wire reset,
    output wire clk_out,
    output wire locked
);

  logic CLKOUT;
  logic CLKFB, CLKFB_BUF;
  BUFG clkf_buf (
      .O(CLKFB_BUF),
      .I(CLKFB)
  );
  BUFG clkout_buf (
      .O(clk_out),
      .I(CLKOUT)
  );

  MMCME2_ADV #(
      .BANDWIDTH           ("OPTIMIZED"),
      .CLKOUT4_CASCADE     ("FALSE"),
      .COMPENSATION        ("ZHOLD"),
      .STARTUP_WAIT        ("FALSE"),
      .DIVCLK_DIVIDE       ({clkdiv}),
      .CLKFBOUT_MULT_F     ({mult:.3f}),
      .CLKFBOUT_PHASE      (0.000),
      .CLKFBOUT_USE_FINE_PS("FALSE"),
      .CLKOUT0_DIVIDE_F    ({div:.3f}),
      .CLKOUT0_PHASE       (0.000),
      .CLKOUT0_DUTY_CYCLE  (0.500),
      .CLKOUT0_USE_FINE_PS ("FALSE"),
      .CLKIN1_PERIOD       ({round(clkin_period, 3)})
  ) MMCME2_ADV_inst (
      .CLKOUT0(CLKOUT),
      .CLKOUT0B(),
      .CLKOUT1(),
      .CLKOUT1B(),
      .CLKFBOUT(CLKFB),
      .CLKFBOUTB(),
      .CLKFBSTOPPED(),
      .CLKINSTOPPED(),
      .LOCKED(locked),
      .CLKIN1(clk_in1),
      .CLKINSEL(1'b1),
      .PWRDWN(1'b0),
      .RST(reset),
      .CLKFBIN(CLKFB_BUF),
      .CLKOUT2(),
      .CLKOUT2B(),
      .CLKOUT3(),
      .CLKOUT3B(),
      .CLKOUT4(),
      .CLKOUT5(),
      .CLKOUT6(),
      .DO(),
      .DRDY(),
      .PSDONE(),
      .CLKIN2(),
      .DADDR(),
      .DCLK(),
      .DEN(),
      .DI(),
      .DWE(),
      .PSCLK(),
      .PSEN(),
      .PSINCDEC()
  );

endmodule
""",
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="generate clocking module")
    parser.add_argument("-f", "--frequency", required=True, help="target frequency", type=float)
    parser.add_argument("-b", "--base_frequency", help="base frequency", type=float, default=25.6e6)
    parser.add_argument("--force", action="store_true", help="skip install python package")
    args = parser.parse_args()
    run(args)
