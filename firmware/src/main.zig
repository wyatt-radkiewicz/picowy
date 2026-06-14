const std = @import("std");
const stm32l0 = @import("stm32l0");

comptime {
    var vt = stm32l0.nvic.VectorTable{ .handlers = .init(.{}) };
    vt.build();
}

pub fn main() noreturn {
    stm32l0.nvic.Config.apply(.{ .irqs = .init(.{
        .wwdg = .{
            .enable = true,
            .priority = 0,
        },
    }) });
    while (true) {}
}
