//! STM32 HAL Root File

// Interrupts Abstraction
const interrupt = @import("interrupt.zig");
pub const Interrupt = interrupt.Interrupt;
pub const vectorTable = interrupt.vectorTable;
