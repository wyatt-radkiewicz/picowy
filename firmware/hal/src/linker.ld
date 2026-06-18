/* STM32L0 linker script, see RM0377 Section 2.2.2 */

/* Main Memory Sections */
MEMORY {
	flash (rx) : org = 0x08000000, l = 16K
	sram (!rx) : org = 0x20000000, l = 2K
}

/* ELF Sections */
SECTIONS {
	/*
	 * If using the optimized module options, unwind tables are not needed, but sometimes are
	 * still included. This omits them from the final elf.
	 */
	/DISCARD/ : {
		*(*.exidx)
	}

	.vectors : {
		KEEP(*(*.vectors))
	} >flash

	.text : {
		*(*.text)
	} >flash

	.rodata : {
		*(*.rodata)
	} >flash

	.data : {
		data_start = .;
		*(*.data)
		data_size = . - data_start;
	} >flash

	sram_start = 0x20000000;

	.bss (NOLOAD) : {
		. = ALIGN(4);
		bss_start = .;
		*(*.bss)
		bss_size = . - bss_start;
	} >sram

	stack_start = 0x20000000 + 2K;
}

