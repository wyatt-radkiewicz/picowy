//! Exception registers and layer
const std = @import("std");
const regs = @import("regs.zig");

/// Interrupt Service Request Numbers
pub const IRQ = enum(i6) {
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
    pub const Config = struct {
        enable: bool,
        priority: u2,
    };
};

/// Vector table abstraction
pub const VectorTable = struct {
    handlers: std.EnumMap(IRQ, Handler),

    /// Exception Handler
    pub const Handler = *const fn () callconv(.{ .arm_interrupt = .{} }) void;

    /// Builds and exports the vector table
    pub fn build(comptime this: @This()) void {
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
        var map = this.handlers;
        var iter = map.iterator();
        while (iter.next()) |entry| {
            const number: u6 = @intCast(@as(i8, @intFromEnum(entry.key)) + 16);
            table_len = @max(table_len, number + 1);
            table_buffer[number] = @ptrCast(entry.value.*);
        }

        // Export the table
        const final_table = table_buffer[0..table_len].*;
        @export(&final_table, .{
            .name = "vectors",
            .linkage = .strong,
            .section = ".vectors",
        });
    }
};

/// Config for NVIC
pub const Config = struct {
    irqs: std.EnumMap(IRQ, IRQ.Config),

    /// Apply the NVIC config
    pub fn apply(comptime this: @This()) void {
        // This allows us to iterate over the map
        comptime var map = this.irqs;

        // Enable certain ISRs
        if (comptime iser: {
            var bitset: u32 = 0;
            var iter = map.iterator();
            while (iter.next()) |cfg| {
                const i = std.math.cast(u5, @intFromEnum(cfg.key)) orelse continue;
                bitset |= @as(u32, @intFromBool(cfg.value.enable)) << i;
            }
            break :iser @as(?u32, if (bitset == 0) null else bitset);
        }) |bits| {
            regs.nvic.iser.* |= bits;
        }

        // Disable other ISRs
        if (comptime icer: {
            var bitset: u32 = 0;
            var iter = map.iterator();
            while (iter.next()) |cfg| {
                const i = std.math.cast(u5, @intFromEnum(cfg.key)) orelse continue;
                bitset |= @as(u32, @intFromBool(!cfg.value.enable)) << i;
            }
            break :icer @as(?u32, if (bitset == 0) null else bitset);
        }) |bits| {
            regs.nvic.icer.* |= bits;
        }

        // Set priorities
        comptime var iter = map.iterator();
        inline while (comptime iter.next()) |cfg| {
            const i = comptime std.math.cast(u5, @intFromEnum(cfg.key)) orelse continue;
            regs.nvic.pri[i] = @as(u8, cfg.value.priority) << 6;
        }
    }
};
