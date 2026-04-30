# PICOWY Design Document

## Touch Panel Controller
> 1.44" 4 Wire Resistive Touch Screen
- Manufacturer - *EastRising*
- Part Number - *ER-TP1.44-1*
- [Datasheet](hardware/datasheets/er-tp1.44-1.pdf)

The datasheet doesn't contain any info on the axis resistance. So a minimum and maximum
touch panel resistance is chosen as:
- $R_{TPMIN} = 200 \Omega$
- $R_{TPMAX} = 4k \Omega$

### Diagram
- *R* is the axis resistance, anywhere between the minimum and maximum.
- *T* is current limiting resistance.
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
  +--R-----R------------ XR
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

### Microcontroller Configuration


### Current Consumption
The touch panel is the only input device that requires the use of the STM32's ADC peripherial.


