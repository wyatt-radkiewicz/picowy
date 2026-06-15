//! Reset and Clock Control Subsystem
const std = @import("std");
const regs = @import("regs.zig");

/// RM0377 Section 7.2 "Clocks"
pub const ClockSource = enum {
    /// RM0377 Section 7.2.1 "HSE Clock"
    /// The high speed external clock signal (HSE) can be generated from two possible clock
    /// sources:
    ///     - HSE external crystal/ceramic resonator
    ///     - HSE user external clock
    hse,

    /// RM0377 Section 7.2.2 "HSI16 Clock"
    /// The HSI16 clock signal is generated from an internal 16 MHz RC oscillator. It can be used
    /// directly as a system clock or as PLL input.
    hsi16,

    /// RM0377 Section 7.2.3 "MSI Clock"
    /// The MSI clock signal is generated from an internal RC oscillator. Its frequency range can
    /// be adjusted by software by using the MSIRANGE[2:0] bits in the RCC_ICSCR register (see
    /// Section 7.3.2: Internal clock sources calibration register (RCC_ICSCR)). Seven frequency
    /// ranges are available: 65.536 kHz, 131.072 kHz, 262.144 kHz, 524.288 kHz, 1.048 MHz,
    /// 2.097 MHz (default value) and 4.194 MHz.
    msi,

    /// RM0377 Section 7.2.4 "PLL Clock"
    /// The internal PLL can be clocked by the HSI16 RC or HSE clocks.
    /// The PLL input clock frequency must range between 2 and 24 MHz.
    pll,

    /// RM0377 Section 7.2.5 "LSI Clock"
    /// The LSI RC acts as an low-power clock source that can be kept running in Stop and
    /// Standby mode for the independent watchdog (IWDG). The clock frequency is around
    /// 37 kHz.
    lsi,

    /// RM0377 Section 7.2.6 "LSE Clock"
    /// The LSE crystal is a 32.768 kHz low speed external crystal or ceramic resonator. It has the
    /// advantage of providing a low-power but highly accurate clock source to the real-time clock
    /// peripheral (RTC) for clock/calendar or other timing functions.
    lse,
};

/// PLL (Phase Locked-Loop) Config
pub const PLL = struct {
    source: Source,
    mul: Mul,
    div: Div,

    /// What clock the PLL uses as it's source
    pub const Source = enum(u1) { hsi16, hse };

    /// What to multiply clock source by
    pub const Mul = enum(u4) {
        @"3",
        @"4",
        @"6",
        @"8",
        @"12",
        @"16",
        @"24",
        @"32",
        @"48",
    };

    /// What to divide clock source by
    pub const Div = enum(u2) {
        @"2" = 1,
        @"3",
        @"4",
    };
};

/// HSI16 Prescaling Config
pub const HSI16 = enum {
    @"1/1",
    @"1/4",
};

/// MSI Range Config
pub const MSI = enum(u3) {
    @"65.536kHz",
    @"131.072 kHz",
    @"262.144 kHz",
    @"524.288 kHz",
    @"1.048 MHz",
    @"2.097 MHz",
    @"4.194 MHz",
};

/// HSE clock config
pub const HSE = void;

/// AHB clock config
pub const AHB = enum(u4) {
    @"1/1",
    @"1/2" = 0b1000,
    @"1/4",
    @"1/8",
    @"1/16",
    @"1/64",
    @"1/128",
    @"1/256",
    @"1/512",
};

/// APB Prescaling config
pub const APB = enum(u3) {
    @"1/1",
    @"1/2" = 0b100,
    @"1/4",
    @"1/8",
    @"1/16",
};

/// What peripherial clocks to enable
pub const EnabledPeripherals = struct {
    dma: bool = false,
    nvm: bool = true,
    adc: bool = false,
    spi1: bool = false,
    lptim1: bool = false,
    pwr: bool = false,
    i2c1: bool = false,
    gpioa: bool = false,
    gpiob: bool = false,
    gpioc: bool = false,
};

