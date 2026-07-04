//! STM32 Target Info
const std = @import("std");
const base = @embedFile("base.ld");

/// Each target the stm32 standard library targets
pub const Model = enum {
    stm32l0x4,

    /// Returns the memory config for this model
    pub fn getMemoryConfig(this: @This()) Memory {
        return switch (this) {
            .stm32l0x4 => .{
                .model_name = "stm32l0x4",
                .flash = .{ .start = 0x0800_0000, .size = "16KB" },
                .sram = .{ .start = 0x2000_0000, .size = "2KB" },
            },
        };
    }

    /// Returns a target query for this model
    pub fn getTarget(this: @This()) std.Target.Query {
        return switch (this) {
            .stm32l0x4 => .{
                .cpu_arch = .arm,
                .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m0plus },
                .os_tag = .freestanding,
                .abi = .eabi,
            },
        };
    }
};

/// Memory configuration of the target
pub const Memory = struct {
    model_name: []const u8,
    flash: Region,
    sram: Region,

    /// Represents a memory region
    pub const Region = struct {
        start: u32,
        size: []const u8,
    };

    /// Memory gets formatted as a linker script
    pub fn format(this: @This(), writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print(
            \\/* {[name]s} linker script */
            \\
            \\/* Memory sections */
            \\MEMORY {{
            \\    flash (rx) : org = 0x{[flash_start]x:0>8}, len = 0x{[flash_size]x}
            \\    sram (!rx) : org = 0x{[sram_start]x:0>8}, len = 0x{[sram_size]x}
            \\}}
            \\
            \\/* Linker sections */
            \\SECTIONS {{
            \\    /* Sometimes a unwind table is still generated, so disable it */
            \\    /DISCARD/ : {{
            \\        *(*.exidx)
            \\    }}
            \\    
            \\    /* Default STM32 vector table */
            \\    .vector_table : {{
            \\        KEEP(*(.vector_table))
            \\    }} >flash
            \\
            \\    /* Program code */
            \\    .text : {{
            \\        *(.text)
            \\    }} >flash
            \\
            \\    /* Read only data */
            \\    .rodata : {{
            \\        /* Make sure biggest natural alignment holds */
            \\        . = ALIGN(0x4);
            \\        *(.rodata)
            \\    }} >flash
            \\
            \\    /* Initial data in flash, virtual location in sram */
            \\    _data_dst_start = 0x{[sram_start]x};
            \\    .data ADDR(.rodata) + SIZEOF(.rodata) (NOLOAD) : AT(_data_dst_start) {{
            \\        /* Make sure biggest natural alignment holds */
            \\        . = ALIGN(0x4);
            \\
            \\        /* Start of the data segment */
            \\        _data_src_start = .;
            \\        *(.data)
            \\        _data_size = . - _data_src_start;
            \\    }}
            \\    
            \\    /* Variables initialized to zero */
            \\    .bss (NOLOAD) : {{
            \\        _bss_start = .;
            \\        *(.bss)
            \\    }} >sram
            \\    _bss_size = SIZEOF(.bss);
            \\
            \\    /* Start address of stack (end of ram) */
            \\    _stack_start = 0x{[sram_start]x} + 0x{[sram_size]x};
            \\}}
            \\
        , .{
            .name = this.model_name,
            .flash_start = this.flash.start,
            .flash_size = std.fmt.parseIntSizeSuffix(this.flash.size, 10) catch
                return error.WriteFailed,
            .sram_start = this.sram.start,
            .sram_size = std.fmt.parseIntSizeSuffix(this.sram.size, 10) catch
                return error.WriteFailed,
        });
    }
};
