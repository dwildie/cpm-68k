                    .include  "include/macros.i"
                    .include  "include/mbr.i"

                    .text
                    .global   listDirectory

*-----------------------------------------------------------------------------------------------------
*
*-----------------------------------------------------------------------------------------------------
listDirectory:      LINK      %FP,#-4

                    MOVE.W    currentDrive,%D1                        | Get current drive
                    MOVE.W    %D1,-2(%FP)                             | Local driveId variable

                    MOVE.W    %D1,-(%SP)
                    BSR       hasValidTable                           | Does this drive have a MBR partition table 
                    ADD       #2,%SP
                    TST.W     %D0
                    BNE       NO_PARTITION

                    MOVE.W    -2(%FP),-(%SP)                          | driveId
                    BSR       getPartitionId                          | Get the drive's current partition
                    ADD       #2,%SP

                    MOVE.W    %D0,-4(%FP)                             | Local partitionId variable

                    MOVE.W    %D0,-(%SP)                              | partitionId
                    MOVE.W    -2(%FP),-(%SP)                          | driveID
                    BSR       getPartitionType                        | Get the partition type
                    ADD       #4,%SP

                    CMPI.B    #PID_FAT12,%D0                          | Check for FAT partition types
                    BEQ       FAT_PARTITION
                    CMPI.B    #PID_FAT16,%D0
                    BEQ       FAT_PARTITION
                    CMPI.B    #PID_FAT16B,%D0
                    BEQ       FAT_PARTITION
                    CMPI.B    #PID_FAT32,%D0
                    BEQ       FAT_PARTITION

                    CMPI      #PID_CPM80,%D0                          | Check for CP/M partition types
                    BEQ       CPM_PARTITION
                    CMPI      #PID_CPM86,%D0
                    BEQ       CPM_PARTITION
                    CMPI      #PID_CDOS,%D0
                    BEQ       CPM_PARTITION

                    PUTS      strUnsupportedType                      | Unsupported partition
                    BRA       return

FAT_PARTITION:      MOVE.W    -4(%FP),%D0                             | partitionId
                    EXT.L     %D0
                    MOVE.L    %D0,-(%SP)
                    MOVE.W    -2(%FP),%D0                             | driveId
                    EXT.L     %D0
                    MOVE.L    %D0,-(%SP)
                    BSR       mediaInit                               | Initialise the FAT32 library
                    ADD.L     #8,%SP

                    PEA       strRootDir                              | List the root directory
                    BSR       listFatDirectory
                    ADD.L     #4,%SP

                    BSR       mediaClose                              | Close the FAT32 library

                    BRA       return

CPM_PARTITION:      MOVE.W    -4(%FP),%D0                             | partitionId
                    EXT.L     %D0
                    MOVE.L    %D0,-(%SP)
                    MOVE.W    -2(%FP),%D0                             | driveId
                    EXT.L     %D0
                    MOVE.L    %D0,-(%SP)
                    BSR       getPartitionStart                       | Get the offset (in sectors) to the start of the partition
                    ADD       #8,%SP

                    MOVE.L    %D0,-(%SP)
                    BSR       listCpmDirectory
                    ADD       #4,%SP
                    BRA       return

NO_PARTITION:       MOVE.L    #0,-(%SP)                               | Assume it is a CP/M Filesytem starting at sector 0
                    BSR       listCpmDirectory
                    ADD       #4,%SP
                    BRA       return

return:             UNLK      %FP
                    RTS

*---------------------------------------------------------------------------------------------------------
                    .section  .rodata.strings

                    .align(2)
strRootDir:         .asciz    "/"
strUnsupportedType: .asciz    "\r\nUnsupporte partition type\rn\n"

