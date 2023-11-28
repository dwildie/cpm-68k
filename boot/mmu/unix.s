					.include  "include/macros.i"
					
                    .data
                    .align(16)
                    
                    .global UNIX_MMU_TABLE_A
                    .global UNIX_MMU_CRP
                    .global UNIX_MMU_TCR

dt_invalid      =         0x0
dt_page         =         0x1
dt_short        =         0x2
dt_long         =         0x3

io_space        =         0xFFFF0000

                    
UNIX_MMU_TABLE_A:   .long	0x000000+dt_page					| 0x0000 -> Invalid
					.long	0x100000+dt_page					| 0x0010 -> Invalid
					.long	0x200000+dt_page					| 0x0020 -> Invalid
					.long	0x300000+dt_page					| 0x0030 -> Invalid
					.long	0x400000+dt_page					| 0x0040 -> Invalid
					.long	0x500000+dt_page					| 0x0050 -> Invalid
					.long	0x600000+dt_page					| 0x0060 -> Invalid
					.long	0x700000+dt_page					| 0x0070 -> Invalid
					.long	0x800000+dt_page					| 0x0080 -> Invalid
					.long	0x900000+dt_page					| 0x0090 -> Invalid
					.long	0xA00000+dt_page					| 0x00A0 -> Invalid
					.long	0xB00000+dt_page					| 0x00B0 -> Invalid
					.long	0xC00000+dt_page					| 0x00C0 -> Invalid
					.long	0xD00000+dt_page					| 0x00D0 -> Invalid
					.long	0xE00000+dt_page					| 0x00E0 -> Invalid
					.long	UNIX_MMU_TABLE_B+dt_short			| 0x00F0 -> Table B 

UNIX_MMU_TABLE_B:   .long	0xF00000+dt_page					| 0x00F0 -> Invalid
					.long	0xF10000+dt_page					| 0x00F1 -> Invalid
					.long	0xF20000+dt_page					| 0x00F2 -> Invalid
					.long	0xF30000+dt_page					| 0x00F3 -> Invalid
					.long	0xF40000+dt_page					| 0x00F4 -> Invalid
					.long	0xF50000+dt_page					| 0x00F5 -> Invalid
					.long	0xF60000+dt_page					| 0x00F6 -> Invalid
					.long	0xF70000+dt_page					| 0x00F7 -> Invalid
					.long	0xF80000+dt_page					| 0x00F8 -> Invalid
					.long	0xF90000+dt_page					| 0x00F9 -> Invalid
					.long	0xFA0000+dt_page					| 0x00FA -> Invalid
					.long	0xFB0000+dt_page					| 0x00FB -> Invalid
					.long	0xFC0000+dt_page					| 0x00FC -> Invalid
					.long	0xFD0000+dt_page					| 0x00FD -> Invalid
					.long	0xFE0000+dt_page					| 0x00FE -> Invalid
					.long	io_space+dt_page					| 0x00FF -> 0xFFFF 

UNIX_MMU_CRP:		.long	0x7FFF0002
					.long	UNIX_MMU_TABLE_A
						
UNIX_MMU_TCR:		.long   0x82E84420	

UNIX_MMU_TT0:		.long   0xFF008507									
                    .text
                    .global initUnixMMU
                    
                    
initUnixMMU:		
					PUTS      strInit
*					PMOVE	UNIX_MMU_TT0,%TT0
					PMOVE	UNIX_MMU_CRP,%CRP
					PMOVE	UNIX_MMU_CRP,%SRP
					PMOVE	UNIX_MMU_TCR,%TC
					PUTS      strDone
					RTS


strInit:  .asciz    "\r\nInitialise the MMU for UNIX"
strDone:  .asciz    "\r\n\r\n"
					