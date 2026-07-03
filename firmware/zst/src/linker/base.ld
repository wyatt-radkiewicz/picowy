/* {[name]s} linker script */

/* Memory sections */
MEMORY {{
	flash (rx) : org = 0x{[flash_start]x:0>8}, len = 0x{[flash_size]x}
	sram (!rx) : org = 0x{[sram_start]x:0>8}, len = 0x{[sram_size]x}
}}

/* Linker sections */
SECTIONS {{
	/* Sometimes a unwind table is still generated, so disable it */
	/DISCARD/ : {{
		*(*.exidx)
	}}
	
	/* Default STM32 vector table */
	.vector_table : {{
		KEEP(*(.vector_table))
	}} >flash

	/* Program code */
	.text : {{
		*(.text)
	}} >flash

	/* Read only data */
	.rodata : {{
		/* Make sure biggest natural alignment holds */
		. = ALIGN(0x4);
		*(.rodata)
	}} >flash

	/* Initial data in flash, virtual location in sram */
	_data_dst_start = 0x{[sram_start]x};
	.data ADDR(.rodata) + SIZEOF(.rodata) (NOLOAD) : AT(_data_dst_start) {{
		/* Make sure biggest natural alignment holds */
		. = ALIGN(0x4);

		/* Start of the data segment */
		_data_src_start = .;
		*(.data)
		_data_size = . - _data_src_start;
	}}
	
	/* Variables initialized to zero */
	.bss (NOLOAD) : {{
		_bss_start = .;
		*(.bss)
	}} >sram
	_bss_size = SIZEOF(.bss);

	/* Start address of stack (end of ram) */
	_stack_start = 0x{[sram_start]x} + 0x{[sram_size]x};
}}
