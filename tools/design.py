#
# This file creates the README.md-the design doc.-for the project.
# Doing this allows the desing parameters to be programmatically chosen.
#
import argparse
import io
import math
import sys
import os
from string import Template
from typing import Literal


# Formats a number for LaTeX.
def fmt_value(
    value: int | float,
    unit: Literal["ohms"] | Literal["amps"] | Literal["volts"] | Literal["hz"],
    percision: int | None = None,
) -> str:
    suffix = ["f", "p", "n", "\\mu ", "m", "", "k", "M", "G", "T"][
        math.floor(math.log10(value) / 3) + 5 if abs(value) >= 1e-15 else 0
    ]
    value /= math.pow(10, math.floor(math.log10(value) / 3) * 3)
    return (
        (f"{value:.{percision}f}" if percision is not None else f"{value}")
        + f"{suffix}{
            {
                'ohms': '\\Omega',
                'volts': '\\mathrm{V}',
                'amps': '\\mathrm{A}',
                'hz': '\\mathrm{Hz}',
            }[unit]
        }"
    )


# Returns the e-series value for a number
def eseries(
    value: float,
    series: Literal[24],
    rounding: Literal["nearest"] | Literal["down"] | Literal["up"] = "nearest",
):
    eseries_values = {
        "24": [
            1.0,
            1.1,
            1.2,
            1.3,
            1.5,
            1.6,
            1.8,
            2.0,
            2.2,
            2.4,
            2.7,
            3.0,
            3.3,
            3.6,
            3.9,
            4.3,
            4.7,
            5.1,
            5.6,
            6.2,
            6.8,
            7.5,
            8.2,
            9.1,
        ],
    }[str(series)]
    power = math.pow(10, math.floor(math.log10(value)))
    value /= power
    idx = 0
    for i, evalue in enumerate(eseries_values):
        match rounding:
            case "nearest":
                if abs(value - evalue) <= abs(value - eseries_values[idx]):
                    idx = i
            case "down" | "up":
                if value >= evalue:
                    idx = i
    if rounding == "up" and value != eseries_values[idx]:
        if idx == len(eseries_values) - 1:
            power *= 10
            idx = 0
        else:
            idx += 1
    return eseries_values[idx] * power


# Actual parameters for the design
class Design:
    R_AL = 100
    R_AH = 4e3
    PCLK = 1.05e6
    f_OLED_SCK = PCLK / 2
    VDD = 3.3
    N_TPMIN = 64

    def __init__(self):
        # Get max ADC input resistance
        T_S = 1.5
        N = 12
        f_ADC = self.PCLK
        C_ADC = 8e-12
        R_ADC = 1e3
        self.R_AINMAX = T_S / (f_ADC * C_ADC * math.log(1 << (N + 2))) - R_ADC

        # Find the optimial touch panel current limit resistor
        V_IH = 2.31
        I_GPIO = 8e-3
        self.R_TP = (self.VDD - I_GPIO * self.R_AL) / I_GPIO

        # Keep raising R_TP from the starting minimum until it doesn't meet a requirement
        step = 10
        while (
            self.R_AIN() < self.R_AINMAX
            and self.N_TP() >= self.N_TPMIN
            and self.V_TP() > V_IH
            and self.I_TPS() <= I_GPIO
        ):
            self.R_TP += step
        self.R_TP = eseries(self.R_TP - step, 24, "down")
        self.I_TP = self.I_TPS() * ((20 / self.PCLK) / (1 / 30))

    def N_TP(self) -> float:
        return math.floor(
            (1 << 12)
            * (self.R_AL * self.R_AL)
            / (
                self.R_TP * self.R_TP
                + 3 * self.R_TP
                + self.R_AL
                + self.R_AL * self.R_AL
            )
        )

    def V_TP(self) -> float:
        R_PD = 25e3  # STM32L011 Table 50
        return self.VDD * (R_PD) / (self.R_TP + R_PD + 2 * self.R_AH)

    def I_TPS(self) -> float:
        return self.VDD / (self.R_TP + self.R_AL)

    def R_AIN(self) -> float:
        return self.R_AH + 1 / (1 / self.R_AH + 2 / self.R_TP)


design = Design()


# Create the variables to be templated into DESIGN.md
variables = {
    "R_AL": fmt_value(Design.R_AL, "ohms"),
    "R_AH": fmt_value(Design.R_AH, "ohms"),
    "R_AIN": fmt_value(design.R_AINMAX, "ohms", 2),
    "N_TPMIN": str(Design.N_TPMIN),
    "R_TP": fmt_value(design.R_TP, "ohms"),
    "N_TP": str(design.N_TP()),
    "V_TP": fmt_value(design.V_TP(), "volts", 2),
    "I_TPS": fmt_value(design.I_TPS(), "amps", 2),
    "I_TP": fmt_value(design.I_TP, "amps", 2),
    "f_OLED_SCK": fmt_value(Design.f_OLED_SCK, "hz"),
}

# Takes in either an output file, or writes to stdout
if __name__ == "__main__":
    # Create the argument parser
    parse = argparse.ArgumentParser(
        prog="design",
        description="Finds parameters for the design and outputs a design document",
    )
    parse.add_argument("-o", "--output", type=str, required=False)
    args = parse.parse_args()

    # Get the output file
    output = None
    try:
        output = (
            io.open(args.output, "wt")
            if args.output is not None
            else sys.stdout
        )
    except OSError:
        print("Trouble opening file!")
        exit(-1)

    # Get the input file and use the templater
    try:
        input = io.open(
            os.path.join(os.path.dirname(sys.argv[0]), "DESIGN.md"), "r"
        )
        tmpl = Template(input.read())
        output.write(tmpl.substitute(**variables))
        input.close()
    except OSError:
        print("Trouble opening DESIGN.md!")
    except Exception:
        print("Trouble making the template!")

    # Output the readme and flush data
    output.flush()
    output.close()
