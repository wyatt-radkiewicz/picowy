//! SDL3 HAL Entry File
const std = @import("std");

// Rest of the hal and the main app
const app_main = @import("app");
const hal = @import("hal");

// SDL3 library
const sdl3 = @import("sdl3.zig").c;
const sdl3_main = @cImport({
    @cDefine("SDL_MAIN_HANDLED", "1");
    @cInclude("SDL3/SDL_main.h");
});

/// Full app state
const AppState = struct {
    // App state
    app_state: app_main.AppState,

    // Zig context
    init: std.process.Init,

    // SDL3 state
    window: *sdl3.SDL_Window,
    renderer: *sdl3.SDL_Renderer,
};

/// Work around for SDL_AppInit
var main_callbacks_init: std.process.Init = undefined;

pub fn main(init: std.process.Init) void {
    main_callbacks_init = init;
    const argc: c_int = 0;
    const argv: [*c][*c]u8 = null;
    _ = sdl3_main.SDL_RunApp(argc, argv, &SDL_AppMain, null);
}

pub export fn SDL_AppMain(argc: c_int, argv: [*c][*c]u8) callconv(.c) c_int {
    return sdl3_main.SDL_EnterAppMainCallbacks(
        argc,
        argv,
        @ptrCast(&SDL_AppInit),
        @ptrCast(&SDL_AppIterate),
        @ptrCast(&SDL_AppEvent),
        @ptrCast(&SDL_AppQuit),
    );
}

pub export fn SDL_AppInit(
    app_state_ptr: [*c]?*anyopaque,
    argc: c_int,
    argv: [*c][*c]u8,
) callconv(.c) sdl3.SDL_AppResult {
    _ = argc;
    _ = argv;

    // Allocate the app state
    app_state_ptr.* = main_callbacks_init.gpa.create(AppState) catch {
        sdl3.SDL_Log("Out of memory!");
        return sdl3.SDL_APP_FAILURE;
    };
    const app_state: *AppState = @ptrCast(@alignCast(app_state_ptr.*));
    app_state.* = .{
        .app_state = undefined,

        .init = main_callbacks_init,

        .window = undefined,
        .renderer = undefined,
    };

    // Set app metadata and initialize SDL3
    _ = sdl3.SDL_SetAppMetadata("Picowy Desktop Version", "1.0", "net.eklipsed.picowy");
    if (!sdl3.SDL_Init(sdl3.SDL_INIT_VIDEO)) {
        sdl3.SDL_Log("Couldn't initialize SDL: %s", sdl3.SDL_GetError());
        return sdl3.SDL_APP_FAILURE;
    }

    // Create a window and renderer
    if (!sdl3.SDL_CreateWindowAndRenderer(
        "Picowy Emulation Window",
        128 * 4,
        128 * 4,
        0,
        @ptrCast(&app_state.window),
        @ptrCast(&app_state.renderer),
    )) {
        sdl3.SDL_Log("Couldn't create window/renderer: %s", sdl3.SDL_GetError());
        return sdl3.SDL_APP_FAILURE;
    }
    _ = sdl3.SDL_SetRenderLogicalPresentation(
        app_state.renderer,
        128 * 4,
        128 * 4,
        sdl3.SDL_LOGICAL_PRESENTATION_LETTERBOX,
    );

    // Call app main
    app_state.app_state = app_main.onInit();
    return sdl3.SDL_APP_CONTINUE;
}

pub export fn SDL_AppEvent(
    app_state_ptr: ?*anyopaque,
    event: [*c]sdl3.SDL_Event,
) callconv(.c) sdl3.SDL_AppResult {
    _ = app_state_ptr;
    switch (event.*.type) {
        sdl3.SDL_EVENT_QUIT => return sdl3.SDL_APP_SUCCESS,
        else => return sdl3.SDL_APP_CONTINUE,
    }
}

pub export fn SDL_AppIterate(
    app_state_ptr: ?*anyopaque,
) callconv(.c) sdl3.SDL_AppResult {
    const app_state: *AppState = @ptrCast(@alignCast(app_state_ptr));
    const now = @as(f64, @floatFromInt(sdl3.SDL_GetTicks())) / 1000.0;
    const red: f32 = @floatCast(0.5 + 0.5 * sdl3.SDL_sin(now));
    const green: f32 = @floatCast(0.5 + 0.5 * sdl3.SDL_sin(now + sdl3.SDL_PI_D * 2 / 3));
    const blue: f32 = @floatCast(0.5 + 0.5 * sdl3.SDL_sin(now + sdl3.SDL_PI_D * 4 / 3));
    _ = sdl3.SDL_SetRenderDrawColorFloat(
        app_state.renderer,
        red,
        green,
        blue,
        sdl3.SDL_ALPHA_OPAQUE_FLOAT,
    );
    _ = sdl3.SDL_RenderClear(app_state.renderer);
    _ = sdl3.SDL_RenderPresent(app_state.renderer);
    app_main.onLoop(&app_state.app_state);
    return sdl3.SDL_APP_CONTINUE;
}

pub export fn SDL_AppQuit(
    app_state_ptr: ?*anyopaque,
    result: sdl3.SDL_AppResult,
) callconv(.c) void {
    const app_state: *AppState = @ptrCast(@alignCast(app_state_ptr));
    app_main.onDeinit(&app_state.app_state);
    app_state.init.gpa.destroy(app_state);
    _ = result;
}
