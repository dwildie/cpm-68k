                    .include  "include/macros.i"
                    .include  "include/ide.i"

                    .text
                    .global   setIdeLba
                    .global   setIdeDrive
                    .global   initIdeDrive
                    .global   getDriveIdent
                    .global   readSectors
                    .global   writeSectors
                    .global   showErrors

*-----------------------------------------------------------------------------------------------------


*-----------------------------------------------------------------------------------------------------
* Select Drive 0 (A) or 1 (B)
*-----------------------------------------------------------------------------------------------------
setIdeDrive:        MOVE.B    %D0,I8255_PORT_DRIVE          | Select Drive 0 (A) or 1 (B)
                    RTS

*-----------------------------------------------------------------------------------------------------
* Initilze the 8255 and drive then do a hard reset on the drive, by default the drive will come up initilized in LBA mode.
*-----------------------------------------------------------------------------------------------------
initIdeDrive:       MOVE.B    #I8255_CFG_READ,I8255_PORT_CTRL | Config 8255 chip, READ mode
                    MOVE.B    #LINE_RESET,I8255_PORT_C      | Hard reset the disk drive

                    MOVE.W    #IDE_RESET_DELAY,%D1          | Time delay for reset/initilization (~66 uS, with 8MHz 8086, 1 I/O wait state)
1:                  SUBQ.W    #1,%D1
                    BNE       1b                            | Delay (IDE reset pulse width)

                    MOVE.B    #0,I8255_PORT_C               | No IDE control lines asserted

                    BSR       DELAY_32                      | Allow time for CF/Drive to recover

                    BSR       waitNotBusy                   | Wait for the drive to be ready
                    BCS       5f

                    MOVE.B    #0b11100000,%D4               | Data for IDE SDH reg (512bytes, LBA mode, single drive, head 0000)
                    MOVE.B    #REG_SDH,%D5
                    BSR       write8255PortA                | Write byte to select the MASTER device

                    MOVE.W    #0xFF,%D6                     | <<< May need to adjust delay time
2:                  MOVE.B    #REG_STATUS,%D5               | Get status after initilization
                    BSR       read8255PortA                 | Check Status (info in [DH])
                    MOVE.B    %D4,%D1
                    AND.B     #STATUS_MASK_BUSY_RDY,%D1
                    EOR.B     #STATUS_BIT_READY,%D1
                    BEQ       6f                            | Return if ready bit is zero

                    MOVE.L    #0x0FFFF,%D7
3:                  MOVE.B    #2,%D5                        | May need to adjust delay time to allow cold drive to
4:                  SUBQ.B    #1,%D5                        | to come up to speed
                    BNE       4b
                    SUBQ.B    #1,%D7
                    BNE       3b

                    DBRA      %D6,2b

5:                  BSR       showErrors                    | Ret with NZ flag set if error (probably no drive)
                    RTS

6:                  MOVE.W    #0,%D0
                    RTS

DELAY_32:           MOVE.B    #40,%D1                       | DELAY ~32 MS (DOES NOT SEEM TO BE CRITICAL)
1:                  MOVE.B    #0,%D2
2:                  SUBQ.B    #1,%D2
                    BNE       2b
                    SUBQ.B    #1,%D1
                    BNE       1b
                    RTS

*-----------------------------------------------------------------------------------------------------
* Read the selected drives id data into the buffer at %A2
*-----------------------------------------------------------------------------------------------------
getDriveIdent:      LINK      %FP,#0
                    MOVEM.L   %D1-%D6/%A2,-(%SP)

                    MOVE.W    #IDE_SEC_SIZE,-(%SP)
                    MOVE.L    8(%FP),-(%SP)
                    BSR       clearBuffer
                    ADDQ.L    #6,%SP

                    BSR       waitNotBusy
                    BEQ       1f
                    BSR       showErrors                    | Display the error
                    BRA       3f

1:                  MOVE.B    #CMD_ID,%D4
                    MOVE.B    #REG_COMMAND,%D5
                    BSR       write8255PortA                | Issue the command

                    BSR       waitDataReqRdy                | Wait for Busy=0, DRQ=1
                    BGE       2f
                    BSR       showErrors
                    BRA       3f

2:                  MOVE.W    #IDE_SEC_SIZE,%D6
                    MOVE.L    8(%FP),%A2
                    BSR       readSector                    | Get 256 words (512 bytes) of data from REGdata port to IDE_BUFFER
                    MOVE.B    #0,%D0                        | Success, rturn 0

3:                  MOVEM.L   (%SP)+,%D1-%D6/%A2
                    UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* Set the drive's 24bit LBA to the value specified in %D0
