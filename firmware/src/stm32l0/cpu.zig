//! CPU Configuration Registers
const regs = @import("regs.zig");

/// CPU Configuration
pub const Config = struct {
    sleep_on_exit: bool = false,
    sleep_deep: bool = false,
    sev_on_pend: bool = false,

    /// Apply the config
    pub fn apply(comptime this: @This()) void {
        regs.scb.scr.* = comptime regs.scb.SCR{
            .sleeponexit = this.sleep_on_exit,
            .sevonpend = this.sev_on_pend,
            .sleepdeep = this.sleep_deep,
        };
    }
};
