# PICOWY Design Document

## Accelerometer
> Ultra Low-Power 3 Axis Accelerometer
- Manufacturer - *STMicroelectronics*
- Part Number - *LIS2HH12*
- Datasheet - [lis2hh12](hardware/datasheets/lis2hh12.pdf)
- Application Notes - [an4662](hardware/datasheets/an4662.pdf)

This accelerometer provides real world physics feedback to the simulation.
The SPI interface is used to poll acceleration data per tick of the simulation.
This uses the **Block Data Update (BDU)** feature of the LIS2HH12 to poll
data from the OUT_(X, Y, Z)_(H, L) registers while having old data be overwritten
([AN4662 Section 3.1.3](hardware/datasheets/an4662.pdf#page=14)). Only the newest
data is needed, samples can be skipped since no filtering on the MCU is used.

### Parameters
- $FS=\pm4.0g$ - Measurement range in *g*
([LIS2HH12 Table 3](hardware/datasheets/lis2hh12.pdf#page=10)).
- $So=0.122\frac{mg}{lsb}$ - Sensitivity in OUT registers
([LIS2HH12 Table 3](hardware/datasheets/lis2hh12.pdf#page=10)).
- $ODR=50\mathrm{Hz}$ - Output data rate.
- $I_{ddA}=110\mu\mathrm{A}$ - Current consumption
([LIS2HH12 Table 4](hardware/datasheets/lis2hh12.pdf#page=11)).
- $PX_G=So\times\frac{9800 mm}{s^2 \times lsb}\times\frac{128 px}{20.14 mm}
\times\frac{s}{30 ticks}=253.3\frac{px}{tick^2 \times lsb}$ -
ODR LSB to px per tick^2 conversion rate (@ 30Hz simulation rate).
  - 20.14mm - Screen size
  ([ER-OLED1.12-2 Outline Drawing](hardware/datasheets/er-oled1.12-2.pdf#page=6)).

### Physics Integration
Projecting the accelerometer data onto the screen's X-Y plane is as simple as only converting
the ODR_X_HL and ODR_Y_HL registers into the screen's units and ignoring ODR_Z_HL. Multiply
ODR_X_HL and ODR_Y_HL by $PX_G$ to get the acceleration values used in the physics simulation.

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
- $f_{SCK} = \frac{PCLK}{2} = 525\mathrm{kHz}$ - SPI interface speed
  - The maximum speed on the OLED's SPI interface is around 4Mhz
  ([SH1107 AC Characteristics](hardware/datasheets/sh1107.pdf#page=52)).
  - The STM32 peripheral (PCLK) clock is the bottleneck. The maximum
  SPI interface speed can be set to $\frac{PCLK}{2}$
  ([RM0377 Section 26.7.1](hardware/datasheets/rm0377.pdf#page=808)).
- $IPP + IREF = 48\mu \mathrm{A}$ - Current from 12V Rail
([ER-OLED1.12-2 Section 4.3](hardware/datasheets/er-oled1.12-2.pdf#page=9))
- $IDD = 100\mu \mathrm{A}$ - Current from 3.3V Rail
([ER-OLED1.12-2 Section 4.3](hardware/datasheets/er-oled1.12-2.pdf#page=9))

## Microcontroller

## Touch Panel
**REMOVE EVERYTHING and start over, this is wayy to overengineered, and as found out at the end
the actual current is so low in the first place**
> 1.44" 4 Wire Resistive Touch Screen
- Manufacturer - *EastRising*
- Part Number - *ER-TP1.44-1*
- Datasheet - [er-tp1.44-1](hardware/datasheets/er-tp1.44-1.pdf)

The datasheet doesn't contain any info on the axis resistance. The design will be made around the
minimum and maximum axis resistances: $R_{AL} = 100\Omega, R_{AH} = 4\mathrm{k}\Omega$. Since
the touch panel sensing circutry does not consume current when the panel is not touched, the
main parameter to optimize for is sensing voltage level and number of unique ADC levels.

### Diagram
- *R* is the axis resistance, anywhere between the minimum and maximum.
- *T* is current limiting resistor $R_{TP}$.
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

### Parameters
**Current Limiting Resistor** $R_{TP}=470\Omega$
- $T_S=1.5$ - ADC sampling time
([RM0377 Section 13.3.9](hardware/datasheets/rm0377.pdf#page=289)).
- $f_{ADC}=1.05\mathrm{MHz}$ - ADC clock source
([RM0377 Section 13.3.5](hardware/datasheets/rm0377.pdf#page=285)).
- $N=12$ - ADC resolution in bits.

**Sense Trigger Level** $V_{TP} = VDD \frac{R_{PD}}{R_{TP} + 2 R_{AH} + R_{PD}} = 2.46V$
- $R_{PD} >= 25k\Omega$ - Minimum pulldown resistor value
([STM32L011 Table 50](hardware/datasheets/stm32l011f3.pdf#page=75)).
- $V_{IH} = 0.7 VDD = 2.31\mathrm{V}$ - Voltage input high, minimum sense trigger level
([STM32L011 Table 50](hardware/datasheets/stm32l011f3.pdf#page=75)).

**Sense Current Consumption** $I_{TP}=8.27\mu \mathrm{A}$
- $\pm8\mathrm{mA}$ - GPIO max sink/source current.
([STM32L011 Section 6.3.13 Page 76](hardware/datasheets/stm32l011f3.pdf#page=76)).
- $I_{TP\_MAX}=5.79\mathrm{mA}$ - Max peak sense current.
- $I_{TP}=\frac{VDD}{R_{TP}+R_{AL}}\frac{50 \cdot 1.05\mathrm{MHz}}{1/30}$ - Average sensing current
consumption (poll rate @ 30Hz).

**Unique ADC Input Levels** $N_{TP} = 110$
- $N_{TP} = 2^N * \frac{R_{AL}^2}{R_{TP}^2+3R_{TP}R_{AL}+R_{AL}^2}$

**Max ADC Input Impedance** $R_{AIN}<17.4\mathrm{k}\Omega$
- $R_{AIN}<\frac{T_S}{f_{ADC} C_{ADC} \ln(2^{N+2})}-R_{ADC}$
([STM32L011 Section 6.3.15 Page 81](hardware/datasheets/stm32l011f3.pdf#page=81)).
- $R_{AIN}=R_{AH}+R_{AH} \parallel R_{TP} \parallel R_{TP}$ - Input resistance in worst case
configuration.

## Debugging

### Serial Wire Debug

### FTDI - STM32 USART Bootloader

## Power Supply

### Main System Current Draw

### 12V Supply

### 3V Supply

### Battery Management

