//! Startup code
const main = @import("main");
const options = @import("options");

// Export the vector table
comptime {
    @export(&@field(main, options.vector_table_name), .{
        .name = "vector_table",
        .section = ".vectors",
    });
}

/// Entry point
pub export fn _start() noreturn {
    // Load .data
    const sram_start = @extern([*]allowzero u8, .{ .name = "sram_start" });
    const data_start = @extern([*]allowzero u8, .{ .name = "data_start" });
    const data_size: usize = @intFromPtr(@extern(
        *allowzero u8,
        .{ .name = "data_size" },
    ));
    @memcpy(sram_start[0..data_size], data_start[0..data_size]);

    // Load .bss
    const bss_start = @extern([*]allowzero u8, .{ .name = "bss_start" });
    const bss_size: usize = @intFromPtr(@extern(
        *allowzero anyopaque,
        .{ .name = "bss_size" },
    ));
    @memset(bss_start[0..bss_size], 0);

    // Call main function
    @field(main, options.main_name)();
}
