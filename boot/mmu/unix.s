                    .include  "include/macros.i"

                    .data
                    .align(16)

                    .global   UNIX_MMU_TABLE_A
                    .global   UNIX_MMU_CRP
                    .global   UNIX_MMU_TCR

dt_Page             =         0x0
dt_page             =         0x1
dt_short            =         0x2
dt_long             =         0x3

io_space            =         0xFFFF0000

                                                                      | +------------------------------------------------+ 
                                                                      | | SHORT FORMAT TABLE DESCRIPTOR                  | 
                                                                      | +-----+--------+---------------------------------+ 
                                                                      | | Bit | Length | Contents                        | 
                                                                      | +-----+--------+---------------------------------+ 
                                                                      | | 00  |   02   | Descriptor Type (DT)            | 
                                                                      | | 02  |   01   | Write Protect (WP)              | 
                                                                      | | 03  |   01   | Update (U)                      | 
                                                                      | | 04  |   28   | Table Address                   | 
                                                                      | +-----+--------+---------------------------------+
                                                                      | This entry points to the base adress of the next level table.
                                                                      |
                                                                      | +------------------------------------------------+ 
                                                                      | | SHORT FORMAT EARLY TERMINATION PAGE DESCRIPTOR | 
                                                                      | +-----+--------+---------------------------------+ 
                                                                      | | Bit | Length | Contents                        | 
                                                                      | +-----+--------+---------------------------------+ 
                                                                      | | 00  |   02   | Descriptor Type (DT)            | 
                                                                      | | 02  |   01   | Write Protect (WP)              | 
                                                                      | | 03  |   01   | Update (U)                      | 
                                                                      | | 04  |   01   | Modified (M)                    | 
                                                                      | | 05  |   01   | Reserved ( must be 0 )          | 
                                                                      | | 06  |   01   | Cache Inhibit (CI)              | 
                                                                      | | 07  |   01   | Reserved ( must be 0 )          | 
                                                                      | | 08  |   24   | Page Address                    | 
                                                                      | +-----+--------+---------------------------------+
                                                                      | This entry points to the base address of a page of memory.
                                                                      |
                                                                      | +-------+-----------------------------------+
                                                                      | | Value | Contents                          |
                                                                      | +-------+-----------------------------------+
                                                                      | |   0x0 | Invalid                           |
                                                                      | |   0x1 | Page Descriptor                   |
                                                                      | |   0x2 | Valid 4 byte (short format) table |
                                                                      | |   0x3 | Valid 8 byte (long format) table  |
                                                                      | +-------+-----------------------------------+
                                                                      | Descriptor type values

                                                                      | Table A splits the 68000's 24bit address space into 16 1MB pages
                                                                      | IS (initial shift) is 8, therefore, the 8 most significant bits are ignored
                                                                      | TIA (table A index bits) is 4, therefore, 16 entries are required in this table
                                                                      |
                                                                      |-----------------------+------------------------+-----------------+
                                                                      | Logical Address Range | Physical Address Range | Descriptor type |
                                                                      |-----------------------+------------------------+-----------------+
UNIX_SRP_TABLE_A:   .long     0x00000000+dt_page                      | 0x00000000-0x000FFFFF | 0x00000000-0x000FFFFF  | Page (1MB)      |
                    .long     0x00100000+dt_page                      | 0x00100000-0x001FFFFF | 0x00100000-0x001FFFFF  | Page (1MB)      |
                    .long     0x00200000+dt_page                      | 0x00200000-0x002FFFFF | 0x00200000-0x002FFFFF  | Page (1MB)      |
                    .long     0x00300000+dt_page                      | 0x00300000-0x003FFFFF | 0x00300000-0x003FFFFF  | Page (1MB)      |
                    .long     0x00400000+dt_page                      | 0x00400000-0x004FFFFF | 0x00400000-0x004FFFFF  | Page (1MB)      |
                    .long     0x00500000+dt_page                      | 0x00500000-0x005FFFFF | 0x00500000-0x005FFFFF  | Page (1MB)      |
                    .long     0x00600000+dt_page                      | 0x00600000-0x006FFFFF | 0x00600000-0x006FFFFF  | Page (1MB)      |
                    .long     0x00700000+dt_page                      | 0x00700000-0x007FFFFF | 0x00700000-0x007FFFFF  | Page (1MB)      |
                    .long     0x00800000+dt_page                      | 0x00800000-0x008FFFFF | 0x00800000-0x008FFFFF  | Page (1MB)      |
                    .long     0x00900000+dt_page                      | 0x00900000-0x009FFFFF | 0x00900000-0x009FFFFF  | Page (1MB)      |
                    .long     0x00A00000+dt_page                      | 0x00A00000-0x00AFFFFF | 0x00A00000-0x00AFFFFF  | Page (1MB)      |
                    .long     0x00B00000+dt_page                      | 0x00B00000-0x00BFFFFF | 0x00B00000-0x00BFFFFF  | Page (1MB)      |
                    .long     0x00C00000+dt_page                      | 0x00C00000-0x00CFFFFF | 0x00C00000-0x00CFFFFF  | Page (1MB)      |
                    .long     0x00D00000+dt_page                      | 0x00D00000-0x00DFFFFF | 0x00D00000-0x00DFFFFF  | Page (1MB)      |
                    .long     0x00E00000+dt_page                      | 0x00E00000-0x00EFFFFF | 0x00E00000-0x00EFFFFF  | Page (1MB)      |
                    .long     UNIX_MMU_TABLE_B_F+dt_short             | 0x00F00000-0x00FFFFFF |                        | Short table     |
                                                                      |-----------------------+------------------------+-----------------+

