const std = @import("std");
const stm32l0 = @import("stm32l0");

comptime {
    stm32l0.exceptions.Vector.generateTable(0, struct {
        pub fn inner(vector: stm32l0.exceptions.Vector) ?*allowzero const anyopaque {
            return switch (vector) {
                .reset => @ptrCast(&main),
                else => null,
            };
        }
    }.inner);
}

pub fn main() noreturn {
    stm32l0.loadDataSections();
    while (true) {}
}
