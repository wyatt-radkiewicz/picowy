//! Exception registers and layer
const std = @import("std");

pub const Vector = enum(u6) {
    reset = 1,
    nmi,
    hardfault,
    svcall = 11,
    pendsv = 14,
    systick,
    _,

    /// Gets the vector number for an IRQ number
    pub fn fromIRQ(n: u5) @This() {
        return @enumFromInt(16 + n);
    }

    /// Generates the table and puts it in the ".vectors" section
    /// Only call this once!
    pub fn generateTable(
        irq_count: comptime_int,
        comptime queryHandler: fn (Vector) ?*allowzero const anyopaque,
    ) void {
        const thunk: *allowzero const anyopaque = @ptrCast(&struct {
            pub fn inner() callconv(.{ .arm_interrupt = .{} }) void {}
        }.inner);
        var table = [1]*allowzero const anyopaque{@ptrFromInt(0)} ** (16 + irq_count);
        table[0] = @extern(*allowzero const anyopaque, .{ .name = "stack_start" });
        for (std.meta.tags(@This())) |vector| {
            table[@intFromEnum(vector)] = queryHandler(vector) orelse thunk;
        }
        for (0..irq_count) |irq| {
            const vector = fromIRQ(irq);
            table[@intFromEnum(vector)] = queryHandler(vector) orelse thunk;
        }
        const final_table = table;
        @export(final_table[@intFromEnum(Vector.reset)], .{
            .name = "_start",
            .linkage = .strong,
        });
        @export(&final_table, .{
            .name = "vectors",
            .linkage = .strong,
            .section = ".vectors",
        });
    }
};
