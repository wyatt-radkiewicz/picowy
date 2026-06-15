//! Hardware Interface
pub const nvic = @import("stm32l0/nvic.zig");
pub const cpu = @import("stm32l0/cpu.zig");
pub const adc = @import("stm32l0/adc.zig");
pub const dma = @import("stm32l0/dma.zig");
pub const flash = @import("stm32l0/flash.zig");
pub const gpio = @import("stm32l0/gpio.zig");
pub const i2c = @import("stm32l0/i2c.zig");
pub const linke = @import("stm32l0/linker.ld");
pub const lptim = @import("stm32l0/lptim.zig");
pub const pwr = @import("stm32l0/pwr.zig");
pub const rcc = @import("stm32l0/rcc.zig");
pub const regs = @import("stm32l0/regs.zig");
pub const spi = @import("stm32l0/spi.zig");
