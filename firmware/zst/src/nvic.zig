//! RM0377 Section 11 "Nested vectored interrupt controller (NVIC)"
const std = @import("std");

/// PM0223 Section 2.3.2 "Exception types"
pub const IRQ = enum(i6) {
    // Exceptions
    nmi = -14,
    hardfault = -13,
    svcall = -5,
    pendsv = -2,
    systick = -1,

    // Interrupts
    wwdg = 0,
    pvd,
    rtc,
    flash,
    rcc_crs,
    exti1_0,
    exti3_2,
    exti15_4,
    dma1_channel1 = 9,
    dma1_channel3_2,
    dma1_channel7_4,
    adc_comp,
    lptim1,
    usart4_usart5,
    tim2,
    tim3,
    tim6,
    tim7,
    tim21 = 20,
    i2c3,
    tim22,
    i2c1,
    i2c2,
    spi1,
    spi2,
    usart1,
    usart2,
    lpuart1_aes,

    // Enables or disables the interrupt
    pub fn setEnable(this: @This(), enable: bool) void {
        (switch (enable) {
            true => regs.iser,
            false => regs.icer,
        }).* |= @as(u32, 1) << @intCast(@intFromEnum(this));
    }

    // Sets the priority of the interrupt
    pub fn setPriority(this: @This(), pri: u8) void {
        regs.ipr[@intCast(@intFromEnum(this))] = pri;
    }
};

/// Handler function prototype
pub const Handler = *const fn () callconv(.{ .arm_interrupt = .{} }) void;

/// Internal STM32 registers
/// PM0223 Section 4.2 "Nested vectored interrupt controller"
const regs = struct {
    pub const iser: *volatile u32 = @ptrFromInt(0xe000e100);
    pub const icer: *volatile u32 = @ptrFromInt(0xe000e180);
    pub const ipr: *volatile [32]u8 = @ptrFromInt(0xe000e400);
};
