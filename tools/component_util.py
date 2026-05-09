#
# Small utility script for calculating component values
#
import math
from typing import Literal


#
# Converts a number into engineering notation for LaTeX
#
def fmt_engr(
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


#
# Returns the closest e-series value for a number
#
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


#
# Gets the value of resistors in parallel
#
def shunt(*args: float) -> float:
    return 1.0 / sum([1.0 / value for value in args])
