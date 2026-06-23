//! Firmware build script
const std = @import("std");

const Build = std.Build;

pub fn build(b: *Build) void {
    _ = b.standardTargetOptions(.{});
    _ = b.standardOptimizeOption(.{});
}
