                    .include  "include/macros.i"
                    .include  "include/disk.i"

                    .text
                    .global   initialiseDiskSys
                    .global   listDrives
                    .global   selectDriveA
                    .global   selectDriveB,
                    .global   showDriveModel
                    .global   showDriveIdent
                    .global   writeDrive


*-----------------------------------------------------------------------------------------------------
* Initialise  the disk system
*-----------------------------------------------------------------------------------------------------
initialiseDiskSys:  BSR       initLBA
                    RTS

*-----------------------------------------------------------------------------------------------------
* Initialise and list the available drives
*-----------------------------------------------------------------------------------------------------
listDrives:         MOVE.B    #DISK_A,%D0                   | Initialise and display drive A 
                    BSR       selectDrive
                    BSR       initIdeDrive
                    BEQ       1f

                    BSR       showCurrentDrive              | Drive A failed to initialise
                    PUTS      strNotInitialised
                    BRA       2f                            | Try drive B

1:                  BSR       showDriveModel                | Drive A ok, show model number

2:                  MOVE.B    #DISK_B,%D0                   | Initialise and display drive B 
                    BSR       selectDrive
                    BSR       initIdeDrive
                    BEQ       3f

                    BSR       showCurrentDrive              | Drive B failed to initialise
                    PUTS      strNotInitialised
                    BRA       4f                            | Finished

3:                  BSR       showDriveModel                | Drive B ok, show model number
4:                  RTS

*-----------------------------------------------------------------------------------------------------
* Select drive A
*-----------------------------------------------------------------------------------------------------
selectDriveA:       MOVE.B    #DISK_A,%D0
                    BSR       selectDrive
                    RTS

*-----------------------------------------------------------------------------------------------------
* Select drive B
*-----------------------------------------------------------------------------------------------------
selectDriveB:       MOVE.B    #DISK_B,%D0
                    BSR       selectDrive
                    RTS

*-----------------------------------------------------------------------------------------------------
* Display the model data from the curent drive's identification data
*-----------------------------------------------------------------------------------------------------
showDriveModel:     BSR       showCurrentDrive

                    PEA       __free_ram_start__
                    BSR       getDriveIdent
                    ADDQ.L    #4,%SP

                    BEQ       1f                            | No error, show model
                    PUTS      strIdentError                 | Error display error string
                    BRA       2f

1:                  LEA       __free_ram_start__,%A2
                    LEA       ID_MODEL_OFFSET(%A2),%A0
                    MOVE.B    #20,%D3                       | Character count in words
                    BSR       writeIdStr                    | Print [A2], [D3] X 2 characters
                    BSR       newLine
2:                  RTS


*-----------------------------------------------------------------------------------------------------
* Display the current drive letter
*-----------------------------------------------------------------------------------------------------
showCurrentDrive:   BSR       writeDrive  | Display the drive letter
                    PUTCH     #':'
                    PUTCH     #' '
                    RTS

*-----------------------------------------------------------------------------------------------------
* Display the identification data for the curent drive
*-----------------------------------------------------------------------------------------------------
showDriveIdent:     PEA       __free_ram_start__
                    BSR       getDriveIdent
                    ADDQ.L    #4,%SP
                    BNE       1f                            | Error

                    PUTS      strDriveIdentPre              | Display the header with drive id
                    BSR       writeDrive
                    PUTS      strDriveIdentSuf

                    LEA       __free_ram_start__,%A2

                    PUTS      strDriveModel                 | Model details
                    LEA       ID_MODEL_OFFSET(%A2),%A0
                    MOVE.B    #20,%D3                       | Character count in words
                    BSR       writeIdStr                    | Print [A2], [D3] X 2 characters

                    PUTS      strDriveSerial                | Serial number
                    LEA       ID_SERIAL_OFFSET(%A2),%A0
                    MOVE.B    #10,%D3                       | Character count in words
                    BSR       writeIdStr                    | Print [A2], [D3] X 2 characters

                    PUTS      strDriveFirmw                 | Firmware revision
                    LEA       ID_FIRMW_OFFSET(%A2),%A0
                    MOVE.B    #4,%D3                        | Character count in words
                    BSR       writeIdStr                    | Print [A2], [D3] X 2 characters

1:                  BSR       newLine
                    RTS

*-----------------------------------------------------------------------------------------------------
* Write the letter for the current drive
*-----------------------------------------------------------------------------------------------------
writeDrive:         MOVE.B    #'A',%D0
                    ADD.B     currentDrive,%D0
                    BSR       writeCh
                    RTS

*-----------------------------------------------------------------------------------------------------
* Select a drive specified in %D0.B
*-----------------------------------------------------------------------------------------------------
selectDrive:        MOVE.B    %D0,currentDrive
                    BSR       setIdeDrive                   | Select Drive 0 or 1
                    RTS

*-----------------------------------------------------------------------------------------------------
* Output drive identification string
*-----------------------------------------------------------------------------------------------------
writeIdStr:         MOVE.B    (%A0,1),%D0                   | Text is stored high byte then low byte
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

*-----------------------------------------------------------------------------------------------------
                    .data
                    .global   currentDrive

currentDrive:       .byte     0x0

