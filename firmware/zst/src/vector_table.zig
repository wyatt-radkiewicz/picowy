//! Vector Table Generator
//! See PM0223 retard
const std = @import("std");
const nvic = @import("nvic.zig");

/// Vector Table Config
pub const Config = std.EnumMap(nvic.IRQ, nvic.Handler);

/// Vector table entry
const Vector = *allowzero const anyopaque;

/// Builds the vector table
pub fn build(comptime cfg: Config) [48]Vector {
    var table = [2]Vector{
        @extern(Vector, .{ .name = "_stack_start" }),
        @extern(Vector, .{ .name = "_start" }),
    } ++ ([1]Vector{@ptrCast(&struct {
        pub fn thunk() callconv(.{ .arm_interrupt = .{} }) void {}
    }.thunk)} ** 46);

    var map = cfg;
    var iter = map.iterator();
    while (iter.next()) |entry| {
        table[@intFromEnum(entry.key)] = @ptrCast(entry.value);
    }

    const final = table;
    return final;
}
