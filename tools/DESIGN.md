# PICOWY Design Document

## Accelerometer
> Ultra Low-Power 3 Axis Accelerometer
- Manufacturer - *STMicroelectronics*
- Part Number - *LIS2HH12*
- Datasheet - [lis2hh12](hardware/datasheets/lis2hh12.pdf)
- Application Notes - [an4662](hardware/datasheets/an4662.pdf)

This accelerometer provides real world physics feedback to the simulation.
The SPI interface is used to poll acceleration data per tick of the simulation.
This uses the Block Data Update (BDU) feature of the LIS2HH12 to poll
data from the OUT_(X, Y, Z)_(H, L) registers while having old data be overwritten
([AN4662 Section 3.1.3](hardware/datasheets/an4662.pdf#page=14)). Only the newest
data is needed, samples can be skipped since no filtering on the MCU is used.

### Parameters
- $$FS=\pm4.0g$$ - Measurement range in *g*
([LIS2HH12 Table 3](hardware/datasheets/lis2hh12.pdf#page=10)).
- $$So=0.122\frac{mg}{lsb}$$ - Sensitivity in OUT registers
([LIS2HH12 Table 3](hardware/datasheets/lis2hh12.pdf#page=10)).
- $$ODR=50\mathrm{Hz}$$ - Output data rate.
- $$I_{ddA}=110\mu\mathrm{A}$$ - Current consumption
([LIS2HH12 Table 4](hardware/datasheets/lis2hh12.pdf#page=11)).
- $$PX_G=So\times\frac{9800 mm}{s^2 \times lsb}\times\frac{128 px}{20.14 mm}
\times\frac{s}{30 ticks}=253.3\frac{px}{tick^2 \times lsb}$$ -
ODR LSB to px per tick^2 conversion rate (@ 30Hz simulation rate).
  - 20.14mm - Screen size
  ([ER-OLED1.12-2 Outline Drawing](hardware/datasheets/er-oled1.12-2.pdf#page=6)).

### Physics Integration
1. Project the $$\langle \mathrm{ODR\_X\_HL}, \mathrm{ODR\_Y\_HL}, \mathrm{ODR\_Z\_HL} \rangle$$
accelerometer data onto the $$\langle 1, 0, 0 \rangle \cdot PX_G, \langle 0, 1, 0 \rangle
\cdot PX_G$$ plane. This both converts units and projects in two simple dot products.
2. Use the new X, and Y acceleration values in the physics simulation.
Pictured below is the physical configuration of the accelerometer, where 1 is the first pin.
```
                 ^ z
                 |
               _-|-_
            _-" 1|  "-_
         _-"     |     "-_
       +-_     _-'-_     _-+
       |  "-_-"     "-_-"  |
       +-_-" "-_   _-" "-_-+
      _-" "-_   "+"   _-" "-_
  y <"       "-_ | _-"       "> x
                "+"
```
([LIS2HH12 Section 1.2](hardware/datasheets/lis2hh12.pdf#page=8))

## OLED Display
> 1.12" 128x128 Monochrome White OLED Display
- Manufacturer - *EastRising*
- Part Number - *ER-OLED1.12-2W*
- Datasheet - [er-oled1.12-2](hardware/datasheets/er-oled1.12-2.pdf)
- Reference Implementation - [er-oled1.12-2-interfacing](hardware/datasheets/er-oled1.12-2-interfacing.pdf)
- Controller - [sh1107](hardware/datasheets/sh1107.pdf)

This OLED has a SPI interface, which can be shared with the internal measurement unit.
The 4-Wire SPI interface is selected, where A0 represents the Data/Command bit. The way that
EastRising designed the display module means that the 12V rail msut be supplied externally.

### Parameters
- $$f_{SCK} = \frac{PCLK}{2} = ${f_OLED_SCK}$$ - SPI interface speed
  - The maximum speed on the OLED's SPI interface is around 4Mhz
  ([SH1107 AC Characteristics](hardware/datasheets/sh1107.pdf#page=52)).
  - The STM32 peripheral (PCLK) clock is the bottleneck. The maximum
  SPI interface speed can be set to $$\frac{PCLK}{2}$$
  ([RM0377 Section 26.7.1](hardware/datasheets/rm0377.pdf#page=808)).
- $$IPP + IREF = 48\mu \mathrm{A}$$ - Current from 12V Rail
([ER-OLED1.12-2 Section 4.3](hardware/datasheets/er-oled1.12-2.pdf#page=9))
- $$IDD = 100\mu \mathrm{A}$$ - Current from 3.3V Rail
([ER-OLED1.12-2 Section 4.3](hardware/datasheets/er-oled1.12-2.pdf#page=9))

## Microcontroller

## Touch Panel
> 1.44" 4 Wire Resistive Touch Screen
- Manufacturer - *EastRising*
- Part Number - *ER-TP1.44-1*
- Datasheet - [er-tp1.44-1](hardware/datasheets/er-tp1.44-1.pdf)

The datasheet doesn't contain any info on the axis resistance. So the minimum and maximum
touch panel resistance is chosen as:
- $$R_{AL} = ${R_AL}$$
- $$R_{AH} = ${R_AH}$$

### Diagram
- *R* is the axis resistance, anywhere between the minimum and maximum.
- *T* is current limiting resistor $$R_{TP}$$.
- *XL*, *YU*, *XR*, *YD* are connected to the STM32's GPIO pins.
```
   Inside TP  .  To GPIO
              .
  +----------------T---- XL
  |           .
  |     +----------T---- YU
  |     |     .
  |     R     .
  |     |     .
  +--R--?--R------------ XR
        |     .
        R     .
        |     .
        +--------------- YD
              .
```

### Operation Modes
There are 4 operation modes:
| State | XL | XR     | YU         | YD     |
|-------|----|--------|------------|--------|
| Sleep | HZ | HZ     | HZ         | HZ     |
| Sense | HZ | HI     | DIGITAL RD | HZ     |
| X Pos | LO | HI     | HZ         | ADC RD |
| Y Pos | HZ | ADC RD | HI         | LO     |

### Design Constraints
**Constraints:**
- Max ADC input impedance
([STM32L011 Section 6.3.15 Page 81](hardware/datasheets/stm32l011f3.pdf#page=81))
  - $$R_{AIN}<\frac{T_S}{f_{ADC} C_{ADC} \ln(2^{N+2})}-R_{ADC}$$
  - $$R_{AIN}<${R_AIN}$$
  - Where:
    - $$T_S=1.5$$ - ADC sampling time
    ([RM0377 Section 13.3.9](hardware/datasheets/rm0377.pdf#page=289))
    - $$f_{ADC}=1.05M\mathrm{Hz}$$ - ADC clock source
    ([RM0377 Section 13.3.5](hardware/datasheets/rm0377.pdf#page=285))
    - $$N=12$$ - ADC resolution in bits
    - $$R_{ADC}=1k\Omega$$ - ADC Sampler switching resistance
    ([STM32L011 Table 54](hardware/datasheets/stm32l011f3.pdf#page=80))
- Unique ADC input levels
  - $$N_{TP} = 2^N * \frac{R_{AL}^2}{R_{TP}^2+3R_{TP}R_{AL}+R_{AL}^2}$$
  - $$N_{TP} > ${N_TPMIN}$$
- Sense trigger level
  - $$VDD \frac{R_{PD}}{R_{TP} + 2 R_{AH} + R_{PD}} > V_{IH}$$
  - $$R_{PD} >= 25k\Omega$$ - Minimum pulldown resistor value
  ([STM32L011 Table 50](hardware/datasheets/stm32l011f3.pdf#page=75))
  - $$V_{IH} = 0.7 VDD = 2.31\mathrm{V}$$ - Voltage input high
  ([STM32L011 Table 50](hardware/datasheets/stm32l011f3.pdf#page=75))
- GPIO max sink/source current
([STM32L011 Section 6.3.13 Page 76](hardware/datasheets/stm32l011f3.pdf#page=76))
  - $$\pm8mA$$
  - Keeping this low also makes the output HI level more stable/higher when sensing.

**Optimize For:**
$$I_{TP}=\frac{VDD}{R_{TP}+R_{AL}}$$ - *XR* max current (uses minimum axis resistance).

### Parameters
- $$R_{TP}=${R_TP}$$ - Current limiting resistor
- $$N_{TP}=${N_TP}$$ - Number of unique ADC levels
- $$V_{TP}=${V_TP}$$ - Sense trigger level
- $$I_{TPS}=${I_TPS}$$ - Sense current (no current if there is no touch detected)
- $$I_{TP}=${I_TP}$$ - Average sense current @ 30Hz poll rate

## Debugging

### Serial Wire Debug

### FTDI - STM32 USART Bootloader

## Power Supply

### Main System Current Draw

### 12V Supply

### 3V Supply

### Battery Management

