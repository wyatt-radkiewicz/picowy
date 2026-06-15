//! PWR Subsystem
const regs = @import("regs.zig");

/// RM0377 Section 6.1.4 "Dynamic voltage scaling management"
pub const VCore = enum(u2) {
    /// Range 1 is the “high performance” range.
    @"1.8V" = 1,

    /// At 1.5 V, the Flash memory is still functional but with medium read access time. This is
    /// the “medium performance” range. Program and erase operations on the Flash memory
    /// are still possible.
    @"1.5V" = 2,

    /// At 1.2 V, the Flash memory is still functional but with slow read access time. This is the
    /// “low performance” range. Program and erase operations on the Flash memory are not
    /// possible under these conditions.
    @"1.2V" = 3,

    /// Set VCore to this range
    pub fn apply(this: @This()) void {
        while (regs.pwr.csr.vosf) {}
        regs.pwr.cr.vos = @intFromEnum(this);
        while (regs.pwr.csr.vosf) {}
    }
};
