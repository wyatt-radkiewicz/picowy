#
# Small helper utility to calculate all of the touch panel parameters
#
import math
from component_util import fmt_engr, eseries, shunt

# Params given
T_S = 1.5  # ADC sampling time
f_ADC = 1.05e6  # ADC clock source
N = 12  # ADC resolution in bits
R_ADC = 1e3  # ADC switching resistance
C_ADC = 8e-12  # Internal ADC sample and hold capacitor
VDD = 3.3  # Digital voltage supply level
R_PD = 25e3  # Minimum GPIO pull down resistance
I_GPIO_MAX = 8e-3  # Maximim GPIO current

# Calculating for:
R_TP = 1

# Constraints
R_AL = 100
R_AH = 4e3
MIN_N_TP = 96
MIN_V_TP = 0.7 * VDD
MAX_I_TP_MAX = 6e-3
MAX_R_AIN = T_S / (f_ADC * C_ADC * math.log(1 << (N + 2))) - R_ADC


def V_TP():
    return VDD * R_PD / (R_TP + 2 * R_AH + R_PD)


def I_TP_MAX():
    return VDD / (R_TP + R_AL)


def N_TP():
    return math.floor(
        (1 << N) * (R_AL * R_AL) / (R_TP * R_TP + 3 * R_TP * R_AL + R_AL * R_AL)
    )


def R_AIN():
    return R_AH + shunt(R_AH, R_TP, R_TP)


# Calculating R_TP
# Keep increasing R_TP until we satisfy all contraints
def valid():
    return (
        V_TP() > MIN_V_TP
        and N_TP() >= MIN_N_TP
        and I_TP_MAX() < MAX_I_TP_MAX
        and R_AIN() < MAX_R_AIN
    )


while not valid():
    R_TP += 1
    if R_TP > 1e6:
        print("No solution found")
        exit(-1)
R_TP = eseries(R_TP, 24)

# Print results
print(f"R_TP = {fmt_engr(R_TP, 'ohms', 1)}")
print(f"V_TP = {fmt_engr(V_TP(), 'volts', 2)}")
print(f"N_TP = {N_TP()}")
print(f"I_TP = {fmt_engr(I_TP_MAX() * (50 / 1.05e6) / (1 / 30), 'amps', 2)}")
print(f"I_TP_MAX = {fmt_engr(I_TP_MAX(), 'amps', 2)}")