UNIX_CRP_TABLE_A:   .long     0x00000000+dt_page                      | Initially identical to the SRP table A
                    .long     0x00100000+dt_page
                    .long     0x00200000+dt_page
                    .long     0x00300000+dt_page
                    .long     0x00400000+dt_page
                    .long     0x00500000+dt_page
                    .long     0x00600000+dt_page
                    .long     0x00700000+dt_page
                    .long     0x00800000+dt_page
                    .long     0x00900000+dt_page
                    .long     0x00A00000+dt_page
                    .long     0x00B00000+dt_page
                    .long     0x00C00000+dt_page
                    .long     0x00D00000+dt_page
                    .long     0x00E00000+dt_page
                    .long     UNIX_MMU_TABLE_B_F+dt_short

                                                                      | Table B (F) splits the upper 1MB page into 16 64KB pages
                                                                      | IS (initial shift) is 8, therefore, the 8 most significant bits are ignored
                                                                      | TIA (table A index bits) is 4
                                                                      | TIB (table b index bits) is 4, therefore, 16 entries are required in this table
                                                                      |
                                                                      |-----------------------+------------------------+-----------------+
                                                                      | Logical Address Range | Physical Address Range | Descriptor type |
                                                                      |-----------------------+------------------------+-----------------+
UNIX_MMU_TABLE_B_F: .long     0xF00000+dt_page                        | 0x00F00000-0x00F0FFFF | 0x00F00000-0x00F0FFFF  | Page (64KB)     | 
                    .long     0xF10000+dt_page                        | 0x00F10000-0x00F0FFFF | 0x00F10000-0x00F1FFFF  | Page (64KB)     |
                    .long     0xF20000+dt_page                        | 0x00F20000-0x00F0FFFF | 0x00F20000-0x00F2FFFF  | Page (64KB)     |
                    .long     0xF30000+dt_page                        | 0x00F30000-0x00F0FFFF | 0x00F30000-0x00F3FFFF  | Page (64KB)     |
                    .long     0xF40000+dt_page                        | 0x00F40000-0x00F0FFFF | 0x00F40000-0x00F4FFFF  | Page (64KB)     |
                    .long     0xF50000+dt_page                        | 0x00F50000-0x00F0FFFF | 0x00F50000-0x00F5FFFF  | Page (64KB)     |
                    .long     0xF60000+dt_page                        | 0x00F60000-0x00F0FFFF | 0x00F60000-0x00F6FFFF  | Page (64KB)     |
                    .long     0xF70000+dt_page                        | 0x00F70000-0x00F0FFFF | 0x00F70000-0x00F7FFFF  | Page (64KB)     |
                    .long     0xF80000+dt_page                        | 0x00F80000-0x00F0FFFF | 0x00F80000-0x00F8FFFF  | Page (64KB)     |
                    .long     0xF90000+dt_page                        | 0x00F90000-0x00F0FFFF | 0x00F90000-0x00F9FFFF  | Page (64KB)     |
                    .long     0xFA0000+dt_page                        | 0x00FA0000-0x00F0FFFF | 0x00FA0000-0x00FAFFFF  | Page (64KB)     |
                    .long     0xFB0000+dt_page                        | 0x00FB0000-0x00F0FFFF | 0x00FB0000-0x00FBFFFF  | Page (64KB)     |
                    .long     0xFC0000+dt_page                        | 0x00FC0000-0x00F0FFFF | 0x00FC0000-0x00FCFFFF  | Page (64KB)     |
                    .long     0xFD0000+dt_page                        | 0x00FD0000-0x00F0FFFF | 0x00FD0000-0x00FDFFFF  | Page (64KB)     |
                    .long     0xFE0000+dt_page                        | 0x00FE0000-0x00F0FFFF | 0x00FE0000-0x00FEFFFF  | Page (64KB)     |
                    .long     io_space+dt_page                        | 0x00FF0000-0x00F0FFFF | 0xFFFF0000-0xFFFFFFFF  | Page (64KB)     |
                                                                      |-----------------------+------------------------+-----------------+

                                                                      |  +------------------------------------------------+
                                                                      |  | ROOT POINTER (CRP/SRP)                         |
                                                                      |  +-----+--------+---------------------------------+
                                                                      |  | Bit | Length | Contents                        |
                                                                      |  +-----+--------+---------------------------------+
                                                                      |  | 00  |   04   | reserved ( must be 0 )          |
                                                                      |  | 04  |   28   | TableA Address (upper 28 bits)  |
                                                                      |  | 32  |   02   | Descriptor Type for table A     |
                                                                      |  | 34  |   14   | reserved ( must be 0 )          |
                                                                      |  | 48  |   15   | Limit                           |
                                                                      |  | 63  |   01   | Lower (0) or upper (1) limit    |
                                                                      |  +----+---------+---------------------------------+