*-----------------------------------------------------------------------------------------------------
setIdeLba:          BSR       waitNotBusy                   | make sure drive is ready
                    BGE       1f
                    BSR       showErrors                    | Returned with NZ set if error
                    RTS

1:                  MOVE.L    %D0,%D4
                    ANDI.W    #0xFF,%D4
                    MOVE.B    #REG_SEC_LOW,%D5              | Write low (of 24bits) byte
                    BSR       write8255PortA                | Write to 8255 port A

                    MOVE.L    %D0,%D4
                    LSR.L     #8,%D4
                    ANDI.W    #0xFF,%D4
                    MOVE.B    #REG_SEC_MID,%D5              | Write middle (of 24bits) byte
                    BSR       write8255PortA                | Write to 8255 port A

                    MOVE.L    %D0,%D4
                    LSR.L     #8,%D4
                    LSR.L     #8,%D4
                    ANDI.W    #0xFF,%D4
                    MOVE.B    #REG_SEC_HIGH,%D5             | Write high (of 24bits) byte
                    BSR       write8255PortAB               | Write to 8255 ports A & B (A = IDE, B - LED HEX Display)

                    RTS

*----------------------------------------------------------------------------------------------------
* Read a number of physical sectors from the currently selected drive at the current position
* %D0 the number of sectors to read
* %A2 the address of the buffer to hold the read data
* Z on success, NZ BSR error routine if problem
*----------------------------------------------------------------------------------------------------
readSectors:        BSR       waitNotBusy                   | make sure drive is ready
                    BEQ       1f
                    BSR       showErrors                    | Returned with NZ set if error
                    RTS

1:                  MOVE.B    %D0,%D4                       | Set the number of sectors to be read
                    MOVE.B    #REG_SEC_COUNT,%D5
                    BSR       write8255PortA                | Write to 8255 A Register

                    BSR       waitNotBusy                   | make sure drive is ready
                    BGE       2f
                    BSR       showErrors                    | Returned with NZ set if error
                    RTS

2:                  MOVE.B    #CMD_READ,%D4                 | Send sector read command to drive.
                    MOVE.B    #REG_COMMAND,%D5
                    BSR       write8255PortA
                    BSR       waitDataReqRdy                | wait until it's got the data
                    BGE       3f
                    BRA       showErrors                    | Drive error

3:                  MOVE.W    #IDE_SEC_SIZE,%D6             | Read 512 bytes to %D6

                    BSR       readSector                    | Read each sector into the buffer
                    SUBI.B    #1,%D0
                    BNE       3b

                    MOVE.B    #0,%D0
                    RTS

*----------------------------------------------------------------------------------------------------
* Read the number of bytes specified in %D6 to the buffer pointed to by %A2
*----------------------------------------------------------------------------------------------------
readSector:         MOVE.B    #REG_DATA,I8255_PORT_C        | REG regsiter address
                    OR.B      #LINE_READ,I8255_PORT_C       | 08H+40H, Pulse RD line

                    MOVE.B    I8255_PORT_A,(%A2)+           | Read the lower byte first 
                    MOVE.B    I8255_PORT_B,(%A2)+           | Then the upper byte next 

                    MOVE.B    #REG_DATA,I8255_PORT_C        | Deassert RD line
                    SUBQ.W    #0x2,%D6
                    BNE       readSector

                    MOVE.B    #REG_STATUS,%D5
                    BSR       read8255PortA                 | Returns status in D4
                    MOVE.B    %D4,%D1
                    AND.B     #0x1,%D1
                    BEQ       5f
                    BSR       showErrors                    | If error display status
5:                  RTS

*----------------------------------------------------------------------------------------------------
* Write one physical sector to the currently selected drive at the current position
* %D0 the number of sectors to write
* %A2 the address of the buffer holding the data to be written
* Currently will only write a single sector
*----------------------------------------------------------------------------------------------------
writeSectors:       BSR       waitNotBusy                   | make sure drive is ready
                    BGE       1f
                    BSR       showErrors
                    RTS

1:                  MOVE.B    #1,%D4                        | Set the number of sectors to be written
                    MOVE.B    #REG_SEC_COUNT,%D5
                    BSR       write8255PortA                | Write to 8255 A Register

                    BSR       waitNotBusy                   | make sure drive is ready
                    BGE       2f
                    BSR       showErrors                    | Returned with NZ set if error
                    RTS

2:                  MOVE.B    #CMD_WRITE,%D4
                    MOVE.B    #REG_COMMAND,%D5
                    BSR       write8255PortA                | tell drive to write a sector
                    BSR       waitDataReqRdy                | wait unit it wants the data
                    BGE       3f
                    BSR       showErrors
                    RTS

3:                  MOVE.W    #IDE_SEC_SIZE,%D6             | 512 bytes
                    MOVE.B    #I8255_CFG_WRITE,I8255_PORT_CTRL

