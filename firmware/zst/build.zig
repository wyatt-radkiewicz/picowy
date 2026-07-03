const std = @import("std");

/// STM32 Target
pub const Target = @import("src/lib/target.zig").Target;

/// Options to be passed into a module
pub const CreateModuleOptions = struct {
    root_source_file: std.Build.LazyPath,
    optimize: std.builtin.OptimizeMode,
};

/// Works exactly like std.Build.createModule, but uses a custom module creation command that
/// optimizes the module options for the target hardware
pub fn createModule(b: *std.Build, options: CreateModuleOptions) *std.Build.Module {
    return b.createModule(getModuleOptions(b, options));
}

/// Works exactly like std.Build.addModule, but uses a custom module creation command that
/// optimizes the module options for the target hardware
pub fn addModule(b: *std.Build, name: []const u8, options: CreateModuleOptions) *std.Build.Module {
    return b.addModule(name, getModuleOptions(b, options));
}

/// Gets the module options
fn getModuleOptions(b: *std.Build, options: CreateModuleOptions) std.Build.Module.CreateOptions {
    return .{
        // Standard options
        .root_source_file = options.root_source_file,
        .target = getTarget(b),
        .optimize = options.optimize,

        // Options to optimize for space
        .no_builtin = true,
        .omit_frame_pointer = true,
        .code_model = .small,
        .error_tracing = false,
        .link_libc = false,
        .link_libcpp = false,
        .sanitize_c = .off,
        .sanitize_thread = false,
        .single_threaded = true,
        .stack_check = false,
        .stack_protector = false,
        .unwind_tables = .none,
    };
}

/// Custom options for the target hardware
pub const AddExecutableOptions = struct {
    name: []const u8,
    root_module: *std.Build.Module,
    version: ?std.SemanticVersion = null,
    vector_table_name: []const u8 = "vector_table",
    main_func_name: []const u8 = "main",
};

/// Works like add executable but with custom options, pass in the dependency of zst to itself
pub fn addExecutable(
    zst: *std.Build.Dependency,
    options: AddExecutableOptions,
) *std.Build.Step.Compile {
    return addExecutable2(zst.builder, zst.module("zst"), zst.artifact("make-ld"), options);
}

/// Works like add executable but with custom options
fn addExecutable2(
    b: *std.Build,
    zst: *std.Build.Module,
    makeld: *std.Build.Step.Compile,
    options: AddExecutableOptions,
) *std.Build.Step.Compile {
    // Executable options
    const start_options = b.addOptions();
    start_options.addOption([]const u8, "vector_table_name", options.vector_table_name);
    start_options.addOption([]const u8, "main_func_name", options.main_func_name);

    // Create the start module
    const start_mod = createModule(b, .{
        .root_source_file = b.path("src/start/main.zig"),
        .optimize = .ReleaseSmall,
    });
    start_mod.addImport("main", options.root_module);
    start_mod.addImport("zst", zst);
    start_mod.addImport("options", start_options.createModule());

    // Generate the linker script
    const gen_script = b.addRunArtifact(makeld);
    gen_script.addFileArg(b.path("src/linker/targets/stm32l0x4.zon"));
    const linker_script = gen_script.addOutputFileArg("linker.ld");

    // Create the final executable
    const exe = b.addExecutable(.{
        .name = options.name,
        .root_module = start_mod,
        .version = options.version,
    });
    exe.setLinkerScript(linker_script);
    exe.step.dependOn(&gen_script.step);
    return exe;
}

/// Gets the target for the MCU
pub fn getTarget(b: *std.Build) std.Build.ResolvedTarget {
    return b.resolveTargetQuery(.{
        .cpu_arch = .arm,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m0plus },

        .os_tag = .freestanding,

        .abi = .eabi,
    });
}

/// Build script
pub fn build(b: *std.Build) void {
    // Optimize options
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Standard build steps
    const examples_step = b.step("examples", "Builds all of the examples");

    // Create the linker script generator
    const makeld_mod = b.createModule(.{
        .root_source_file = b.path("src/linker/make_ld.zig"),
        .target = target,
        .optimize = optimize,
    });
    const makeld_exe = b.addExecutable(.{
        .name = "make-ld",
        .root_module = makeld_mod,
    });

    // Create the library module
    const zst_mod = addModule(b, "zst", .{
        .root_source_file = b.path("src/lib/root.zig"),
        .optimize = optimize,
    });

    // Build the examples
    const example_names = [_][]const u8{
        "base",
    };
    for (example_names) |example_name| {
        const example_mod = createModule(b, .{
            .root_source_file = b.path(b.pathJoin(&.{ "examples", example_name, "main.zig" })),
            .optimize = optimize,
        });
        example_mod.addImport("zst", zst_mod);

        const example_exe = addExecutable2(b, zst_mod, makeld_exe, .{
            .name = example_name,
            .root_module = example_mod,
        });
        const example_install = b.addInstallArtifact(example_exe, .{});
        examples_step.dependOn(&example_install.step);
    }
}
