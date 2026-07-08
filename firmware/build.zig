const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const hal_mod = b.createModule(.{
        .root_source_file = b.path("src/hal/sdl3/root.zig"),
        .optimize = optimize,
        .target = target,
    });
    const app_mod = b.createModule(.{
        .root_source_file = b.path("src/app/root.zig"),
        .optimize = optimize,
        .target = target,
    });
    app_mod.addImport("hal", hal_mod);
    const start_mod = b.createModule(.{
        .root_source_file = b.path("src/hal/sdl3/main.zig"),
        .optimize = optimize,
        .target = target,
    });
    start_mod.addImport("hal", hal_mod);
    start_mod.addImport("app", app_mod);
    start_mod.linkSystemLibrary("sdl3", .{
        .needed = true,
        .use_pkg_config = .yes,
        .preferred_link_mode = .static,
    });
    const exe = b.addExecutable(.{
        .name = "picowy-sdl3",
        .root_module = start_mod,
    });
    const exe_install = b.addInstallArtifact(exe, .{});
    b.getInstallStep().dependOn(&exe_install.step);
}
