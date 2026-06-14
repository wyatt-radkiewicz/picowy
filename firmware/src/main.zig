const std = @import("std");
const stm32l0 = @import("stm32l0");

comptime {
    stm32l0.nvic.handlers(.initFull(null));
}

pub fn main() noreturn {
    while (true) {}
}
