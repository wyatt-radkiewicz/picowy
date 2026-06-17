//! CPU Control
const std = @import("std");
const regs = @import("regs.zig");

/// Allow interrupts or not
pub inline fn enableInterrupts(comptime primask: bool) void {
    asm volatile (std.fmt.comptimePrint("cpsi{c} i", .{switch (primask) {
            false => 'd',
            true => 'e',
        }}));
}

/// Wait for interrupt
pub inline fn waitForInterrupt() void {
    asm volatile ("wfi");
}

/// Configure the CPU
pub fn configure(comptime config: Config) void {
    regs.scb.scr.* = comptime regs.scb.SCR{
        .sleeponexit = config.sleep_on_exit,
        .sevonpend = config.sev_on_pend,
        .sleepdeep = config.sleep_deep,
    };
}

/// CPU Configuration
pub const Config = struct {
    /// PM0223 Section 4.3.6 "System Control Register"
    /// Indicates sleep-on-exit when returning from Handler mode to Thread mode. Setting this bit
    /// to 1 enables an interrupt-driven application to avoid returning to an empty main
    /// application.
    ///     false: Do not sleep when returning to Thread mode.
    ///     true: Enter sleep, or deep sleep, on return from an ISR to Thread mode.
    sleep_on_exit: bool = false,

    /// PM0223 Section 4.3.6 "System Control Register"
    /// Controls whether the processor uses sleep or deep sleep as its low power mode.
    sleep_deep: bool = false,

    /// PM0223 Section 4.3.6 "System Control Register"
    /// Send Event on Pending bit
    ///     false: Only enabled interrupts or events can wakeup the processor, disabled interrupts
    ///     are excluded.
    ///     true: Enabled events and all interrupts, including disabled interrupts, can wakeup the
    ///     processor.
    /// When an event or interrupt becomes pending, the event signal wakes up the processor from
    /// WFE. If the processor is not waiting for an event, the event is registered and affects the
    /// next WFE.
    /// The processor also wakes up on execution of an SEV instruction or an external event.
    sev_on_pend: bool = false,
};
