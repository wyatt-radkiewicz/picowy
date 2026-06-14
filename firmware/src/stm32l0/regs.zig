//! Raw MMIO Registers
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
