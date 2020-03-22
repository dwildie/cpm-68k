                    .include  "include/macros.i"
                    .include  "include/disk.i"

*-----------------------------------------------------------------------------------------------------
                    .bss
                    .global   currentDrive

driveStatus:        .ds.b     2
currentDrive:       .ds.w     1

*-----------------------------------------------------------------------------------------------------

                    .text
                    .global   initialiseDiskSys
                    .global   initDrives
                    .global   initDrive
                    .global   getDriveStatus
                    .global   selectDriveA
                    .global   selectDriveB,
                    .global   showDriveModel
                    .global   showDriveIdent
                    .global   writeDrive

*-----------------------------------------------------------------------------------------------------
* Initialise  the disk system
*-----------------------------------------------------------------------------------------------------
initialiseDiskSys:  MOVE.W    #DISK_A,currentDrive

                    BSR       initLBA

                    LEA       driveStatus,%A0
                    MOVE.B    #DISK_UNAVAILABLE,DISK_A(%A0)
                    MOVE.B    #DISK_UNAVAILABLE,DISK_B(%A0)

                    RTS

*-----------------------------------------------------------------------------------------------------
* Initialise and list the available drives
*-----------------------------------------------------------------------------------------------------
initDrives:         MOVE.W    #DISK_A,%D0                             | Initialise and display drive A 
                    BSR       selectDrive
                    BSR       initDrive
                    BEQ       1f

                    BSR       showCurrentDrive                        | Drive A failed to initialise
                    PUTS      strNotInitialised
                    BRA       3f                                      | Try drive B

1:                  BSR       showDriveModel                          | Drive A ok, show model number

                    MOVE.W    #1,-(%SP)                               | Don't display errors
                    MOVE.W    #DISK_A,-(%SP)                          | Read the partition table, if present, from the master boot record
                    BSR       readMBR
                    ADD       #4,%SP
                    TST.W     %D0
                    BEQ       2f                                      | Valid

                    PUTS      strInvalidMBR                           | Not present or invalid, show error
                    BRA       3f

2:                  MOVE.W    #DISK_A,-(%SP)                          | Display the partition table
                    BSR       showPartitions
                    ADD       #2,%SP

3:                  MOVE.W    #DISK_B,%D0                             | Initialise and display drive B 
                    BSR       selectDrive
                    BSR       initDrive
                    BEQ       4f

                    BSR       showCurrentDrive                        | Drive B failed to initialise
                    PUTS      strNotInitialised
                    BRA       6f                                      | Finished

4:                  BSR       showDriveModel                          | Drive B ok, show model number

                    MOVE.W    #1,-(%SP)                               | Don't display errors
                    MOVE.W    #DISK_B,-(%SP)                          | Read the partition table, if present, from the master boot record
                    BSR       readMBR
                    ADD       #4,%SP
                    TST.W     %D0
                    BEQ       5f                                      | Valid

                    PUTS      strInvalidMBR                           | Not present or invalid, show error
                    BRA       6f

5:                  MOVE.W    #DISK_B,-(%SP)                          | Display the partition table
                    BSR       showPartitions
                    ADD       #2,%SP

6:                  RTS

*-----------------------------------------------------------------------------------------------------
* Initialise the current drive
*-----------------------------------------------------------------------------------------------------
initDrive:          BSR       initIdeDrive
                    BEQ       1f

                    MOVE.B    #DISK_UNAVAILABLE,%D0                   | Mark drive not present
                    BSR       setDriveStatus
                    MOVE.B    #1,%D0                                  | Return 1 = error
                    BRA       2f

1:                  MOVE.B    #DISK_AVAILABLE,%D0                     | Mark drive present
                    BSR       setDriveStatus

                    MOVE.B    #0,%D0                                  | Return 0 = success
2:                  RTS

*-----------------------------------------------------------------------------------------------------
* Set the current drive's status to %D0.B
*-----------------------------------------------------------------------------------------------------
setDriveStatus:     LEA       driveStatus,%A0
                    MOVE.W    currentDrive,%D1
                    MOVE.B    %D0,(%A0,%D1.W)
                    RTS

*-----------------------------------------------------------------------------------------------------
* Get the current drive's status in %D0.B
*-----------------------------------------------------------------------------------------------------
getDriveStatus:     LEA       driveStatus,%A0
                    MOVE.W    currentDrive,%D1
                    MOVE.B    (%A0,%D1.W),%D0
                    RTS

