*-----------------------------------------------------------------------------------------------------
                    .include  "include/disk.i"

                    .text
                    .global   cmxInitDrives
                    .global   cmxGetDriveStatus
                    .global   cmxReadDriveBlock
                    .global   cmxWriteDriveBlock
                    .global   cmxInitConsole
                    .global   cmxOutChar
                    .global   cmxInChar

*-----------------------------------------------------------------------------------------------------
* Get the status of both drives
*-----------------------------------------------------------------------------------------------------
cmxInitDrives:      MOVEM.L   %D1-%D7/%A0-%A7,-(%SP)

                    BSR       initDataSegs                            | Initialise the initialised data degment
                    BSR       ioInit                                  | Initialise the i/o subsystem
                    BSR       initialiseDiskSys                       | Initialise the disk subsystem
                    BSR       initDrives                              | List the available drives

                    MOVEM.L   (%SP)+,%D1-%D7/%A0-%A7
                    JMP       cmxGetDriveStatus

*-----------------------------------------------------------------------------------------------------
* Get the status of both drives
*-----------------------------------------------------------------------------------------------------
cmxGetDriveStatus:  MOVE.L    %D1,-(%SP)

                    CLR.L     %D0
                    MOVE.W    driveStatus,%D1
                    CMP.B     #DISK_AVAILABLE,%D1
                    BNE       1f
                    OR.L      #0x1,%D0

1:                  LSR.W     #8,%D1
                    CMP       #DISK_AVAILABLE,%D1
                    BNE       2f
                    OR.L      #0x2,%d0

2:                  MOVE.L    (%SP)+,%D1
                    RTS

*-----------------------------------------------------------------------------------------------------
* Read drive block (long drive, long lba, byte *buffer, long count)
*-----------------------------------------------------------------------------------------------------
cmxReadDriveBlock:  LINK      %FP,#0
                    MOVEM.L   %D1-%D7/%A0-%A7,-(%SP)

                    MOVE.L    0x08(%FP),%D0                           | Param - drive
                    BSR       setIdeDrive                             | Select drive

                    MOVE.L    0x0C(%FP),%D0                           | Param - LBA
                    BSR       setLBA                                  | Set the LBA

                    MOVE.L    0x10(%FP),%A2                           | Param - Buffer address
                    MOVE.L    0x14(%FP),%D0                           | Param - Sector count
                    BSR       readSectors                             | Read the sectors

                    MOVEM.L   (%SP)+,%D1-%D7/%A0-%A7
                    UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* Write drive block (long drive, long lba, byte *buffer, long count)
*-----------------------------------------------------------------------------------------------------
cmxWriteDriveBlock: LINK      %FP,#0
                    MOVEM.L   %D1-%D7/%A0-%A7,-(%SP)

                    MOVE.L    0x08(%FP),%D0                           | Param - drive
                    BSR       setIdeDrive                             | Select drive

                    MOVE.L    0x0C(%FP),%D0                           | Param - LBA
                    BSR       setLBA                                  | Set the LBA

                    MOVE.L    0x10(%FP),%A2                           | Param - Buffer address
                    MOVE.L    0x14(%FP),%D0                           | Param - Sector count
                    BSR       writeSectors                            | Read the sectors

                    MOVEM.L   (%SP)+,%D1-%D7/%A0-%A7
                    UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* Initialise the console
*-----------------------------------------------------------------------------------------------------
cmxInitConsole:     MOVEM.L   %D1-%D7/%A0-%A7,-(%SP)
                    BSR       ioInit
                    MOVEM.L   (%SP)+,%D1-%D7/%A0-%A7
                    RTS

*-----------------------------------------------------------------------------------------------------
* Output a character to the current console device (unsigned long char)
*-----------------------------------------------------------------------------------------------------
cmxOutChar:         LINK      %FP,#0
                    MOVEM.L   %D1-%D7/%A0-%A7,-(%SP)
                    MOVE.L    0x08(%FP),%D1                           | Param - char
                    BSR       outch
                    MOVEM.L   (%SP)+,%D1-%D7/%A0-%A7
                    UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* Input a character from the current console device
*-----------------------------------------------------------------------------------------------------
cmxInChar:          MOVEM.L   %D1-%D7/%A0-%A7,-(%SP)
                    MOVE.L    #0,%D0
                    BSR       inch
                    MOVEM.L   (%SP)+,%D1-%D7/%A0-%A7
                    RTS

