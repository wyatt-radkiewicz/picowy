/* STM32L0 linker script, see RM0377 Section 2.2.2 */

MEMORY {
	flash (rx) : org = 0x08000000, l = 16K
	sram (!rx) : org = 0x20000000, l = 2K
}

SECTIONS {
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
		data_end = .;
	} >flash

	sram_start = 0x20000000;

	.bss (NOLOAD) : {
		. = ALIGN(4);
		bss_start = .;
		*(*.bss)
		bss_end = .;
	} >sram

	stack_start = 0x20000000 + 2K;
}

