const std = @import("std");

const Build = std.Build;
const Target = std.Target;
const Module = Build.Module;
const Compile = Build.Step.Compile;

/// Options to pass in when building an executable with the HAL
pub const AddExecutableOptions = struct {
    /// Name of the executable
    name: []const u8,

    /// The root module
    root_module: *Module,

    /// What the main function is called
    main_func: []const u8 = "main",

    /// What the vector table is called
    vector_table: []const u8 = "vector_table",
};

/// Gets the MCU's target
pub fn target(b: *Build) Build.ResolvedTarget {
    return b.resolveTargetQuery(.{
        // ARM Cortex-M0+
        .cpu_arch = .arm,
        .cpu_model = .{ .explicit = &Target.arm.cpu.cortex_m0plus },

        // Bare metal
        .os_tag = .freestanding,

        // Embedded ABI
        .abi = .eabi,
    });
}

/// Changes the module options to be more optimized for the target
pub fn optimizeModuleOpts(options: Module.CreateOptions) Module.CreateOptions {
    return .{
        // Inheritted options
        .root_source_file = options.root_source_file,
        .imports = options.imports,
        .target = options.target,
        .optimize = options.optimize,
        .strip = options.strip,
        .dwarf_format = options.dwarf_format,
        .fuzz = options.fuzz,
        .valgrind = options.valgrind,

        // Overridden options
        .link_libc = false,
        .link_libcpp = false,
        .single_threaded = true,
        .unwind_tables = .none,
        .code_model = .small,
        .stack_protector = false,
        .stack_check = false,
        .sanitize_c = .off,
        .sanitize_thread = false,
        .pic = null,
        .red_zone = null,
        .omit_frame_pointer = true,
        .error_tracing = false,
        .no_builtin = true,
    };
}

/// Create an executable with a vector table and "main" as the entry point
pub fn addExecutable(hal: *Build.Dependency, options: AddExecutableOptions) *Compile {
    return addExecutableWithHAL(hal.builder, hal.module("hal"), options);
}

/// Internal function to build an executable with the HAL module
fn addExecutableWithHAL(b: *Build, hal: *Module, options: AddExecutableOptions) *Compile {
    // Make the provided options available to the start module
    const start_opts = b.addOptions();
    start_opts.addOption([]const u8, "main_name", options.main_func);
    start_opts.addOption([]const u8, "vector_table_name", options.vector_table);

    // Create a "start" module that calls the root module
    const start = b.createModule(optimizeModuleOpts(.{
        .root_source_file = b.path("src/start.zig"),

        .optimize = .ReleaseSmall,
        .target = target(b),
    }));
    start.addImport("main", options.root_module);
    start.addImport("hal", hal);
    start.addImport("options", start_opts.createModule());

    // Create the executable
    const exe = b.addExecutable(.{
        .name = options.name,
        .root_module = start,
    });
    exe.setLinkerScript(b.path("src/linker.ld"));
    return exe;
}

/// Internal build function for the library
pub fn build(b: *Build) void {
    // Get the standard options
    const optimize = b.standardOptimizeOption(.{});

    // Gather each main build step
    const install_step = b.getInstallStep();

    // Build the main module
    const hal = b.addModule("hal", optimizeModuleOpts(.{
        .root_source_file = b.path("src/root.zig"),

        .optimize = optimize,
        .target = target(b),
    }));

    // List of examples to build
    const examples = [_][]const u8{
        "base",
    };

    // Build each example
    for (examples) |example_name| {
        // Create the main module
        const example_mod = b.createModule(optimizeModuleOpts(.{
            .root_source_file = b.path(b.pathJoin(&.{ "examples", example_name, "main.zig" })),

            .optimize = optimize,
            .target = target(b),
        }));
        example_mod.addImport("hal", hal);

        // Build the executable and install it
        const example_exe = addExecutableWithHAL(b, hal, .{
            .name = example_name,
            .root_module = example_mod,
        });
        const example_install = b.addInstallArtifact(example_exe, .{});
        install_step.dependOn(&example_install.step);
    }
}
