/// GPIO Subsystem
const std = @import("std");
const regs = @import("regs.zig");

/// GPIO Config
pub const Config = struct {
    a: A = .{},
    b: B = .{},
    c: C = .{},

    /// GPIOA pins
    pub const A = struct {
        @"0": Pin(enum(u3) { usart2_rx, lptim1_in1, tim2_ch1, usart2_cts = 4, tim2_etr, lpuart1_rx, comp1_out }) = .{ .analog = {} },
        @"1": Pin(enum(u3) { eventout, lptim1_in2, tim2_ch2, i2c1_smba, usart2_rts_de, tim21_etr, lpuart1_tx }) = .{ .analog = {} },
        @"2": Pin(enum(u3) { tim21_ch1, tim2_ch3 = 2, usart2_tx = 4, lpuart1_tx = 6, comp2_out }) = .{ .analog = {} },
        @"3": Pin(enum(u3) { tim21_ch2, tim2_ch4 = 2, usart2_rx = 4, lpuart1_rx = 6 }) = .{ .analog = {} },
        @"4": Pin(enum(u3) { spitlnss, lptim1_in1, lptim1_etr, i2c1_scl, usart2_ck, tim2_etr, lpuart1ltx, comp2_out }) = .{ .input = .{
            .pull = null,
        } },
        @"5": Pin(enum(u3) { spi1_sck, lptim1_in2, tim2_etr, tim2_ch1 = 5 }) = .{ .analog = {} },
        @"6": Pin(enum(u3) { spi1_miso, lptim1_etr, lpuart1_cts = 4, eventout = 6, comp1_out }) = .{ .analog = {} },
        @"7": Pin(enum(u3) { spi1_mosi, lptim1_out, usart2_cts = 4, tim21_etr, eventout, comp2_out }) = .{ .analog = {} },
        @"8": Pin(enum(u3) { mco, lptim1_in1 = 2, eventout, usart2_ck, tim2_ch1 }) = .{ .analog = {} },
        @"9": Pin(enum(u3) { mco, i2c1_scl, lptim1_out, usart2_tx = 4, tim21_ch2, comp1_out = 7 }) = .{ .analog = {} },
        @"10": Pin(enum(u3) { tim21_ch1, i2c1_sda, rtc_refin, usart2_rx = 4, tim2_ch3, comp1_out = 7 }) = .{ .analog = {} },
        @"11": Pin(enum(u3) { spi1_miso, lptim1_out, eventout, usart2_cts = 4, tim21_ch2, comp1_out = 7 }) = .{ .analog = {} },
        @"12": Pin(enum(u3) { spi1_mosi, eventout = 2, usart2_rts_de = 3, comp2_out = 7 }) = .{ .analog = {} },
        @"13": Pin(enum(u3) { swdio, lptim1_etr, i2c1_sda = 3, spi1_sck = 5, lpuart1_rx, comp1_out }) = .{ .alt = .{
            .type = .push_pull,
            .pull = .up,
            .func = .swdio,
            .speed = .very_high,
        } },
        @"14": Pin(enum(u3) { swclk, lptim1_out, i2c1_smba = 3, usart2_tx, spi1_miso, lpuart1_tx, comp2_out }) = .{ .alt = .{
            .type = .push_pull,
            .pull = .down,
            .func = .swclk,
            .speed = .low,
        } },
        @"15": Pin(enum(u3) { spi1_nss, tim2_etr = 2, eventout, usart2_rx, tim2_ch1 }) = .{ .analog = {} },
    };

    /// GPIOB pins
    pub const B = struct {
        @"0": Pin(enum(u3) { eventout, spi1_miso, tim2_ch2, usart2_rts_de = 4, tim2_ch3 }) = .{ .analog = {} },
        @"1": Pin(enum(u3) { usart2_ck, spi1_mosi, lptim1_in1, lpuart1_rts_de, tim2_ch4 }) = .{ .analog = {} },
        @"2": Pin(enum(u3) { lptim1_out = 2 }) = .{ .analog = {} },
        @"3": Pin(enum(u3) { spi1_sck, tim2_ch2 = 2, eventout = 4 }) = .{ .analog = {} },
        @"4": Pin(enum(u3) { spi1_miso, eventout = 2 }) = .{ .analog = {} },
        @"5": Pin(enum(u3) { spi1_mosi, lptim1_in1 = 2, i2c1_smba, tim21_ch1 = 5 }) = .{ .analog = {} },
        @"6": Pin(enum(u3) { usart2_tx, i2c1_scl, lptim1_etr, tim2_ch3 = 5, lpuart1_tx }) = .{ .analog = {} },
        @"7": Pin(enum(u3) { usart2_rx, i2c1_sda, lptim1_in2, tim2_ch4 = 5, lpuart1_rx }) = .{ .analog = {} },
        @"8": Pin(enum(u3) { usart2_tx, eventout = 2, i2c1_scl = 4, spi1_nss }) = .{ .analog = {} },
        @"9": Pin(void) = .{ .analog = {} },
    };

    /// GPIOC pins
    pub const C = struct {
        @"14": Pin(void) = .{ .analog = {} },
        @"15": Pin(void) = .{ .analog = {} },
    };

    /// Apply the pin configuration
    pub fn apply(comptime this: @This(), comptime prev: @This()) void {
        inline for (comptime std.meta.tags(Port)) |port| {
            const new_regs = comptime this.config(port);
            const old_regs = comptime prev.config(port);
            inline for (comptime std.meta.fields(regs.GPIO)) |field| {
                if (comptime std.meta.eql(
                    @field(new_regs, field.name),
                    @field(old_regs, field.name),
                )) continue;
                @field(comptime switch (port) {
                    .a => regs.gpioa,
                    .b => regs.gpiob,
                    .c => regs.gpioc,
                }, field.name) = @field(new_regs, field.name);
            }
        }
    }

    /// Gets the registers for this config's port
    fn config(comptime this: @This(), comptime port: Port) regs.GPIO {
        var gpio = regs.GPIO{
            .moder = 0,
            .otyper = 0,
            .ospeedr = 0,
            .pupdr = 0,
            .idr = 0,
            .odr = 0,
            .bsrr = 0,
            .lckr = 0,
            .afr = .{ 0, 0 },
            .brr = 0,
        };

        const PortCfg = @FieldType(@This(), @tagName(port));
        const port_cfg = @field(this, @tagName(port));
        for (std.meta.fields(PortCfg)) |field| {
            const pin = @field(port_cfg, field.name);
            const i = std.fmt.parseInt(u5, field.name, 0) catch
                @compileError("Pin name is not a number.");

            gpio.moder |= @as(u32, pin.moder() orelse 0) << i * 2;
            gpio.otyper |= @as(u32, pin.otyper() orelse 0) << i * 1;
            gpio.ospeedr |= @as(u32, pin.ospeedr() orelse 0) << i * 2;
            gpio.pupdr |= @as(u32, pin.pupdr() orelse 0) << i * 2;
            gpio.afr[i / 8] |= @as(u32, pin.afr() orelse 0) << ((i % 8) * 4);
        }

        return gpio;
    }

    /// Pin config helper
    fn Pin(comptime AlternateFuncs: type) type {
        return union(Mode) {
            input: struct {
                pull: ?Pull,
            },
            output: struct {
                type: Type,
                pull: Pull,
                speed: Speed,
            },
            analog: void,
            alt: struct {
                type: Type,
                pull: Pull,
                speed: Speed,
                func: AlternateFuncs,
            },

            fn moder(this: @This()) ?u2 {
                return @intFromEnum(std.meta.activeTag(this));
            }

            fn otyper(this: @This()) ?u1 {
                return switch (this) {
                    .input, .analog => null,
                    .output => |x| @intFromEnum(x.type),
                    .alt => |x| @intFromEnum(x.type),
                };
            }

            fn ospeedr(this: @This()) ?u2 {
                return switch (this) {
                    .input, .analog => null,
                    .output => |x| @intFromEnum(x.speed),
                    .alt => |x| @intFromEnum(x.speed),
                };
            }

            fn pupdr(this: @This()) ?u2 {
                return switch (this) {
                    .analog => null,
                    .input => |x| input: {
                        if (x.pull) |pull| {
                            break :input @as(u2, @intFromEnum(pull)) + 1;
                        } else {
                            break :input 0;
                        }
                    },
                    .output => |x| @as(u2, @intFromEnum(x.pull)) + 1,
                    .alt => |x| @as(u2, @intFromEnum(x.pull)) + 1,
                };
            }

            fn afr(this: @This()) ?u4 {
                return switch (this) {
                    .alt => |alt| @intFromEnum(alt.func),
                    else => null,
                };
            }
        };
    }
};

/// Pin mode
pub const Mode = enum(u2) { input, output, analog, alt };

/// Output type
pub const Type = enum(u1) { push_pull, open_drain };

/// Output speed
pub const Speed = enum(u2) { low, medium, high, very_high };

/// Pull up/pull down
pub const Pull = enum(u1) { up, down };

/// GPIO Port
pub const Port = enum { a, b, c };
