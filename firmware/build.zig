//! Firmware build script
const std = @import("std");

pub fn build(b: *std.Build) void {
    // Build targets
    const stm32_target = b.resolveTargetQuery(.{
        .cpu_arch = .arm,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m0plus },

        .os_tag = .freestanding,

        .abi = .eabi,
    });
    const sdl3_target = b.standardTargetOptions(.{});

    // Optimization mode
    const optimize = b.standardOptimizeOption(.{});

    // Main steps
    const install_step = b.getInstallStep();
    const stm32_step = b.step("stm32", "Build and flash the STM32 firmware");
    const sdl3_step = b.step("sdl3", "Build and run the SDL3 application");

    // Target modules
    const stm32_hal_mod = b.createModule(.{
        .root_source_file = b.path("hal/stm32/root.zig"),
        .target = stm32_target,
        .optimize = optimize,

        .code_model = .small,
        .no_builtin = true,
        .omit_frame_pointer = true,
        .unwind_tables = .none,
    });
    const stm32_app_mod = b.createModule(.{
        .root_source_file = b.path("app/main.zig"),
        .target = stm32_target,
        .optimize = optimize,

        .code_model = .small,
        .no_builtin = true,
        .omit_frame_pointer = true,
        .unwind_tables = .none,
    });
    stm32_app_mod.addImport("hal", stm32_hal_mod);

    const sdl3_hal_mod = b.createModule(.{
        .root_source_file = b.path("hal/sdl3/root.zig"),
        .target = sdl3_target,
        .optimize = optimize,
    });
    sdl3_hal_mod.linkSystemLibrary("sdl3", .{ .needed = true });
    const sdl3_app_mod = b.createModule(.{
        .root_source_file = b.path("app/main.zig"),
        .target = sdl3_target,
        .optimize = optimize,
    });
    sdl3_app_mod.addImport("hal", sdl3_hal_mod);

    // Target Executables
    const sdl3_exec = b.addExecutable(.{
        .name = "firmware-sdl3",
        .root_module = sdl3_app_mod,
    });

    // Run steps
    _ = stm32_step;
    const sdl3_run = b.addRunArtifact(sdl3_exec);
    sdl3_step.dependOn(&sdl3_run.step);

    // Install steps
    const sdl3_install = b.addInstallArtifact(sdl3_exec, .{});
    install_step.dependOn(&sdl3_install.step);
}
