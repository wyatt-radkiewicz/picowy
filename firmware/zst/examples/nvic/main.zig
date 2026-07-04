const zst = @import("zst");

// None of our vector handlers do anything (in this example)
pub const vector_table = zst.vector_table.build(.init(.{}));

pub fn main() void {
    zst.nvic.IRQ.i2c1.setEnable(true);
    zst.nvic.IRQ.i2c1.setPriority(0x40);

    // Loop forever (returning from main doesn't make sense)
    while (true) {}
}
