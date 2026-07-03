//! Generates a linker script for STM32 target from a definition
const std = @import("std");
const base_script = @embedFile("base.ld");

/// Configuration of a system
pub const Config = struct {
    stm32_model: []const u8,
    flash: Region,
    sram: Region,

    /// Represents a memory region
    pub const Region = struct {
        start: u32,
        size: []const u8,
    };

    /// Writes linker script
    pub fn format(this: @This(), writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print(base_script, .{
            .name = this.stm32_model,
            .flash_start = this.flash.start,
            .flash_size = std.fmt.parseIntSizeSuffix(this.flash.size, 10) catch
                return error.WriteFailed,
            .sram_start = this.sram.start,
            .sram_size = std.fmt.parseIntSizeSuffix(this.sram.size, 10) catch
                return error.WriteFailed,
        });
    }
};

/// Prints the usage message and exits the program
fn printUsage(prg_name: []const u8, stdout: *std.Io.File.Writer) noreturn {
    stdout.interface.print(
        \\\usage: {s} <input.zon> <output.ld>
    , .{prg_name}) catch die(null);
    stdout.flush() catch die(null);
    std.process.exit(0);
}

/// Prints out of memory and exits
fn die(reason: ?enum { oom }) noreturn {
    std.debug.panic("{s}", .{if (reason) |x| switch (x) {
        .oom => "out of memory!",
    } else "program error!"});
}

/// Takes in the first parameter an input file, and a second parameter as the output file
pub fn main(init: std.process.Init) void {
    // Init stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(init.io, &stdout_buffer);
    defer stdout_writer.flush() catch die(null);

    // Get arguments
    var args_iter = init.minimal.args.iterateAllocator(init.gpa) catch std.process.exit(1);
    defer args_iter.deinit();

    const prg_name = args_iter.next() orelse unreachable;
    const input_path = args_iter.next() orelse printUsage(prg_name, &stdout_writer);
    const output_path = args_iter.next() orelse printUsage(prg_name, &stdout_writer);

    // Load input file
    var input_buffer: [1024]u8 = undefined;
    const input_file = std.Io.Dir.cwd().openFile(
        init.io,
        input_path,
        .{ .mode = .read_only },
    ) catch std.debug.panic("Can't load the input file \"{s}\"!", .{input_path});
    defer input_file.close(init.io);
    const input_len = input_file.length(init.io) catch std.debug.panic("no file length!", .{});
    const input_source = init.gpa.allocWithOptions(u8, input_len, null, 0) catch die(.oom);
    defer init.gpa.free(input_source);
    var input_reader = input_file.reader(init.io, &input_buffer);
    input_reader.interface.readSliceAll(input_source[0..input_len]) catch die(null);

    // Load input config
    const input_config = std.zon.parse.fromSliceAlloc(Config, init.gpa, input_source, null, .{
        .free_on_error = true,
        .ignore_unknown_fields = false,
    }) catch std.debug.panic("Can't parse the input file \"{s}\"!", .{input_path});
    defer std.zon.parse.free(init.gpa, input_config);

    // Write to the output file
    var output_buffer: [1024]u8 = undefined;
    const output_file = std.Io.Dir.cwd().createFile(init.io, output_path, .{}) catch
        std.debug.panic("Can't open the output file \"{s}\"!", .{output_path});
    defer output_file.close(init.io);
    var output_writer = output_file.writer(init.io, &output_buffer);
    output_writer.interface.print("{f}\n", .{input_config}) catch
        std.debug.panic("Error writing to output file!", .{});
    output_writer.flush() catch die(null);
}
