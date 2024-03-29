*-----------------------------------------------------------------------------------------------------
                    .include  "include/disk.i"
                    .include  "include/macros.i"
                    
                    .text
                    .global   biosInitDrives
                    .global   biosGetDriveStatus
                    .global   biosReadDriveBlock
                    .global   biosWriteDriveBlock
                    .global   biosInitConsole
                    .global   biosOutChar
                    .global   biosInChar
                    .global   biosHasChar
                    .global   biosReadDriveIdent
                    .global   biosGetDiskSize
                    .global   biosGetCommandTokenCount
                    .global   biosGetCommandToken

Carry		        = 0b00000001 | Carry bit
NotCarry  	        = 0b11111110

*-----------------------------------------------------------------------------------------------------
* Get the status of both drives
*-----------------------------------------------------------------------------------------------------
biosInitDrives:     MOVEM.L   %D1-%D7/%A0-%A7,-(%SP)

                    BSR       initDataSegs                            | Initialise the initialised data degment
                    BSR       ioInit                                  | Initialise the i/o subsystem
                    BSR       initialiseDiskSys                       | Initialise the disk subsystem
                    BSR       initDrives                              | List the available drives

                    MOVEM.L   (%SP)+,%D1-%D7/%A0-%A7
                    JMP       biosGetDriveStatus

*-----------------------------------------------------------------------------------------------------
* Get the status of both drives
*-----------------------------------------------------------------------------------------------------
biosGetDriveStatus: MOVE.L    %D1,-(%SP)
                    
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
* Read drive ident (long drive, byte *buffer)
*-----------------------------------------------------------------------------------------------------
biosReadDriveIdent: LINK      %FP,#0
                    MOVEM.L   %D1-%D7/%A0-%A7,-(%SP)

                    MOVE.L    0x08(%FP),%D0                           | Param - drive
                    BSR       setIdeDrive                             | Select drive

                    MOVE.L    0x0C(%FP),-(%A7)                        | Param - Buffer address
					BSR       getDriveIdent
					ADD.L     #4,%A7
					
                    MOVEM.L   (%SP)+,%D1-%D7/%A0-%A7
                    UNLK      %FP
                    RTS       
 
*-----------------------------------------------------------------------------------------------------
* biosGetDiskSize(long drive)
*-----------------------------------------------------------------------------------------------------
biosGetDiskSize:    LINK      %FP,#0
                    MOVEM.L   %D1-%D7/%A0-%A7,-(%SP)
                    
                    MOVE.L    0x08(%FP),%D0                           | Param - drive
                    MOVE.W    %d0,-(%A7)
                    BSR       getDiskSize
                    ADDQ.L    #2,%A7
                                            
                    MOVEM.L   (%SP)+,%D1-%D7/%A0-%A7
                    UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* Read drive block (long drive, long lba, byte *buffer, long count)
*-----------------------------------------------------------------------------------------------------
biosReadDriveBlock: LINK      %FP,#0
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
biosWriteDriveBlock: LINK     %FP,#0
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
biosInitConsole:    MOVEM.L   %D1-%D7/%A0-%A7,-(%SP)
                    BSR       ioInit
                    MOVEM.L   (%SP)+,%D1-%D7/%A0-%A7
                    RTS

*-----------------------------------------------------------------------------------------------------
* Output a character to the current console device (unsigned long char)
*-----------------------------------------------------------------------------------------------------
biosOutChar:        LINK      %FP,#0
                    MOVEM.L   %D1-%D7/%A0-%A7,-(%SP)
                    MOVE.L    0x08(%FP),%D0                           | Param - char
                    BSR       outch
                    MOVEM.L   (%SP)+,%D1-%D7/%A0-%A7
                    UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* Input a character from the current console device
*-----------------------------------------------------------------------------------------------------
biosInChar:         MOVEM.L   %D1-%D7/%A0-%A7,-(%SP)
                    MOVE.L    #0,%D0
                    BSR       inch
                    MOVEM.L   (%SP)+,%D1-%D7/%A0-%A7
                    RTS

*-----------------------------------------------------------------------------------------------------
* Return zero if a input char is available, otherwise non-zero
*-----------------------------------------------------------------------------------------------------
biosHasChar:        MOVEM.L   %D1-%D7/%A0-%A7,-(%SP)
                    MOVE.L    #0,%D0
                    BSR       keystat
                    BEQ       1f
                    MOVE.L    #0x0,%D0
                    BRA       2f
1:                  MOVE.L    #0x1,%D0
2:                  MOVEM.L   (%SP)+,%D1-%D7/%A0-%A7
                    RTS

*-----------------------------------------------------------------------------------------------------
* Get the command token count
*-----------------------------------------------------------------------------------------------------
biosGetCommandTokenCount: 
                    MOVE.W    cmdTokenCount,%D0
                    RTS
                                        
*-----------------------------------------------------------------------------------------------------
* Get the command token address
*-----------------------------------------------------------------------------------------------------
biosGetCommandToken: 
                    LINK      %FP,#0 
                    MOVEM.L   %D1-%D7/%A0-%A7,-(%SP)

                    MOVE.L    0x08(%FP),%D0                           | Param - arg number
                    MOVE.W    cmdTokenCount,%D1
                    CMP       %D1,%D0
                    BLO       1f
                    ORI.B     #Carry,%CCR                             | Set carry
                    BRA       5f
                    
1:                  LEA.L     cmdTokens,%A0
                    LSL.L     #2,%D0
                    ADD.L     %A0,%D0
                    AND.B     #NotCarry,%CCR                          | Clear carry
                    
5:                  MOVEM.L   (%SP)+,%D1-%D7/%A0-%A7
                    UNLK      %FP
                    RTS
                    
