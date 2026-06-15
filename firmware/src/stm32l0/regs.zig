//! MMIO Register Mappings
const std = @import("std");

/// PM0223 Section 4.2 "Nested Vectored Interrupt Controller"
pub const nvic = struct {
    /// PM0223 Table 25 "NVIC Register Summary"
    pub const base_addr = 0xe000_e100;

    /// PM0223 Section 4.2.2 "Interrupt Set-enable Register"
    pub const ISER = u32;
    pub const iser: *volatile ISER = @ptrFromInt(base_addr + 0x0000);

    /// PM0223 Section 4.2.3 "Interrupt Clear-enable Register"
    pub const ICER = u32;
    pub const icer: *volatile ICER = @ptrFromInt(base_addr + 0x0080);

    /// PM0223 Section 4.2.6 "Interrupt Priority Registers"
    pub const Pri = u8;
    pub const pri: *volatile [32]Pri = @ptrFromInt(base_addr + 0x0300);
};

/// PM0223 Section 4.3 "System Control Block"
pub const scb = struct {
    /// PM0223 Table 29 "Summary of the SCB Registers"
    pub const base_addr = 0xe000_ed00;

    /// PM0223 Section 4.3.6 "System Control Register"
    pub const SCR = packed struct(u32) {
        reserved0: u1 = 0,
        sleeponexit: bool,
        sleepdeep: bool,
        reserved1: u1 = 0,
        sevonpend: bool,
        reserved2: u27 = 0,
    };
    pub const scr: *volatile SCR = @ptrFromInt(base_addr + 0x0010);
};

/// RM0377 Section 3 "Flash program memory and data EEPROM (FLASH)"
pub const flash = struct {
    /// RM0377 Table 3 "STM32L0x1 peripheral register boundary addresses"
    pub const base_addr = 0x4002_2000;

    /// RM0377 Section 3.7.1 "Access control register (FLASH_ACR)"
    pub const ACR = packed struct(u32) {
        latency: u1,
        prften: bool,
        reserved0: u1 = 0,
        sleep_pd: bool,
        run_pd: bool,
        disab_buf: bool,
        pre_read: bool,
        reserved1: u25 = 0,
    };
    pub const acr: *volatile ACR = @ptrFromInt(base_addr + 0x00);
};

/// RM0377 Section 6 "Power control (PWR)"
pub const pwr = struct {
    /// RM0377 Table 3 "STM32L0x1 peripheral register boundary addresses"
    pub const base_addr = 0x4000_7000;

    /// RM0377 Section 6.4.1 "PWR power control register (PWR_CR)"
    pub const CR = packed struct(u32) {
        lpsdsr: bool,
        pdds: bool,
        cwuf: bool,
        csbf: bool,
        pvde: bool,
        pls: u3,
        dbp: bool,
        ulp: bool,
        fwu: bool,
        vos: u2,
        ds_ee_koff: bool,
        lprun: bool,
        reserved0: u1 = 0,
        lpds: bool,
        reserved1: u15 = 0,
    };
    pub const cr: *volatile CR = @ptrFromInt(base_addr + 0x00);

    /// RM0377 Section 6.4.2 "PWR power control/status register (PWR_CSR)"
    pub const CSR = packed struct(u32) {
        wuf: bool,
        sbf: bool,
        pvdo: bool,
        vrefintrdyf: bool,
        vosf: bool,
        reglpf: bool,
        reserved0: u2 = 0,
        ewup1: bool,
        ewup2: bool,
        ewup3: bool,
        reserved1: u21 = 0,
    };
    pub const csr: *volatile CSR = @ptrFromInt(base_addr + 0x04);
};