*-----------------------------------------------------------------------------------------------------
* Select drive A
*-----------------------------------------------------------------------------------------------------
selectDriveA:       MOVE.W    #DISK_A,%D0
                    BSR       selectDrive
                    RTS

*-----------------------------------------------------------------------------------------------------
* Select drive B
*-----------------------------------------------------------------------------------------------------
selectDriveB:       MOVE.W    #DISK_B,%D0
                    BSR       selectDrive
                    RTS

*-----------------------------------------------------------------------------------------------------
* Select a drive specified in %D0.W
*-----------------------------------------------------------------------------------------------------
selectDrive:        MOVE.W    %D0,currentDrive
                    BSR       setIdeDrive                             | Select Drive 0 or 1
                    RTS

*-----------------------------------------------------------------------------------------------------
* Display the model data from the curent drive's identification data
*-----------------------------------------------------------------------------------------------------
showDriveModel:     BSR       showCurrentDrive

                    PEA       __free_ram_start__
                    BSR       getDriveIdent
                    ADDQ.L    #4,%SP

                    BEQ       1f                                      | No error, show model
                    PUTS      strIdentError                           | Error display error string
                    MOVE.W    #1,%D0
                    BRA       2f

1:                  LEA       __free_ram_start__,%A2
                    LEA       ID_MODEL_OFFSET(%A2),%A0
                    MOVE.B    #20,%D3                                 | Character count in words
                    BSR       writeIdStr                              | Print [A2], [D3] X 2 characters
                    BSR       newLine

                    MOVE.W    #0,%D0
2:                  RTS


*-----------------------------------------------------------------------------------------------------
* Display the current drive letter
*-----------------------------------------------------------------------------------------------------
showCurrentDrive:   BSR       writeDrive                              | Display the drive letter
                    PUTCH     #':'
                    PUTCH     #' '
                    RTS

*-----------------------------------------------------------------------------------------------------
* Display the identification data for the curent drive
*-----------------------------------------------------------------------------------------------------
showDriveIdent:     PEA       __free_ram_start__
                    BSR       getDriveIdent
                    ADDQ.L    #4,%SP
                    BNE       1f                                      | Error

                    PUTS      strDriveIdentPre                        | Display the header with drive id
                    BSR       writeDrive
                    PUTS      strDriveIdentSuf

                    LEA       __free_ram_start__,%A2

                    PUTS      strDriveModel                           | Model details
                    LEA       ID_MODEL_OFFSET(%A2),%A0
                    MOVE.B    #20,%D3                                 | Character count in words
                    BSR       writeIdStr                              | Print [A2], [D3] X 2 characters

                    PUTS      strDriveSerial                          | Serial number
                    LEA       ID_SERIAL_OFFSET(%A2),%A0
                    MOVE.B    #10,%D3                                 | Character count in words
                    BSR       writeIdStr                              | Print [A2], [D3] X 2 characters

                    PUTS      strDriveFirmw                           | Firmware revision
                    LEA       ID_FIRMW_OFFSET(%A2),%A0
                    MOVE.B    #4,%D3                                  | Character count in words
                    BSR       writeIdStr                              | Print [A2], [D3] X 2 characters

1:                  BSR       newLine
                    RTS

*-----------------------------------------------------------------------------------------------------
* Write the letter for the current drive
*-----------------------------------------------------------------------------------------------------
writeDrive:         MOVE.B    #'A',%D0
                    ADD.W     currentDrive,%D0
                    BSR       writeCh
                    RTS

*-----------------------------------------------------------------------------------------------------
* Output drive identification string
*-----------------------------------------------------------------------------------------------------
writeIdStr:         MOVE.B    (%A0,1),%D0                             | Text is stored high byte then low byte
                    BSR       writeCh
                    MOVE.B    (%A0),%D0
                    BSR       writeCh
                    ADDQ.L    #2,%A0
                    SUBQ.B    #1,%D3
                    BNE       writeIdStr
                    RTS

*---------------------------------------------------------------------------------------------------------
                    .section  .rodata.strings
                    .align(2)
strDiskError:       .asciz    "Error\r\n"
strDriveIdentPre:   .asciz    "\r\nDrive "
strDriveIdentSuf:   .asciz    " Identity information"
strDriveModel:      .asciz    "\r\nModel     : "
strDriveSerial:     .asciz    "\r\nSerial No : "
strDriveFirmw:      .asciz    "\r\nFirmware  : "
strNotInitialised:  .asciz    "Failed to initialise\r\n"
strIdentError:      .asciz    "Failed to read drive identifier\r\n"

