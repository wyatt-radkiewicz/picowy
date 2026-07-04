//! STM32 Entry Point
const main = @import("main");
const zst = @import("zst");

comptime {
    // Export main's vector table
    @export(&main.vector_table, .{
        .name = "vector_table",
        .linkage = .strong,
        .section = ".vector_table",
    });
}

/// Entry point, copies .data segment, and zero's out the .bss segment
pub export fn _start() void {
    // Copy the .data segment
    const data_src_start = @extern([*]u8, .{ .name = "_data_src_start" });
    const data_dst_start = @extern([*]u8, .{ .name = "_data_dst_start" });
    const data_size = @intFromPtr(@extern([*]u8, .{ .name = "_data_size" }));
    @memcpy(data_dst_start[0..data_size], data_src_start[0..data_size]);

    // Zero out the .bss segment
    const bss_start = @extern([*]u8, .{ .name = "_bss_start" });
    const bss_size = @intFromPtr(@extern([*]u8, .{ .name = "_bss_size" }));
    @memset(bss_start[0..bss_size], 0);

    // Call main
    main.main();
}
