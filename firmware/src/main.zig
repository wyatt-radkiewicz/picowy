const std = @import("std");
const stm32l0 = @import("stm32l0");

comptime {
    stm32l0.nvic.VectorTable.build(.{ .handlers = .init(.{}) });
}

pub fn main() noreturn {
    stm32l0.cpu.Config.apply(.{
        .sleep_on_exit = true,
        .sleep_deep = false,
        .sev_on_pend = false,
    });
    while (true) {}
}
