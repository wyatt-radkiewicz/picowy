const hal = @import("hal");

pub const AppState = struct {};

pub fn onInit() AppState {
    return .{};
}

pub fn onLoop(state: *AppState) void {
    _ = state;
}

pub fn onDeinit(state: *AppState) void {
    _ = state;
}
