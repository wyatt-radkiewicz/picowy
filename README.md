# picowy Design Document
This is the design document for the picowy. This is made to be a thin, low power tomagachi like
device for my girlfriend. This design document goes over the basic system configuration and power
requirements. It enumerates every major system component. It does not go into detail about the
coding architecture or the physical design, those can be found in the firmware directory and the
chassis directory respectivly.

> *eklipsed, rev. 1.0.1*

## Table of Contents
1. [Accelerometer](#accelerometer)
2. [OLED Display](#oled-display)
3. [Microcontroller](#microcontroller)
4. [Touch Panel](#touch-panel)
5. [FTDI Firmware Flasher](#ftdi-firmware-flasher)
6. [Power System](#power-system)

## Accelerometer
> Ultra Low-Power 3 Axis Accelerometer
- Manufacturer - *STMicroelectronics*
- Part Number - *LIS2HH12TR*
- Datasheet - [LIS2HH12](hardware/datasheets/accel/lis2hh12.pdf)
- Application Notes - [AN4662](hardware/datasheets/accel/an4662.pdf)

This accelerometer provides real world physics feedback to the simulation.
The SPI interface is used to poll acceleration data per tick of the simulation.
This uses the **Block Data Update (BDU)** feature of the LIS2HH12 to poll
data from the OUT_(X, Y, Z)_(H, L) registers while having old data be overwritten
([AN4662 Section 3.1.3](hardware/datasheets/accel/an4662.pdf#page=14)). Only the newest
data is needed, samples can be skipped since no filtering on the MCU is used.

### Parameters
- $FS=\pm4.0g$ - Measurement range in *g*
([LIS2HH12 Table 3](hardware/datasheets/accel/lis2hh12.pdf#page=10)).
- $So=0.122\frac{mg}{lsb}$ - Sensitivity in OUT registers
([LIS2HH12 Table 3](hardware/datasheets/accel/lis2hh12.pdf#page=10)).
- $ODR=50\mathrm{Hz}$ - Output data rate.
- $I_{ddA}=110\mu\mathrm{A}$ - Current consumption
([LIS2HH12 Table 4](hardware/datasheets/accel/lis2hh12.pdf#page=11)).
- $PX_G=So\times\frac{9800 mm}{s^2 \times lsb}\times\frac{128 px}{20.14 mm}
\times\frac{s}{30 ticks}=253.3\frac{px}{tick^2 \times lsb}$ -
ODR LSB to px per tick^2 conversion rate (@ 30Hz simulation rate).
  - 20.14mm - Screen size
  ([ER-OLED1.12-2 Outline Drawing](hardware/datasheets/oled/er-oled1.12-2.pdf#page=6)).

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
([LIS2HH12 Section 1.2](hardware/datasheets/accel/lis2hh12.pdf#page=8))

## OLED Display
> 1.12" 128x128 Monochrome White OLED Display
- Manufacturer - *EastRising*
- Part Number - *ER-OLED1.12-2W*
- Datasheet - [ER-OLED1.12-2](hardware/datasheets/oled/er-oled1.12-2.pdf)
- Reference Implementation -
[er-oled1.12-2-interfacing](hardware/datasheets/oled/er-oled1.12-2-interfacing.pdf)
- Controller - [SH1107](hardware/datasheets/oled/sh1107.pdf)
- Connector Datasheet - [ZIF20PIN](hardware/datasheets/oled/er-con20ht-1.pdf)

This OLED has a SPI interface, which can be shared with the internal measurement unit.
The 4-Wire SPI interface is selected, where A0 represents the Data/Command bit. The way that
EastRising designed the display module means that the 12V rail msut be supplied externally.

### Parameters
- $f_{SCK} = \frac{PCLK}{2} = 1.05\mathrm{MHz}$ - SPI interface speed
  - The maximum speed on the OLED's SPI interface is around 4Mhz
  ([SH1107 AC Characteristics](hardware/datasheets/oled/sh1107.pdf#page=52)).
  - The STM32 peripheral (PCLK) clock is the bottleneck. The maximum
  SPI interface speed can be set to $\frac{PCLK}{2}$
  ([RM0377 Section 26.7.1](hardware/datasheets/stm32/rm0377.pdf#page=808)).
- $IPP + IREF = 48\mu \mathrm{A}$ - Current from 12V Rail
([ER-OLED1.12-2 Section 4.3](hardware/datasheets/oled/er-oled1.12-2.pdf#page=9))
- $IDD = 100\mu \mathrm{A}$ - Current from 3.3V Rail
([ER-OLED1.12-2 Section 4.3](hardware/datasheets/oled/er-oled1.12-2.pdf#page=9))

## Microcontroller
> Arm Cortex M0+ Microcontroller 16KB Flash 2KB RAM
- Manufacturer - *STMicroelectronics*
- Part Number - *STM32L011G4U6TR*
- Datasheet - [STM32L011](hardware/datasheets/stm32/stm32l011.pdf)
- Reference Manual - [RM0377](hardware/datasheets/stm32/rm0377.pdf)
- Bootloader Manual - [AN2606](hardware/datasheets/stm32/an2606.pdf)
- USART Bootloader Protocol Manual - [AN3155](hardware/datasheets/stm32/an3155.pdf)
- Programmer's Manual - [PM0223](hardware/datasheets/stm32/pm0223.pdf)

The main program will be a state machine where it runs all functions and then sleeps. This repeats
on a main $30\mathrm{Hz}$ timer.

### Power Mode and Clock Setup
- **Power Mode (VCORE)** - To save power *VCORE Range 3 (1.2V)* will be selected
[RM0377 Section 6.1.4](hardware/datasheets/stm32/rm0377.pdf#page=138).
- **System Clock (SYSCLK)** - SYSCLK will run from the MSI (Multispeed Internal) clock at
$2.1\mathrm{MHz}$ [RM0377 Section 7.2.3](hardware/datasheets/stm32/rm0377.pdf#page=174).
- **Peripherial Clock (PCLK)** - PCLK will be run at the same frequency of $2.1\mathrm{MHz}$.
- **Run Mode** -  When running with no peripherials on except FLASH, and interpolating data from
[STM32L011 Table 22](hardware/datasheets/stm32/stm32l011.pdf#page=53), around $300\mu\mathrm{A}$ is
consumed while running.
- **Sleep Mode** - When in sleep mode running at $65\mathrm{kHz}$ and without FLASH, around
$26.5\mu\mathrm{A}$ is consumed
[STM32L011 Table 26](hardware/datasheets/stm32/stm32l011.pdf#page=56).

### States
#### 1. Wakeup
LPTIM1 is running at $30\mathrm{Hz}$, and wakes up the system.
Driven off of the stable LSI (Low Speed Internal) clock source so that MSI can be changed during
operation. System sets MSI clock back to $2.1\mathrm{MHz}$.
- **Required Peripherials:** PWR, FLASH, LPTIM1
- **Power Consumption:** $300\mu\mathrm{A} + 36.0\mu\mathrm{A} = 336.0\mu\mathrm{A}$
- **Average Runtime $\approx 0.266\mathrm{ms}$**
  - 8 cycles at 65kHz [STM32L011 Section 6.3.5](hardware/datasheets/stm32/stm32l011.pdf#page=62)
  - N cycles at 2.1Mhz (Somewhere in the 100-200 cycles range)

#### 2. Poll Touch Screen
First it runs the *Sense* operation to see if the touch screen is being touched, and only if there
is touch detected does it start up ADC1 and run the *X Pos* and *Y Pos* modes. ADC1 is configured
to run with 1.5 sample time and to run off of the PCLK with 12 bit resolution.
- **Required Peripherials:** PWR, FLASH, LPTIM1, ADC1, GPIO
- **Power Consumption:** $300\mu\mathrm{A} + 61.2\mu\mathrm{A} = 361.2\mu\mathrm{A}$
- **Average Runtime $\approx 0.122\mathrm{ms}$**
  - $1\mu\mathrm{s}$ ADC Power up Time
  [STM32L011 Table 54](hardware/datasheets/stm32/stm32l011.pdf#page=81)
  - $2\times\left(12.5 + 1.5\right)\times\frac{1}{1.05\mathrm{Mhz}}=27\mu\mathrm{s}$
  2 ADC Sample Times [STM32L011 Table 54](hardware/datasheets/stm32/stm32l011.pdf#page=81)
  - N cycles at 2.1Mhz (Somewhere in the 100-200 cycles range)

#### 3. Poll Accelerometer
SPI1 should use $CPOL=1, CPHA=1$ when communicating with the accelerometer. ODR_(X, Y, Z)_(H, L) is
read and converted into *px/tick^2* using the accelerometer's communitcation protocol
[LIS2HH12 Section 6.2](hardware/datasheets/accel/lis2hh12.pdf#page=25). With this protocol,
the ODR_X_L register can be read, and then the rest can follow with DMA1 clocking the SCK signal
for the rest.
- **Required Peripherials:** PWR, FLASH, LPTIM1, SPI1, DMA1, GPIO
- **Power Consumption:** $300\mu\mathrm{A} + 68.6\mu\mathrm{A} = 368.6\mu\mathrm{A}$
- **Average Runtime $\approx 0.291\mathrm{ms}$**
  - 56 SPI cycles
  - N cycles at 2.1Mhz (500 cycles range)

#### 4. Update Simulation
The simulation will use a state machine for the character, and the character will be affected by
the external acceleration seen by the accelerometer, and the touch sensor. It will update the
internal screen bitmap for the next step.
- **Required Peripherials:** PWR, FLASH, LPTIM1
- **Power Consumption:** $300\mu\mathrm{A} + 36.0\mu\mathrm{A} = 336.0\mu\mathrm{A}$
- **Average Runtime $\approx 4.76\mathrm{ms}$**
  - N cycles at 2.1Mhz (10,000 cycles budget)

#### 5. Update Screen
Since the 128x128 screen is too large to fit into 2KB RAM, work arounds are needed. A sprite based
approach with X, Y, W, H pairs and a reference to the bitmap in FLASH works, and with a system that
knows where sprites were previously, full screen rewrites are not needed. Even if a full screen
refresh was needed, it would only take under $18\mathrm{ms}$ when SPI1 runs at full speed
($1.05\mathrm{MHz}$).
- **Required Peripherials:** PWR, FLASH, LPTIM1, SPI1, DMA1, GPIO
- **Power Consumption:** $300\mu\mathrm{A} + 60.3\mu\mathrm{A} = 360.3\mu\mathrm{A}$
- **Average Runtime $\approx 6.19\mathrm{ms}$**
  - 4000 SPI1 cycles (Assuming 1/4 of screen is refreshed)
  - N cycles at 2.1Mhz (5,000 cycles budget)

#### 6. Sleep
This sets the MSI clock to $65\mathrm{kHz}$, disables relevant clock
blocks and peripherals, and exits the LPTIM1 interrupt to go back into sleep mode.
- **Required Peripherials:** PWR, FLASH, LPTIM1
- **Power Consumption:** $26.5\mu\mathrm{A} + 36.0\mu\mathrm{A} = 62.5\mu\mathrm{A}$

### Average Power Consumption
- Time in *Run* mode: $11.7\mathrm{ms}$
- Average current: $360\mu\mathrm{A}\times\frac{11.7}{33.33}+70\mu\mathrm{A}\times
\frac{21.63}{33.33}\approx172\mu\mathrm{A}$

### Debug Connector
> Tag Connect 2030 Solderless Connection
- Manufacturer - *Tag-Connect*
- Part Number - *TC2030*
- Datasheet - [TC2030](hardware/datasheets/conn/tc2030.pdf)

The TC2030 will be connected the STM32's SWCLK, SWDIO, 3.3V, GND, NRST. NRST will be pulled up to
$V_{DD}$. This will use the Serial Wire Debug (SWD) protocol.

## Touch Panel
> 1.44" 4 Wire Resistive Touch Screen
- Manufacturer - *EastRising*
- Part Number - *ER-TP1.44-1*
- Datasheet - [ER-TP1.44-1](hardware/datasheets/touch/er-tp1.44-1.pdf)

The datasheet doesn't contain any info on axis resistance. Design is made around that limitation,
but still the minimum and maximum allowed for the design will be selected for
$300\Omega-600\Omega$. The touch panel circuitry uses no current if the panel is not being touched.

### Diagram
- $R_{AX}$ is the axis resistance, anywhere between the minimum and maximum.
- $R_{TP}$ is current limiting resistor $R_{TP}$.
- *XL*, *YU*, *XR*, *YD* are connected to the STM32's GPIO pins.
```
   Inside TP    . To GPIO
                .
  +--------------------- XL
  |             .
  |      +-------------- YU
  |      |      .
  |     R_AX    .
  |      |      .
  +-R_AX-?-R_AX---R_TP-- XR
         |      .
        R_AX    .
         |      .
         +--------R_TP-- YD
                .
```

### Parameters
- $R_{PD} >= 25k\Omega$ - Minimum pulldown resistor value
([STM32L011 Table 50](hardware/datasheets/stm32/stm32l011.pdf#page=75)).
- $I_{MAX}=2\mathrm{mA}$

### Operation Modes
When sleeping, the touch panel GPIO is all set to Input (*no* pullup/down). This configuration
consumes no current.

#### Touch Sense
| Pin | State             |
|-----|-------------------|
| XL  | Out Push-Pull, HI |
| XR  | HZ                |
| YU  | In Pull-Down      |
| YD  | HZ                |
- $I_{TP}=\frac{V_{DD}}{R_{PD}}=0.132\mathrm{mA}$ - GPIO source/sink current (if pressed)
- $V_{TP}=V_{DD}\frac{R_{PD}}{2R_{AX}+R_{IA}+R_{PD}}=3.03\mathrm{V}$ - Touch sense level
  - $R_{IA}$ - Inter-axis touch resistance ($0-1000\Omega$)

#### X/Y Position Reading
| State | XL                | XR                | YU                | YD                |
|-------|-------------------|-------------------|-------------------|-------------------|
| X Pos | Out Push-Pull, LO | Out Push-Pull, HI | ADC In            | HZ                |
| Y Pos | ADC In            | HZ                | Out Push-Pull, LO | Out Push-Pull, HI |

$R_{TP} = 1.4\mathrm{k}\Omega$ - What to use for $R_{TP}$ since only these modes use it
- $R_{TP} > \frac{V_{DD}}{I_{MAX}}-R_{AX}$ - What to select for $R_{TP}$ to keep current low

## FTDI Firmware Flasher
> USB to UART Bridge for Firmware Flashing
- Manufacturer - *FTDI, Future Technology Devices International Ltd*
- Part Number - *FT260Q-T*
- Datasheet - [FT260](hardware/datasheets/ftdi/ft260.pdf)
- Application Notes - [AN394](hardware/datasheets/ftdi/an394.pdf)

This will be used to boot the STM32 into the USART Boot Loader
([AN3155](hardware/datasheets/stm32/an3155.pdf)). Two GPIOs will be used on the FT260, one to
assert NRST on the STM32, and the other to assert the BOOT0 pin on the STM32 to get it into
bootloader mode [AN2606 Table 2](hardware/datasheets/stm32/an2606.pdf#page=34). For this,
nBOOT_SEL must be 0 [RM0377 Section 3.7.8](hardware/datasheets/stm32/rm0377.pdf#page=110).

Support for an external EEPROM configuration chip for the FT260 will be made by making a space
for it on the PCB (need not be populated). This EEPROM chip communicates over $\mathrm{I^2C}$
[FT260 Section 9](hardware/datasheets/ftdi/ft260.pdf#page=44).

### Parameters
- $DCNF1 = 1, DCNF0 = 0$ - Only USART interface is enabled
[FT260 Section 5.1](hardware/datasheets/ftdi/ft260.pdf#page=17)
- $PARITY = EVEN$ [AN3155 Section 3](hardware/datasheets/stm32/an3155.pdf#page=9)
- $Baud\;Rate = 115200$ [AN3155 Section 2.2](hardware/datasheets/stm32/an3155.pdf#page=7)

## Power System
There are 3 distinct power rails, VBUS, 3V3, and 12V. The devices connected to each are:
| RAIL | DEVICES         | CURRENT                                                                                                       |
|------|-----------------|---------------------------------------------------------------------------------------------------------------|
| VBUS | FT260           | $9.6\mathrm{mA}$ [FT260 Table Section 6.3](hardware/datasheets/ftdi/ft260.pdf#page=29)                        |
|      | Battery Charger | $50\mathrm{mA}$ Set by $EN1=HI,EN2=LO$ [BQ24230 Section 7.5](hardware/datasheets/charger/bq24230.pdf#page=9)  |
| 3V3  | STM32           | $172\mu\mathrm{A}$ [STM32 Average Power Consumption](#microcontroller)                                        |
|      | OLED            | $100\mu\mathrm{A}$ [OLED Display 3V3 Current](#oled-display)                                                  |
|      | Accelerometer   | $110\mu\mathrm{A}$ [Accelerometer Current](#accelerometer)                                                    |
| 12V  | OLED Driver     | $32\mu\mathrm{A}$ [OLED Display Driver 12V Current](#oled-display)                                            |

The rated battery charging rate and lack of circuitry needed to negociate USB Battery Charging or
Power Delivery means that the battery charger will have an input current limit of $50\mathrm{mA}$.

With the selected parts, the 3V3 rail draws $1.4\mathrm{mW}$ because of the LDO. The 12V rail draws
$1.2\mathrm{mW}$ due to the $\approx50\%$ efficiency. This means the battery will be sourcing
around $0.7\mathrm{mA}$.

### Battery <TODO>
> 3.7V Thin Lithium Ion Battery Rechargeable
- Manufacturer - *GlobTek, Inc.*
- Part Number - *BL0105F2635161S1PCAT*
- Datasheet - [BL0105F2635161S1PCAT](hardware/datasheets/battery/battery.pdf)

Is very thin $2.8\mathrm{mm}$ thick battery, with thin connector. Stay in the $50\mathrm{mA}$ range
for charging [BL0105F2635161S1PCAT Section 3](hardware/datasheets/battery/battery.pdf#page=3).

#### Male Connector (PCB Side)
- Manufacturer - *Hirose Electric Co Ltd*
- Part Number - *DF65-3P-1.7V(21)*
- Drawing - [DF65-3P-1.7V-21](hardware/datasheets/conn/df65-3p-1.7v-21.pdf)

### Battery Charger
> Battery Charger and Power Path Managment
- Manufacturer - *Texas Instruments*
- Part Number - *BQ24230RGTR*
- Datasheet - [BQ24230](hardware/datasheets/charger/bq24230.pdf)

Using this power path battery charger, it allows instant on from a dead battery. Use custom current
limit though external resistor to give some room for the FT260 to also source current on VBUS and
to not charge the battery at its max all the time.

### Fuel Gauge
> System Side Impeadance Track Fuel Gauge
- Manufacturer - *Texas Instruments*
- Part Number - *BQ27426YZFR*
- Datasheet - [BQ27426](hardware/datasheets/gauge/bq27426.pdf)
- Technical Reference - [SLUUBB0](hardware/datasheets/gauge/sluubb0.pdf)

This is an optional component, and can be added to the $\mathrm{I^2C}$ bus on the STM32 to measure
how much battery is left and how much current the system consumes.

### 3V3 Rail
> Low Noise LDO Voltage Regulator
- Manufacturer - *Texas Instruments*
- Part Number - *TPS7A2033PDBVR*
- Datasheet - [TPS7A20](hardware/datasheets/ldo/tps7a20.pdf)

As shown the in part number, *TPS7A20***33***PDBVR* is a 3.3V low noise, low $I_Q$ LDO for
the 3.3V rail.

### 12V Rail
> Power Step-Up DC-DC Converter
- Manufacturer - *Texas Intruments*
- Part Number - *TPS61040DDCR*
- Datasheet - [TPS61040](hardware/datasheets/boost/tps61040.pdf)

The boost converter suggested by the reference implementation for the OLED. Will have around a
70% efficency a the OLED's advertised current.
