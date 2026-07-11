const std = @import("std");

/// Each backend the HAL supports goes here
const Backend = enum {
    sdl3,

    /// Gets the resovled target for this backend
    fn getTarget(this: @This(), b: *std.Build) std.Build.ResolvedTarget {
        return switch (this) {
            .sdl3 => b.resolveTargetQuery(.{}),
        };
    }
};

pub fn build(b: *std.Build) void {
    // Get build options
    const backend = b.option(Backend, "backend", "Which backend to use for the HAL.") orelse
        .sdl3;
    const optimize = b.standardOptimizeOption(.{});

    // C Compiler configuration
    const base_flags = &[_][]const u8{"-std=c23"};

    // Top level build steps
    const run_step = b.step("run", "Run and or flash the app.");

    // Create the base module
    const mod = switch (backend) {
        .sdl3 => b.createModule(.{
            .target = backend.getTarget(b),
            .optimize = optimize,
            .link_libc = true,
            .sanitize_c = .off,
        }),
    };
    mod.addCSourceFiles(.{
        .root = b.path(""),
        .flags = base_flags,
        .files = &.{
            "src/app.c",
        },
    });

    // Add in which backend we are using
    switch (backend) {
        .sdl3 => {
            mod.addCSourceFile(.{
                .flags = base_flags,
                .file = b.path("src/hal/sdl3.c"),
            });
            mod.linkSystemLibrary("sdl3", .{
                .needed = true,
                .use_pkg_config = .yes,
                .preferred_link_mode = .static,
            });
        },
    }

    // Build the executable and install it
    switch (backend) {
        .sdl3 => {
            const exe = b.addExecutable(.{
                .name = "picowy-sdl3",
                .root_module = mod,
            });
            b.installArtifact(exe);
            run_step.dependOn(&b.addRunArtifact(exe).step);
        },
    }
}
