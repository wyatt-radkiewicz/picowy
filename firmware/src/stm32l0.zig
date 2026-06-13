pub const exceptions = @import("stm32l0/exceptions.zig");

/// Load .data and .bss into memory
pub fn loadDataSections() void {
    const sram_start = @extern([*]allowzero u8, .{ .name = "sram_start" });
    const data_start = @extern([*]allowzero u8, .{ .name = "data_start" });
    const data_end = @extern(*allowzero u8, .{ .name = "data_end" });
    const bss_start = @extern([*]allowzero u8, .{ .name = "bss_start" });
    const bss_end = @extern(*allowzero u8, .{ .name = "bss_end" });
    @memset(bss_start[0 .. bss_end - bss_start], 0);
    @memcpy(sram_start[0 .. data_end - data_start], data_start[0 .. data_end - data_start]);
}
