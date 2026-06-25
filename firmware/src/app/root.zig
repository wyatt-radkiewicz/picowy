const std = @import("std");
const hal = @import("hal");

//
// Types
//
const State = *const fn () void;

//
// Constants
//
const max_sprites: u8 = 64;
const power_poll_interval: u8 = hal.update_rate;

//
// Variables
//
var touch_point: ?hal.Point = null; // (px, px)
var gravity: hal.FixedVec2 = .zero; // px/s^2
var power_status: hal.PowerStatus = .default;
var average_current: i16 = 0; // mA

var tick: u16 = 0;
var current_state: ?State = calibration;

var power_poll_timer: u8 = 0; // ticks

var sprites: ?[max_sprites]hal.Sprite = [1]hal.Sprite.none ** max_sprites;

//
// Assets
//

//
// Main loop
//
pub fn loop() void {
    // Poll inputs
    touch_point = hal.pollTouch();
    gravity = hal.pollAccelerometer();

    // Poll power status every 10 seconds
    if (power_poll_timer == 0) {
        power_status = hal.pollBattery();
        power_poll_timer = power_poll_interval + 1;
    } else {
        power_poll_timer -= 1;
    }

    // Run current tick
    current_state();
    tick +%= 1;
}

//
// Run touch panel calibration
//
fn calibration() void {}

//
// Simulate the world
//
fn simulation() void {}
