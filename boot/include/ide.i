*-----------------------------------------------------------------------------------------------------
* i8255 ports
*-----------------------------------------------------------------------------------------------------
*I8255_PORT_A        =         0x00FF0030                    | lower 8 bits of IDE interface
*I8255_PORT_B        =         I8255_PORT_A + 1              | upper 8 bits of IDE interface
*I8255_PORT_C        =         I8255_PORT_A + 2              | control lines for IDE interface
*I8255_PORT_CTRL     =         I8255_PORT_A + 3              | 8255 configuration port
*I8255_PORT_DRIVE    =         I8255_PORT_A + 4              | To select the 1st or 2nd CF card/drive

*-----------------------------------------------------------------------------------------------------
* i8255 configuration
*-----------------------------------------------------------------------------------------------------
I8255_CFG_READ      =         0b10010010                              | Set 8255 I8255_PORT_C out, I8255_PORT_A&B input
I8255_CFG_WRITE     =         0b10000000                              | Set all three 8255 ports output

*-----------------------------------------------------------------------------------------------------
* IDE control lines for use with 8255_PORT_C.
*-----------------------------------------------------------------------------------------------------
LINE_A0             =         0x01                                    | direct from 8255 to IDE interface
LINE_A1             =         0x02                                    | direct from 8255 to IDE interface
LINE_A2             =         0x04                                    | direct from 8255 to IDE interface
LINE_CS0            =         0x08                                    | inverter between 8255 and IDE interface
LINE_CS1            =         0x10                                    | inverter between 8255 and IDE interface
LINE_WRITE          =         0x20                                    | inverter between 8255 and IDE interface
LINE_READ           =         0x40                                    | inverter between 8255 and IDE interface
LINE_RESET          =         0x80                                    | inverter between 8255 and IDE interface

*-----------------------------------------------------------------------------------------------------
* IDE Drive registers, this makes the code more readable than always specifying the address pins
*-----------------------------------------------------------------------------------------------------
REG_DATA            =         LINE_CS0                                | 0x08 - Data register (RW)
REG_ERROR           =         LINE_CS0 + LINE_A0                      | 0x09 - Error registr(R) - Feature register (w)
REG_SEC_COUNT       =         LINE_CS0 + LINE_A1                      | 0x0A - Sector Count register (RW)
REG_SEC_LOW         =         LINE_CS0 + LINE_A1 + LINE_A0            | 0x0B - LBA Low register (RW)
REG_SEC_MID         =         LINE_CS0 + LINE_A2                      | 0x0C - LBA Mid register (RW)
REG_SEC_HIGH        =         LINE_CS0 + LINE_A2 + LINE_A0            | 0x0D - LBA High register (RW)
REG_SDH             =         LINE_CS0 + LINE_A2 + LINE_A1            | 0x0E - Drive/Head register (RW)
REG_COMMAND         =         LINE_CS0 + LINE_A2 + LINE_A1 + LINE_A0  | 0x0F - Command register (W)
REG_STATUS          =         LINE_CS0 + LINE_A2 + LINE_A1 + LINE_A0  | 0x0F - Status register (R)
REG_CONTROL         =         LINE_CS1 + LINE_A2 + LINE_A1            | 0x16
REG_ASTATUS         =         LINE_CS1 + LINE_A2 + LINE_A1 + LINE_A0  | 0x17

*-----------------------------------------------------------------------------------------------------
* IDE commands
*-----------------------------------------------------------------------------------------------------
CMD_RECAL           =         0x10
CMD_READ            =         0x20
CMD_WRITE           =         0x30
CMD_INIT            =         0x91
CMD_ID              =         0xEC
CMD_SPIN_DOWN       =         0xE0
CMD_SPIN_UP         =         0xE1

*-----------------------------------------------------------------------------------------------------
* IDE status register
*-----------------------------------------------------------------------------------------------------
STATUS_BUSY_BIT     =         7                                       | device busy
STATUS_READY_BIT    =         6                                       | device ready
STATUS_FAULT_BIT    =         5                                       | device fault
STATUS_DSC_BIT      =         4                                       | seek complete
STATUS_DRQ_BIT      =         3                                       | data transfer requested
STATUS_CORR_BIT     =         2                                       | data corrected
STATUS_IDX_BIT      =         1                                       | index mark
STATUS_ERR_BIT      =         0                                       | error

STATUS_BIT_BUSY     =         0b10000000                              | device busy
STATUS_BIT_READY    =         0b01000000                              | device ready
STATUS_BIT_DRQ      =         0b00001000                              | data transfer requested
STATUS_MASK_BUSY_RDY =        STATUS_BIT_BUSY + STATUS_BIT_READY      | busy & ready bits
STATUS_MASK_BUSY_DRQ =        STATUS_BIT_BUSY + STATUS_BIT_DRQ

*-----------------------------------------------------------------------------------------------------
* IDE error register
*-----------------------------------------------------------------------------------------------------
ERR_BAD_BLOCK_BIT   =         7                                       | Bad block detected
ERR_UNCORRECT_BIT   =         6                                       | Uncorrectable data error
ERR_CHANGED_BIT     =         5                                       | Media changed
ERR_NOT_FOUND_BIT   =         4                                       | Sector ID not found
ERR_MEDIA_RQST_BIT  =         3                                       | Media change requested
ERR_ABORT_BIT       =         2                                       | Command aborted
ERR_TRACK_NF_BIT    =         1                                       | Track zero not found
ERR_ADDR_NF_BIT     =         0                                       | Address mark not found


IDE_SEC_SIZE        =         512                                     | All IDE drives use a 512 byte sector size

*IDE_RESET_DELAY_B   =         0x2                                     | Base time delay for reset/initilization (~66 uS, with 8MHz 8086, 1 I/O wait state)
*IDE_WAIT_RDY_B      =         0x100                                   | Base time delay for drive to become ready
*IDE_WAIT_DRQ_B      =         0x200                                   | Base time delay for data to be available
*IDE_START_DELAY_B   =         0x10                                    | Aprox 500 millisecond delay
