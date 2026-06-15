const std = @import("std");
const stm32l0 = @import("stm32l0");

comptime {
    stm32l0.nvic.VectorTable.build(.{ .handlers = .init(.{}) });
}

pub fn main() noreturn {
    // Disable interrupts
    stm32l0.cpu.enableInterrupts(false);

    // Make CPU sleep on handler exit
    stm32l0.cpu.Config.apply(.{
        .sleep_on_exit = true,
        .sleep_deep = false,
        .sev_on_pend = false,
    });

    // Configure clocks
    const rcc_config = stm32l0.rcc.Config.apply(.{
        .sysclk = .msi,
        .msi = .@"2.097 MHz",
        .run = .{
            .nvm = true,
            .pwr = true,
            .lptim1 = true,
        },
        .sleep = .{
            .nvm = true,
            .pwr = true,
            .lptim1 = true,
        },
    }, .{});
    _ = rcc_config;

    // Configure flash
    stm32l0.flash.Config.apply(.{
        .sleep_power_down = true,
        .disable_cache = false,
        .pre_read = true,
        .prefetch_enable = true,
        .wait_states = 0,
    });

    // Set power level
    stm32l0.pwr.VCore.apply(.@"1.2V");

    // Enable interrupts and start loop
    stm32l0.cpu.enableInterrupts(true);
    while (true) {
        stm32l0.cpu.waitForInterrupt();
    }
}