writeSector:        MOVE.B    (%A2)+,I8255_PORT_A
                    MOVE.B    (%A2)+,I8255_PORT_B

                    MOVE.B    #REG_DATA,I8255_PORT_C
                    OR.B      #LINE_WRITE,I8255_PORT_C      | Send WR pulse
                    MOVE.B    #REG_DATA,I8255_PORT_C
                    SUBQ.W    #0x2,%D6
                    BNE       writeSector

                    MOVE.B    #I8255_CFG_READ,I8255_PORT_CTRL | Set 8255 back to read mode

                    MOVE.B    #REG_STATUS,%D5
                    BSR       read8255PortA
                    MOVE.B    %D4,%D1
                    AND.B     #0x1,%D1
                    BEQ       4f
                    BSR       showErrors                    | If error display status
                    RTS

4:                  MOVE.B    #0,%D0
                    RTS

*--------------------------------------------------------
*----------------------------------------------------------------------------------------------------
* READ 8 bits from IDE register @ %D5, return info in %D4
*----------------------------------------------------------------------------------------------------
read8255PortA:      MOVE.B    %D5,I8255_PORT_C              | Select IDE register, drive address onto control lines
                    OR.B      #LINE_READ,I8255_PORT_C       | RD pulse pin (40H), Assert read pin
                    MOVE.B    I8255_PORT_A,%D4              | Return with data in [D4]
                    MOVE.B    %D5,I8255_PORT_C              | Select IDE register, drive address onto control lines
                    MOVE.B    #0,I8255_PORT_C               | Zero all port C lines
                    RTS

*----------------------------------------------------------------------------------------------------
* WRITE Data in %D4 to IDE register @ %D5 - Port A
*----------------------------------------------------------------------------------------------------
write8255PortA:     MOVE.B    #I8255_CFG_WRITE,I8255_PORT_CTRL | Set 8255 to write mode
                    MOVE.B    %D4,I8255_PORT_A              | Get data put it in 8255 A port
                    MOVE.B    %D5,I8255_PORT_C              | Select IDE register, drive address onto control lines
                    OR.B      #LINE_WRITE,I8255_PORT_C      | Assert write pin
                    MOVE.B    %D5,I8255_PORT_C              | Select IDE register, drive address onto control lines
                    MOVE.B    #0,I8255_PORT_C               | Zero all port C lines
                    MOVE.B    #I8255_CFG_READ,I8255_PORT_CTRL | Config 8255 chip, read mode on return
                    RTS

*----------------------------------------------------------------------------------------------------
* WRITE Data in %D4 to IDE register @ %D5 - Port A & B
*----------------------------------------------------------------------------------------------------
write8255PortAB:    MOVE.B    #I8255_CFG_WRITE,I8255_PORT_CTRL | Set 8255 to write mode
                    MOVE.B    %D4,I8255_PORT_A              | Get data put it in 8255 A port
                    MOVE.B    %D4,I8255_PORT_B              | Get data put it in 8255 B port
                    MOVE.B    %D5,I8255_PORT_C              | Select IDE register, drive address onto control lines
                    OR.B      #LINE_WRITE,I8255_PORT_C      | Assert write pin
                    MOVE.B    %D5,I8255_PORT_C              | Select IDE register, drive address onto control lines
                    MOVE.B    #0,I8255_PORT_C               | Zero all port C lines
                    MOVE.B    #I8255_CFG_READ,I8255_PORT_CTRL | Config 8255 chip, read mode on return
                    RTS

*----------------------------------------------------------------------------------------------------
* Wait till drive is not busy, rrive READY if 0x01000000
*----------------------------------------------------------------------------------------------------
waitNotBusy:        MOVE.W    #0x0FFFF,%D6
1:                  MOVE.B    #REG_STATUS,%D5               | wait for RDY bit to be set
                    BSR       read8255PortA                 | Note AH or CH are unchanged
                    MOVE.B    %D4,%D1
                    AND.B     #STATUS_MASK_BUSY_RDY,%D1
                    EOR.B     #STATUS_BIT_READY,%D1
                    BEQ       2f
                    SUBQ.W    #1,%D6
                    BNE       1b
                    MOVE.B    #0xFF,%D0
                    LSL.B     #1,%D0                        | Set carry to indicate an error
                    RTS

2:                  CLR.B     %D1                           | Clear carry to indicate no error
                    RTS

