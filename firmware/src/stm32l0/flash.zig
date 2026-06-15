/// FLASH Subsystem
const regs = @import("regs.zig");

/// Flash Configuration
pub const Config = struct {
    /// RM0377 Section 3.7.1 "Access control register (FLASH_ACR)"
    /// The value of this bit specifies if a 0 or 1 wait-state is necessary to read the NVM. The
    /// user must write the correct value relative to the core frequency and the operation mode
    /// (power). The correct value to use can be found in Table 15. No check is done to verify if
    /// the configuration is correct.
    /// To increase the clock frequency, the user has to change this bit to ‘1’, then to increase
    /// the frequency. To reduce the clock frequency, the user has to decrease the frequency, then
    /// to change this bit to ‘0’.
    ///     0: Zero wait state is used to read a word in the NVM.
    ///     1: One wait state is used to read a word in the NVM.
    wait_states: u1,

    /// RM0377 Section 3.7.1 "Access control register (FLASH_ACR)"
    /// This bit enables the prefetch. It is automatically reset every time the DISAB_BUF bit (in this
    /// register) is set to 1. To know how the prefetch works, see the Fetch and prefetch section.
    ///     false: The prefetch is disabled.
    ///     true: The prefetch is enabled. The memory interface stores the last address fetched and
    ///     tries to read the next one when no other read or write operation is ongoing.
    prefetch_enable: bool,

    /// RM0377 Section 3.7.1 "Access control register (FLASH_ACR)"
    /// This bit allows to have the Flash program memory and data EEPROM in power-down mode or
    /// in idle mode when the device is in Sleep mode.
    ///     false: When the device is in Sleep mode, the NVM is in Idle mode.
    ///     true: When the device is in Sleep mode, the NVM is in power-down mode.
    sleep_power_down: bool,

    /// RM0377 Section 3.7.1 "Access control register (FLASH_ACR)"
    /// This bit disables the buffers used as a cache during a read. This means that every read will
    /// access the NVM even for an address already read (for example, the previous address). When
    /// this bit is reset, the PRFTEN and PRE_READ bits are automatically reset, too.
    ///     false: The buffers are enabled
    ///     true: The buffers are disabled. Every time one NVM value is necessary, one new memory
    ///     read sequence has do be done.
    disable_cache: bool,

    /// RM0377 Section 3.7.1 "Access control register (FLASH_ACR)"
    /// This bit enables the pre-read.
    ///     false: The pre-read is disabled
    ///     true: The pre-read is enabled. The memory interface stores the last address read as
    ///     data and tries to read the next one when no other read or write or prefetch operation
    ///     is ongoing.
    /// Note: It is automatically reset every time the DISAB_BUF bit (in this register) is set to 1.
    pre_read: bool,

    /// Apply the config
    pub fn apply(comptime this: @This()) void {
        regs.flash.acr.* = comptime regs.flash.ACR{
            .latency = this.wait_states,
            .prften = this.prefetch_enable,
            .sleep_pd = this.sleep_power_down,
            .run_pd = false,
            .disab_buf = this.disable_cache,
            .pre_read = this.pre_read,
        };
    }
};