* Set the CPU (user) root pointer to the 4byte CRP Table A with no limit
UNIX_MMU_CRP:       .long     0x7FFF0002                              | DT=2 (valid short, 4 byte, table), Limit=0x7FFF, L/U=0 (Lower limit)
                    .long     UNIX_CRP_TABLE_A

* Set the Superviser root pointer to the 4byte SRP Table A with no limit
UNIX_MMU_SRP:       .long     0x7FFF0002                              | DT=2 (valid short, 4 byte, table), Limit=0x7FFF, L/U=0 (Lower limit)
                    .long     UNIX_SRP_TABLE_A

                                                                      | +------------------------------------------------+
                                                                      | | TRANSLATION CONTROL (TC)                       |
                                                                      | +-----+--------+---------------------------------+
                                                                      | | Bit | Length | Contents                        |
                                                                      | +-----+--------+---------------------------------+
                                                                      | | 00  |   04   | TableD Index (TID) bits         |
                                                                      | | 04  |   04   | TableC Index (TIC) bits         |
                                                                      | | 08  |   04   | TableB Index (TIB) bits         |
                                                                      | | 12  |   04   | TableA Index (TIA) bits         |
                                                                      | | 16  |   04   | Initial Shift (IS) bits         |
                                                                      | | 20  |   04   | Page Size (PS)                  |
                                                                      | | 24  |   01   | Function Code Lookup (FCL)      |
                                                                      | | 25  |   01   | Supervisor Root Enable (SRE)    |
                                                                      | | 26  |   05   | unused                          |
                                                                      | | 31  |   01   | Enable (E)                      |
                                                                      | +-----+--------+---------------------------------+
                                                                      |
                                                                      | +-------------------------+
                                                                      | | PAGE SIZE (PS)          |
                                                                      | +-------+-----+-----------+
                                                                      | | Value | Hex | Page Size |
                                                                      | +-------+-----+-----------+
                                                                      | | 1000  |   8 | 256 bytes |
                                                                      | | 1001  |   9 | 512 bytes |
                                                                      | | 1010  |   A | 1KB       |
                                                                      | | 1011  |   B | 4KB       |
                                                                      | | 1100  |   C | 8KB       |
                                                                      | | 1101  |   D | 16KB      |
                                                                      | | 1111  |   E | 32KB      |
                                                                      | +-------+-----+-----------+

UNIX_MMU_TCR:       .long     0x82E84420                              | TID=0, TIC=2, TIB=4, TIA=4, IS=8, PS=E (32KB), FCL=0, SRE=1, E=1 (enabled)
                                                                      |
                                                                      | IS + TIA + TIB + TIC + TID + PS must equal 32
                                                                      | 8 + 4 + 4 + 2 + 0 + 14 = 32

UNIX_MMU_TT0:       .long     0xFF008507


                    .text
                    .global   initUnixMMU


initUnixMMU:
                    PUTS      strInit
*					PMOVE	UNIX_MMU_TT0,%TT0
                    PMOVE     UNIX_MMU_CRP,%CRP
                    PMOVE     UNIX_MMU_SRP,%SRP
                    PMOVE     UNIX_MMU_TCR,%TC
                    PUTS      strDone
                    RTS


strInit:            .asciz    "\r\nInitialise the MMU for UNIX"
strDone:            .asciz    "\r\n\r\n"
