//! Interrupts Abstraction Layer
const std = @import("std");

pub const Interrupt = enum(i6) {
    // Exceptions
    nmi = -14,
    hardfault,
    svcall = -5,
    pendsv = -2,
    systick,

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
    i2c2,
    i2c1,
    spi1,
    spi2,
    usart1,
    usart2,
    lpuart1_aes,

    /// Config for an IRQ
    pub const Config = union {
        /// PM0223 Section 4.2.2 and Section 4.2.3
        disabled: void,

        /// Provide a priority for the interrupt
        enabled: Priority,
    };

    /// Exception Handler
    pub const Handler = *const fn () callconv(.{ .arm_interrupt = .{} }) void;

    /// Priority Number
    /// PM0223 Section 4.2.6
    pub const Priority = u2;

    /// Configures the interrupt
    pub fn configure(comptime this: @This(), comptime config: Config) void {
        const irq_num = std.math.cast(u5, @intFromEnum(this)) orelse
            @compileError("Configuring exceptions is not supported (currently).");
        switch (config) {
            .disabled => regs.icer |= @as(u32, 1) << irq_num,
            .enabled => |prio| {
                regs.iser |= @as(u32, 1) << irq_num;
                regs.pri[irq_num] = @as(u8, prio) << 6;
            },
        }
    }
};

/// Builds a vector table
pub fn vectorTable(exception_handlers: std.EnumMap(Interrupt, Interrupt.Handler)) ret_type: {
    const last_bit_set = exception_handlers.bits.findLastSet() orelse -1;
    const len = last_bit_set + 17;
    break :ret_type [len]*allowzero const anyopaque;
} {
    // Unused vector thunk
    const Entry = *allowzero const anyopaque;
    const thunk: Entry = @ptrCast(&struct {
        pub fn inner() callconv(.{ .arm_interrupt = .{} }) void {}
    }.inner);

    // Initialize the table
    var table_buffer = [2]Entry{
        @extern(Entry, .{ .name = "stack_start" }),
        @extern(Entry, .{ .name = "_start" }),
    } ++ [1]Entry{thunk} ** 62;
    var table_len = 16;

    // Add each entry
    var map = exception_handlers;
    var iter = map.iterator();
    while (iter.next()) |entry| {
        const number: u6 = @intCast(@as(i8, @intFromEnum(entry.key)) + 16);
        table_len = @max(table_len, number + 1);
        table_buffer[number] = @ptrCast(entry.value.*);
    }

    // Return the final table
    const final_table = table_buffer[0..table_len].*;
    return final_table;
}

/// PM0223 Section 4.2 "Nested Vectored Interrupt Controller"
const regs = struct {
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
