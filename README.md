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
- $f_{SCK} = \frac{PCLK}{2} = 1.05\mathrm{MHz}$ - SPI interface speed
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
> Arm Cortex M0+ Microcontroller 16KB Flash 2KB RAM
- Manufacturer - *STMicroelectronics*
- Part Number - *STM32L011G4U6TR*
- Datasheet - [STM32L011](hardware/datasheets/stm32l011.pdf)
- Reference Manual - [RM0377](hardware/datasheets/rm0377.pdf)

The main program will be a state machine where it runs all functions and then sleeps. This repeats
on a main $30\mathrm{Hz}$ timer.

### Power Mode and Clock Setup
- **Power Mode (VCORE)** - To save power *VCORE Range 3 (1.2V)* will be selected
[RM0377 Section 6.1.4](hardware/datasheets/rm0377.pdf#page=138).
- **System Clock (SYSCLK)** - SYSCLK will run from the MSI (Multispeed Internal) clock at
$2.1\mathrm{MHz}$ [RM0377 Section 7.2.3](hardware/datasheets/rm0377.pdf#page=174).
- **Peripherial Clock (PCLK)** - PCLK will be run at the same frequency of $2.1\mathrm{MHz}$.
- **Run Mode** -  When running with no peripherials on except FLASH, and interpolating data from
[STM32L011 Table 22](hardware/datasheets/stm32l011.pdf#page=53), around $300\mu\mathrm{A}$ is
consumed while running.
- **Sleep Mode** - When in sleep mode running at $65\mathrm{kHz}$ and without FLASH, around
$26.5\mu\mathrm{A}$ is consumed [STM32L011 Table 26](hardware/datasheets/stm32l011.pdf#page=56).

### States
#### 1. Wakeup
LPTIM1 is running at $30\mathrm{Hz}$, and wakes up the system.
Driven off of the stable LSI (Low Speed Internal) clock source so that MSI can be changed during
operation. System sets MSI clock back to $2.1\mathrm{MHz}$.
- **Required Peripherials:** PWR, FLASH, LPTIM1
- **Power Consumption:** $300\mu\mathrm{A} + 36.0\mu\mathrm{A} = 336.0\mu\mathrm{A}$
- **Average Runtime $\approx 0.266\mathrm{ms}$**
  - 8 cycles at 65kHz [STM32L011 Section 6.3.5](hardware/datasheets/stm32l011.pdf#page=62)
  - N cycles at 2.1Mhz (Somewhere in the 100-200 cycles range)

#### 2. Poll Touch Screen
First it runs the *Sense* operation to see if the touch screen is being touched, and only if there
is touch detected does it start up ADC1 and run the *X Pos* and *Y Pos* modes. ADC1 is configured
to run with 1.5 sample time and to run off of the PCLK with 12 bit resolution.
- **Required Peripherials:** PWR, FLASH, LPTIM1, ADC1, GPIO
- **Power Consumption:** $300\mu\mathrm{A} + 61.2\mu\mathrm{A} = 361.2\mu\mathrm{A}$
- **Average Runtime $\approx 0.122\mathrm{ms}$**
  - $1\mu\mathrm{s}$ ADC Power up Time
  [STM32L011 Table 54](hardware/datasheets/stm32l011.pdf#page=81)
  - $2\times\left(12.5 + 1.5\right)\times\frac{1}{1.05\mathrm{Mhz}}=27\mu\mathrm{s}$
  2 ADC Sample Times [STM32L011 Table 54](hardware/datasheets/stm32l011.pdf#page=81)
  - N cycles at 2.1Mhz (Somewhere in the 100-200 cycles range)

#### 3. Poll Accelerometer
SPI1 should use $CPOL=1, CPHA=1$ when communicating with the accelerometer. ODR_(X, Y, Z)_(H, L) is
read and converted into *px/tick^2* using the accelerometer's communitcation protocol
[LIS2HH12 Section 6.2](hardware/datasheets/lis2hh12.pdf#page=25). With this protocol, the ODR_X_L
register can be read, and then the rest can follow with DMA1 clocking the SCK signal for the rest.
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

## Touch Panel
> 1.44" 4 Wire Resistive Touch Screen
- Manufacturer - *EastRising*
- Part Number - *ER-TP1.44-1*
- Datasheet - [er-tp1.44-1](hardware/datasheets/er-tp1.44-1.pdf)

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
([STM32L011 Table 50](hardware/datasheets/stm32l011.pdf#page=75)).
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

## Debugging

### Serial Wire Debug

### FTDI - STM32 USART Bootloader

## Power Supply

### Main System Current Draw

### 12V Supply

### 3V Supply

### Battery Management

