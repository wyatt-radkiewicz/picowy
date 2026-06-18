//! Base startup example
const hal = @import("hal");

pub const vector_table = hal.vectorTable(.init(.{}));

pub fn main() noreturn {
    while (true) {}
}
