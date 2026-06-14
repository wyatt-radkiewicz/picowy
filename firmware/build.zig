const std = @import("std");

const Build = std.Build;
const Target = std.Target;

pub fn build(b: *Build) void {
    // Targets and optimize mode
    const mcu_target = b.resolveTargetQuery(.{
        .cpu_arch = .arm,
        .os_tag = .freestanding,
        .abi = .eabi,
        .cpu_model = .{ .explicit = &Target.arm.cpu.cortex_m0plus },
    });
    const optimize = b.standardOptimizeOption(.{});

    // Build steps
    const install_step = b.getInstallStep();
    const flash_step = b.step("flash", "Flash firmware with openocd (SWD ONLY)");

    // Hardware, main, and start module
    const stm32l0_mod = SmallModule.createModule(.{
        .optimize = optimize,
        .target = mcu_target,
        .root_source_file = b.path("src/stm32l0.zig"),
    }, b);

    const picowy_mod = SmallModule.createModule(.{
        .optimize = optimize,
        .target = mcu_target,
        .root_source_file = b.path("src/main.zig"),
    }, b);
    picowy_mod.addImport("stm32l0", stm32l0_mod);

    const start_mod = SmallModule.createModule(.{
        .optimize = optimize,
        .target = mcu_target,
        .root_source_file = b.path("src/stm32l0/start.zig"),
    }, b);
    start_mod.addImport("stm32l0", stm32l0_mod);
    start_mod.addImport("picowy", picowy_mod);

    // Building firmware
    const picowy_exe = b.addExecutable(.{
        .name = "picowy",
        .root_module = start_mod,
    });
    picowy_exe.setLinkerScript(b.path("src/stm32l0/linker.ld"));
    install_step.dependOn(&b.addInstallArtifact(picowy_exe, .{}).step);

    // Flashing firmware
    if (b.findProgram(&.{"openocd"}, &.{})) |openocd_path| {
        const openocd_run = b.addSystemCommand(&.{
            openocd_path,
            "--help",
        });
        flash_step.dependOn(&openocd_run.step);
    } else |_| {
        flash_step.dependOn(&b.addFail("Could not find \"openocd\" in \"PATH\"!").step);
    }
}

const SmallModule = struct {
    target: Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    root_source_file: Build.LazyPath,

    fn createModule(this: @This(), b: *Build) *Build.Module {
        return b.createModule(.{
            .optimize = this.optimize,
            .target = this.target,
            .root_source_file = this.root_source_file,

            .code_model = .small,
            .omit_frame_pointer = true,
            .unwind_tables = .none,
            .no_builtin = true,
        });
    }
};