/// RM0377 Section 7.3 "RCC Registers"
pub const rcc = struct {
    /// RM0377 Table 3 "STM32L0x1 peripheral register boundary addresses"
    pub const base_addr = 0x4002_1000;

    /// RM0377 Section 7.3.1 "Clock control register (RCC_CR)"
    pub const CR = packed struct(u32) {
        hsi16on: bool,
        hsi16keron: bool,
        hsi16rdyf: bool,
        hsi16diven: bool,
        hsi16divf: bool,
        hsi16outen: bool,
        reserved0: u2 = 0,
        msion: bool,
        msirdy: bool,
        reserved1: u6 = 0,
        hseon: bool,
        hserdy: bool,
        hsebyp: bool,
        csshseon: bool,
        rtcpre: u2,
        reserved2: u2 = 0,
        pllon: bool,
        pllrdy: bool,
        reserved3: u6 = 0,
    };
    pub const cr: *volatile CR = @ptrFromInt(base_addr + 0x00);

    /// RM0377 Section 7.3.2 "Internal clock sources calibration register (RCC_ICSCR)"
    pub const ICSCR = packed struct(u32) {
        hsi16cal: u8,
        hsi16trim: u5,
        msirange: u3,
        msical: u8,
        msitrim: u8,
    };
    pub const icscr: *volatile ICSCR = @ptrFromInt(base_addr + 0x04);

    /// RM0377 Section 7.3.3 "Clock configuration register (RCC_CFGR)"
    pub const CFGR = packed struct(u32) {
        sw: u2,
        sws: u2,
        hpre: u4,
        ppre1: u3,
        ppre2: u3,
        reserved0: u1 = 0,
        stopwuck: u1,
        pllsrc: u1,
        reserved1: u1 = 0,
        pllmul: u4,
        plldiv: u2,
        mcosel: u4,
        mcopre: u3,
        reserved2: u1 = 0,
    };
    pub const cfgr: *volatile CFGR = @ptrFromInt(base_addr + 0x0c);

    /// RM0377 Section 7.3.11 "GPIO clock enable register (RCC_IOPENR)"
    pub const IOPENR = packed struct(u32) {
        iopaen: bool,
        iopben: bool,
        iopcen: bool,
        iopden: bool,
        iopeen: bool,
        reserved0: u2 = 0,
        iophen: bool,
        reserved1: u24 = 0,
    };
    pub const iopenr: *volatile IOPENR = @ptrFromInt(base_addr + 0x2c);

    /// RM0377 Section 7.3.12 "AHB peripheral clock enable register (RCC_AHBENR)"
    pub const AHBENR = packed struct(u32) {
        dmaen: bool,
        reserved0: u7 = 0,
        mifen: bool,
        reserved1: u3 = 0,
        crcen: bool,
        reserved2: u11 = 0,
        crypen: bool,
        reserved3: u7 = 0,
    };
    pub const ahbenr: *volatile AHBENR = @ptrFromInt(base_addr + 0x30);

    /// RM0377 Section 7.3.13 "APB2 peripheral clock enable register (RCC_APB2ENR)"
    pub const APB2ENR = packed struct(u32) {
        syscfgen: bool,
        reserved0: u1 = 0,
        tim21en: bool,
        reserved1: u2 = 0,
        tim22en: bool,
        reserved2: u1 = 0,
        fwen: bool,
        reserved3: u1 = 0,
        adcen: bool,
        reserved4: u2 = 0,
        spi1en: bool,
        reserved5: u1 = 0,
        usart1en: bool,
        reserved6: u7 = 0,
        dbgen: bool,
        reserved7: u9 = 0,
    };
    pub const apb2enr: *volatile APB2ENR = @ptrFromInt(base_addr + 0x34);

    /// RM0377 Section 7.3.14 "APB1 peripheral clock enable register (RCC_APB1ENR)"
    pub const APB1ENR = packed struct(u32) {
        tim2en: bool,
        tim3en: bool,
        reserved0: u2 = 0,
        tim6en: bool,
        tim7en: bool,
        reserved1: u5 = 0,
        wwdgen: bool,
        reserved2: u2 = 0,
        spi2en: bool,
        reserved3: u2 = 0,
        usart2en: bool,
        lpuart1en: bool,
        usart4en: bool,
        usart5en: bool,
        i2c1en: bool,
        i2c2en: bool,
        reserved4: u5 = 0,
        pwren: bool,
        reserved5: u1 = 0,
        i2c3en: bool,
        lptim1en: bool,
    };
    pub const apb1enr: *volatile APB1ENR = @ptrFromInt(base_addr + 0x38);

    /// RM0377 Section 7.3.15 "GPIO clock enable in Sleep mode register (RCC_IOPSMENR)"
    pub const IOPSMENR = packed struct(u32) {
        iopasmen: bool,
        iopbsmen: bool,
        iopcsmen: bool,
        iopdsmen: bool,
        iopesmen: bool,
        reserved0: u2 = 0,
        iophsmen: bool,
        reserved1: u24 = 0,
    };
    pub const iopsmenr: *volatile IOPENR = @ptrFromInt(base_addr + 0x3c);

    /// RM0377 Section 7.3.16 "AHB peripheral clock enable in Sleep mode register (RCC_AHBSMENR)"
    pub const AHBSMENR = packed struct(u32) {
        dmasmen: bool,
        reserved0: u7 = 0,
        mifsmen: bool,
        sramsmen: bool,
        reserved1: u2 = 0,
        crcsmen: bool,
        reserved2: u11 = 0,
        crypsmen: bool,
        reserved3: u7 = 0,
    };
    pub const ahbsmenr: *volatile AHBSMENR = @ptrFromInt(base_addr + 0x40);

    /// RM0377 Section 7.3.17 "APB2 peripheral clock enable in Sleep mode register (RCC_APB2SMENR)"
    pub const APB2SMENR = packed struct(u32) {
        syscfgsmen: bool,
        reserved0: u1 = 0,
        tim21smen: bool,
        reserved1: u2 = 0,
        tim22smen: bool,
        reserved2: u1 = 0,
        fwsmen: bool,
        reserved3: u1 = 0,
        adcsmen: bool,
        reserved4: u2 = 0,
        spi1smen: bool,
        reserved5: u1 = 0,
        usart1smen: bool,
        reserved6: u7 = 0,
        dbgsmen: bool,
        reserved7: u9 = 0,
    };
    pub const apb2smenr: *volatile APB2SMENR = @ptrFromInt(base_addr + 0x44);

    /// RM0377 Section 7.3.18 "APB1 peripheral clock enable in Sleep mode register (RCC_APB1SMENR)"
    pub const APB1SMENR = packed struct(u32) {
        tim2smen: bool,
        tim3smen: bool,
        reserved0: u2 = 0,
        tim6smen: bool,
        tim7smen: bool,
        reserved1: u5 = 0,
        wwdgsmen: bool,
        reserved2: u2 = 0,
        spi2smen: bool,
        reserved3: u2 = 0,
        usart2smen: bool,
        lpuart1smen: bool,
        usart4smen: bool,
        usart5smen: bool,
        i2c1smen: bool,
        i2c2smen: bool,
        reserved4: u5 = 0,
        pwrsmen: bool,
        reserved5: u1 = 0,
        i2c3smen: bool,
        lptim1smen: bool,
    };
    pub const apb1smenr: *volatile APB1SMENR = @ptrFromInt(base_addr + 0x48);

    /// RM0377 Section 7.3.19 "Clock configuration register (RCC_CCIPR)"
    pub const CCIPR = packed struct(u32) {
        usart1sel: u2,
        usart2sel: u2,
        reserved0: u6 = 0,
        lpuart1sel: u2,
        i2c1sel: u2,
        reserved1: u2 = 0,
        i2c3sel: u2,
        lptim1sel: u2,
        reserved2: u12 = 0,
    };
    pub const ccipr: *volatile CCIPR = @ptrFromInt(base_addr + 0x4c);

    /// RM0377 Section 7.3.20 "Control/status register (RCC_CSR)"
    pub const CSR = packed struct(u32) {
        lsion: bool,
        lsirdy: bool,
        reserved0: u5 = 0,
        lseon: bool,
        lserdy: bool,
        lsebyp: bool,
        lsedrv: u2,
        csslseon: bool,
        csslsed: bool,
        reserved1: u1 = 0,
        rtcsel: u2,
        rtcen: bool,
        rtcrst: bool,
        reserved2: u3 = 0,
        rmvf: bool,
        fwrstf: bool,
        oblrstf: bool,
        pinrstf: bool,
        porrstf: bool,
        sftrstf: bool,
        iwdgrstf: bool,
        wwdgrstf: bool,
        lpwrrstf: bool,
    };
    pub const csr: *volatile CSR = @ptrFromInt(base_addr + 0x50);
};
