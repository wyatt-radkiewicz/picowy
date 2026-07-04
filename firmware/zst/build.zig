const std = @import("std");
const target = @import("src/target.zig");

const Build = std.Build;
const Module = Build.Module;
const Compile = Build.Step.Compile;
const WriteFile = Build.Step.WriteFile;
const LazyPath = Build.LazyPath;

/// STM32 target model
pub const Model = target.Model;

/// Options to be passed in when creating a module
pub const CreateModuleOptions = struct {
    root_source_file: LazyPath,
    optimize: std.builtin.OptimizeMode,
    model: Model,
};

/// Creates a module
pub fn createModule(b: *Build, options: CreateModuleOptions) *Module {
    return b.createModule(getCreateModuleOptions(b, options));
}

/// Adds a module
pub fn addModule(b: *Build, name: []const u8, options: CreateModuleOptions) *Module {
    return b.addModule(name, getCreateModuleOptions(b, options));
}

/// Internal function to get Zig build tool create module options
fn getCreateModuleOptions(b: *Build, options: CreateModuleOptions) Module.CreateOptions {
    return .{
        // Standard options
        .root_source_file = options.root_source_file,
        .target = b.resolveTargetQuery(options.model.getTarget()),
        .optimize = options.optimize,

        // Optimize options
        .code_model = .small,
        .link_libc = false,
        .link_libcpp = false,
        .error_tracing = false,
        .no_builtin = true,
        .omit_frame_pointer = true,
        .sanitize_c = .off,
        .sanitize_thread = false,
        .single_threaded = true,
        .stack_check = false,
        .stack_protector = false,
        .unwind_tables = .none,
    };
}

/// Options to be passed in when creating an executable
pub const AddExecutableOptions = struct {
    name: []const u8,
    root_module: *Module,
    model: Model,
};

/// Adds an executable to the build
pub fn addExecutable(zst: *Build.Dependency, options: AddExecutableOptions) *Compile {
    return addExecutable2(zst.builder, zst.module("zst"), options);
}

/// Adds an executable to the build, needs the zst module and the zst write files provided
fn addExecutable2(b: *Build, zst: *Module, options: AddExecutableOptions) *Compile {
    // Create the start module to call the root module
    const start_mod = createModule(b, .{
        .root_source_file = b.path("src/start.zig"),
        .model = options.model,
        .optimize = .ReleaseSmall,
    });
    start_mod.addImport("zst", zst);
    start_mod.addImport("main", options.root_module);

    // Create the linker script
    const linker_script_dir = b.addWriteFiles();
    const linker_script = linker_script_dir.add(
        b.fmt("{s}.ld", .{@tagName(options.model)}),
        b.fmt("{f}", .{options.model.getMemoryConfig()}),
    );

    // Create the final executable
    const exe = b.addExecutable(.{
        .name = options.name,
        .root_module = start_mod,
    });
    exe.setLinkerScript(linker_script);
    return exe;
}

/// Build script
pub fn build(b: *Build) void {
    // Get build options
    const model = b.option(Model, "model", "Which STM32 model to target.") orelse
        std.debug.panic("Expected an stm32 target model!", .{});
    const optimize = b.standardOptimizeOption(.{});

    // Get top level build rules
    const examples_step = b.step(
        "examples",
        "Build and install each example to the prefix directory.",
    );

    // Build the main zst module
    const zst_mod = addModule(b, "zst", .{
        .root_source_file = b.path("src/root.zig"),
        .optimize = optimize,
        .model = model,
    });

    // Build each example
    const examples = [_][]const u8{
        "nvic",
    };
    for (examples) |example_name| {
        // Create the root module
        const example_mod = createModule(b, .{
            .root_source_file = b.path(b.pathJoin(&.{ "examples", example_name, "main.zig" })),
            .optimize = optimize,
            .model = model,
        });
        example_mod.addImport("zst", zst_mod);

        // Create the executable
        const example_exe = addExecutable2(b, zst_mod, .{
            .name = b.fmt("example-{s}", .{example_name}),
            .root_module = example_mod,
            .model = model,
        });

        // Install the executable to the prefix directory
        const example_install = b.addInstallArtifact(example_exe, .{});
        examples_step.dependOn(&example_install.step);
    }
}
