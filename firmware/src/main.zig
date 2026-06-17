const std = @import("std");
const stm32l0 = @import("stm32l0");

// Build the vector table
comptime {
    stm32l0.nvic.exportVectorTable(.init(.{}));
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
    const rcc_config = comptime stm32l0.rcc.Config{
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
    };
    rcc_config.apply(.{});

    // Configure flash
    stm32l0.flash.Config.apply(.{
        .sleep_power_down = true,
        .disable_cache = false,
        .pre_read = true,
        .prefetch_enable = true,
        .wait_states = 0,
    });

    // Configure GPIO pins
    const pins_cfg = comptime stm32l0.gpio.Config{
        .a = .{
            .@"4" = .{ .output = .{
                .type = .open_drain,
                .pull = .up,
                .speed = .low,
            } },
            .@"5" = .{ .alt = .{
                .type = .push_pull,
                .pull = .up,
                .speed = .low,
                .func = .spi1_sck,
            } },
            .@"6" = .{ .alt = .{
                .type = .push_pull,
                .pull = .up,
                .speed = .low,
                .func = .spi1_miso,
            } },
            .@"7" = .{ .alt = .{
                .type = .push_pull,
                .pull = .up,
                .speed = .low,
                .func = .spi1_mosi,
            } },
            .@"8" = .{ .output = .{
                .type = .open_drain,
                .pull = .up,
                .speed = .low,
            } },
        },
        .b = .{
            .@"0" = .{ .output = .{
                .type = .open_drain,
                .pull = .up,
                .speed = .low,
            } },
            .@"1" = .{ .output = .{
                .type = .open_drain,
                .pull = .up,
                .speed = .low,
            } },
            .@"3" = .{ .input = .{
                .pull = null,
            } },
            .@"4" = .{ .input = .{
                .pull = null,
            } },
            .@"6" = .{ .alt = .{
                .type = .push_pull,
                .pull = .up,
                .speed = .low,
                .func = .i2c1_scl,
            } },
            .@"7" = .{ .alt = .{
                .type = .push_pull,
                .pull = .up,
                .speed = .low,
                .func = .i2c1_sda,
            } },
        },
    };
    pins_cfg.apply(.{});

    // Set power level
    stm32l0.pwr.VCore.apply(.@"1.2V");

    // Enable interrupts and start loop
    stm32l0.cpu.enableInterrupts(true);
    while (true) {
        stm32l0.cpu.waitForInterrupt();
    }
}