*----------------------------------------------------------------------------------------------------
* Wait for the drive to be ready to transfer data.AND
*----------------------------------------------------------------------------------------------------
waitDataReqRdy:     MOVE.W    #0x0FFFF,%D6
1:                  MOVE.B    #REG_STATUS,%D5               | wait for DRQ bit to be set
                    BSR       read8255PortA                 | Note AH or CH are unchanged
                    MOVE.B    %D4,%D1
                    AND.B     #STATUS_MASK_BUSY_DRQ,%D1     | Ignore all but BUSY & DRQ bits
                    CMP.B     #STATUS_BIT_DRQ,%D1
                    BEQ       2f
                    SUBQ.W    #1,%D6
                    BNE       1b
                    MOVE.B    #0xFF,%D0
                    LSL.B     #1,%D0                        | Set carry to indicate an error
                    RTS
2:
                    CLR.B     %D1                           | Clear carry it indicate no error
                    RTS

*----------------------------------------------------------------------------------------------------
* Wait for the drive to be ready to transfer data.
*----------------------------------------------------------------------------------------------------
showErrors:         MOVE.L    %D1,-(%SP)                    | Save %D1
                    MOVE.B    #REG_STATUS,%D5               | Get status 
                    BSR       read8255PortA                 | Returns status in %D4
                    BTST.B    #STATUS_ERR_BIT,%D4
                    BNE       4f                            | Go to  REGerr register for more info
                                                            | All OK if 01000000

                    BTST      #STATUS_BUSY_BIT,%D4
                    BEQ       1f
                    PUTS      strDriveBusy                  | Drive Busy stuck high.
                    BRA       10f

1:                  BTST      #STATUS_READY_BIT,%D4
                    BNE       2f
                    PUTS      strDriveNotReady              | Drive Not Ready (bit 6) stuck low.
                    BRA       10f

2:                  BTST.B    #STATUS_FAULT_BIT,%D4
                    BNE       3f
                    PUTS      strWriteFault                 | Drive write fault. 
                    BRA       10f

3:                  PUTS      strUnknownStatus
                    BRA       10f

4:                  MOVE.B    #REG_ERROR,%D5                | Read the  error code from REGerr
                    BSR       read8255PortA

                    BTST.B    #ERR_NOT_FOUND_BIT,%D4
                    BEQ       5f
                    PUTS      strSectorNotFound
                    BRA       10f

5:                  BTST.B    #ERR_BAD_BLOCK_BIT,%D4        | Bad block detected
                    BEQ       6f
                    PUTS      strBadBlock
                    BRA       10f

6:                  BTST.B    #ERR_UNCORRECT_BIT,%D4        | Uncorrectable data error
                    BEQ       7f
                    PUTS      strUncorrectable
                    BRA       10f

7:                  BTST.B    #ERR_ABORT_BIT,%D4            | Command aborted
                    BEQ       8f
                    PUTS      strInvalidCmd
                    JMP       10f

8:                  BTST.B    #ERR_TRACK_NF_BIT,%D4         | Track zero not found
                    BEQ       9f
                    PUTS      strTrackZero
                    JMP       10f

9:                  PUTS      strUnknownError
                    BSR       newLine
                    BRA       11f

10:                 MOVE.B    %D4,%D0                       | Display Byte bit pattern in %D6
                    BSR       PUT_BITB                      | Show error bit pattern
                    BSR       newLine

11:                 MOVE.L    (%SP)+,%D1                    | Get origional flags
                    MOVE.W    #1,%D0                        | Set NZ flag
                    RTS

*---------------------------------------------------------------------------------------------------------
* clearBuffer(*buffer, word length)
* Clear the buffer
*---------------------------------------------------------------------------------------------------------
clearBuffer:        LINK      %FP,#0
                    MOVEM.L   %D0/%A0,-(%SP)

                    MOVE.W    0x0C(%FP),%D0
                    MOVE.L    0x08(%FP),%A0

                    BRA       2f
1:                  MOVE.B    #0,(%A0,%D0)
2:                  DBRA      %D0,1b

                    MOVEM.L   (%SP)+,%D0/%A0
                    UNLK      %FP
                    RTS

*---------------------------------------------------------------------------------------------------------
                    .section  .rodata.strings
                    .align(2)

strDriveBusy:       .asciz    "Drive Busy (bit 7) stuck high.   Status = "
strDriveNotReady:   .asciz    "Drive Ready (bit 6) stuck low.  Status = "
strWriteFault:      .asciz    "Drive write fault.    Status = "
strUnknownStatus:   .asciz    "Unknown error in status register.   Status = "
strSectorNotFound:  .asciz    "Sector not found. Error Register = "
strBadBlock:        .asciz    "Bad Sector ID.    Error Register = "
strUncorrectable:   .asciz    "Uncorrectable data error.  Error Register = "
strInvalidCmd:      .asciz    "Invalid Command. Error Register = "
strTrackZero:       .asciz    "Track Zero not found. Error Register = "
strUnknownError:    .asciz    "Unknown Error. Error Register = "
