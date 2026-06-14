//! Raw MMIO Registers
const std = @import("std");

/// NVIC Registers
pub const nvic = struct {
    pub const iser: *volatile u32 = @ptrFromInt(base_addr + 0x0000);
    pub const icer: *volatile u32 = @ptrFromInt(base_addr + 0x0080);
    pub const pri: *volatile [32]u8 = @ptrFromInt(base_addr + 0x0300);
    pub const base_addr = 0xe000_e100;
};