/// Reset and Clock Configuration
pub const Config = struct {
    /// What oscillator does SYSCLK use
    sysclk: ClockSource = .msi,

    /// What peripherial clocks to enable in run mode
    run: EnabledPeripherals = .{},

    /// What peripherial clocks to enable in sleep mode
    sleep: EnabledPeripherals = .{},

    /// AHB clock config
    ahb: AHB = .@"1/1",

    /// APB1 clock config
    apb1: APB = .@"1/1",

    /// APB2 clock confi
    apb2: APB = .@"1/1",

    /// PLL clock config, null corresponds to the PLL being turned off
    pll: ?PLL = null,

    /// MSI clock config, null corresponds to the MSI being turned off
    msi: ?MSI = .@"2.097 MHz",

    /// HSI16 clock config, null corresponds to the HSI16 being turned off
    hsi16: ?HSI16 = null,

    /// HSE clock config, null corresponds to the HSE being turned off
    hse: ?HSE = null,

    /// Apply the config
    /// This is applied in respect to a previous config, so that transitions to new clock sources
    /// can occur correctly
    pub fn apply(comptime this: @This(), comptime prev: @This()) @This() {
        // Turn on any clocks now and update their values
        // HSE clock
        if (comptime !std.meta.eql(this.hse, prev.hse) and this.hse != null) {
            regs.rcc.cr.hseon = true;
        }

        // HSI16 clock
        if (comptime !std.meta.eql(this.hsi16, prev.hsi16)) {
            if (comptime this.hsi16) |hsi16| {
                regs.rcc.cr.hsi16diven = hsi16 == .@"1/4";
                regs.rcc.cr.hsi16on = true;
            }
        }

        // MSI clock
        if (comptime !std.meta.eql(this.msi, prev.msi)) {
            if (comptime this.msi) |msi| {
                regs.rcc.icscr.msirange = @intFromEnum(msi);
                regs.rcc.cr.msion = true;
            }
        }

        // PLL clock
        if (comptime !std.meta.eql(this.pll, prev.pll)) {
            if (comptime this.pll) |pll| {
                // Make sure PLL is off before making changes
                if (comptime prev.pll != null) {
                    regs.rcc.cr.pllon = false;
                    while (regs.rcc.cr.pllrdy) {}
                }

                // Update PLL and apply changes
                regs.rcc.cfgr.pllsrc = @intFromEnum(pll.source);
                regs.rcc.cfgr.pllmul = @intFromEnum(pll.mul);
                regs.rcc.cfgr.plldiv = @intFromEnum(pll.div);
                regs.rcc.regs.rcc.cr.pllon = true;
            }
        }

        // Change SYSCLK source
        if (comptime !std.meta.eql(this.sysclk, prev.sysclk)) {
            // Validate the config
            if (comptime switch (this.sysclk) {
                .hse => this.hse == null,
                .hsi16 => this.hsi16 == null,
                .msi => this.msi == null,
                .pll => this.pll == null,
                else => @compileError("Invalid SYSCLK clock source."),
            }) {
                @compileError("SYSCLK source not enabled in config.");
            }

            // Make sure that the new source is ready
            while (switch (this.sysclk) {
                .hse => !regs.rcc.cr.hserdy,
                .hsi16 => !regs.rcc.cr.hsi16rdyf,
                .msi => !regs.rcc.cr.msirdy,
                .pll => !regs.rcc.cr.pllrdy,
                else => unreachable,
            }) {}

            // Switch to the new source
            regs.rcc.cfgr.sw = comptime switch (this.sysclk) {
                .hse => 0b10,
                .hsi16 => 0b01,
                .msi => 0b00,
                .pll => 0b11,
                else => unreachable,
            };
        }

        // Turn off any clocks now
        // HSE clock
        if (comptime !std.meta.eql(this.hse, prev.hse) and this.hse == null) {
            regs.rcc.cr.hseon = false;
        }
        if (comptime !std.meta.eql(this.hsi16, prev.hsi16) and this.hsi16 == null) {
            regs.rcc.cr.hsi16on = false;
        }
        if (comptime !std.meta.eql(this.msi, prev.msi) and this.msi == null) {
            regs.rcc.cr.msi = false;
        }
        if (comptime !std.meta.eql(this.pll, prev.pll) and this.pll == null) {
            regs.rcc.cr.pll = false;
        }

        // AHB clocks
        if (comptime !std.meta.eql(this.ahb, prev.ahb)) {
            regs.rcc.cfgr.hpre = @intFromEnum(this.ahb);
            while (regs.rcc.cfgr.hpre != @intFromEnum(this.ahb)) {}
        }

        // APB1 clock
        if (comptime !std.meta.eql(this.apb1, prev.apb1)) {
            regs.rcc.cfgr.ppre1 = @intFromEnum(this.apb1);
        }

        // APB2 clock
        if (comptime !std.meta.eql(this.apb2, prev.apb2)) {
            regs.rcc.cfgr.ppre2 = @intFromEnum(this.apb2);
        }

        // Peripherals enabled in run mode
        if (comptime !std.meta.eql(this.run, prev.run)) {
            regs.rcc.ahbenr.* = comptime regs.rcc.AHBENR{
                .crcen = false,
                .crypen = false,
                .dmaen = this.run.dma,
                .mifen = this.run.nvm,
            };
            regs.rcc.apb1enr.* = comptime regs.rcc.APB1ENR{
                .i2c1en = this.run.i2c1,
                .i2c2en = false,
                .i2c3en = false,
                .lptim1en = this.run.lptim1,
                .lpuart1en = false,
                .pwren = this.run.pwr,
                .spi2en = false,
                .tim2en = false,
                .tim3en = false,
                .tim6en = false,
                .tim7en = false,
                .usart2en = false,
                .usart4en = false,
                .usart5en = false,
                .wwdgen = false,
            };
            regs.rcc.apb2enr.* = comptime regs.rcc.APB2ENR{
                .adcen = this.run.adc,
                .dbgen = false,
                .fwen = false,
                .spi1en = this.run.spi1,
                .syscfgen = false,
                .tim21en = false,
                .tim22en = false,
                .usart1en = false,
            };
        }

        // Peripherals enabled in sleep mode
        if (comptime !std.meta.eql(this.sleep, prev.sleep)) {
            regs.rcc.ahbsmenr.* = comptime regs.rcc.AHBSMENR{
                .crcsmen = false,
                .crypsmen = false,
                .dmasmen = this.sleep.dma,
                .mifsmen = this.sleep.nvm,
                .sramsmen = true,
            };
            regs.rcc.apb1smenr.* = comptime regs.rcc.APB1SMENR{
                .i2c1smen = this.sleep.i2c1,
                .i2c2smen = false,
                .i2c3smen = false,
                .lptim1smen = this.sleep.lptim1,
                .lpuart1smen = false,
                .pwrsmen = this.sleep.pwr,
                .spi2smen = false,
                .tim2smen = false,
                .tim3smen = false,
                .tim6smen = false,
                .tim7smen = false,
                .usart2smen = false,
                .usart4smen = false,
                .usart5smen = false,
                .wwdgsmen = false,
            };
            regs.rcc.apb2smenr.* = comptime regs.rcc.APB2SMENR{
                .adcsmen = this.sleep.adc,
                .dbgsmen = false,
                .fwsmen = false,
                .spi1smen = this.sleep.spi1,
                .syscfgsmen = false,
                .tim21smen = false,
                .tim22smen = false,
                .usart1smen = false,
            };
        }

        return this;
    }
};
