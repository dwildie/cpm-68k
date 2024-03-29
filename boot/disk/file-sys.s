                    .include  "include/macros.i"
                    .include  "include/mbr.i"
                    .include  "include/file-sys.i"

*-----------------------------------------------------------------------------------------------------
                    .bss
F_DRIVE_ID:         ds.w      1
F_PARTITION_ID:     ds.w      1
F_FILESYS_TYPE:     ds.w      1
F_PARTITION_OFFSET: ds.l      1

*-----------------------------------------------------------------------------------------------------
                    .text
                    .global   fatInit
                    .global   fatExit
                    .global   listDirectory
                    .global   fOpen
                    .global   fRead
                    .global   fClose
                    .global   getFileSysType

*-----------------------------------------------------------------------------------------------------
* fatInit
*-----------------------------------------------------------------------------------------------------
          .ifdef              IS_68030
fatInit:            LINK      %FP,#0
                    MOVE.W    currentDrive,%D0                        | Get current drive
                    MOVE.W    %D0,F_DRIVE_ID                          | Local driveId variable

                    MOVE.W    %D0,-(%SP)                              | Get the filesystem type
                    BSR       getFileSysType
                    ADD.L     #2,%SP

                    MOVE.W    %D0,F_FILESYS_TYPE

                    CMPI.W    #FS_FAT_P,%D0                           | FAT
                    BEQ       1f

                    PUTS      strUnsupportedType                      | Unsupported partition
                    MOVE.B    #1,%D0                                  | Return Error
                    BRA       2f

                    /* FAT Partition */
1:                  MOVE.W    currentDrive,-(%SP)                     | driveId
                    BSR       getPartitionId                          | Get the drive's current partition
                    ADD       #2,%SP
                    MOVE.W    %D0,F_PARTITION_ID

                    EXT.L     %D0
                    MOVE.L    %D0,-(%SP)                              | Param - partitionId
                    MOVE.W    currentDrive,%D0
                    EXT.L     %D0
                    MOVE.L    %D0,-(%SP)                              | Param driveId
                    BSR       mediaInit                               | Initialise the FAT32 library
                    ADD.L     #8,%SP
                    MOVE.B    #0,%D0                                  | Return OK

2:                  UNLK      %FP
                    RTS
          .endif

*-----------------------------------------------------------------------------------------------------
* fatExit
*-----------------------------------------------------------------------------------------------------
          .ifdef              IS_68030
fatExit:            MOVE.W    F_FILESYS_TYPE,%D0

                    CMPI.W    #FS_FAT_P,%D0                           | FAT
                    BNE       1f

                    /* FAT Partition */
                    BSR       mediaClose                              | Close the FAT driver

1:                  RTS
          .endif

*-----------------------------------------------------------------------------------------------------
* fOpen(*fileName)
* Open fileName
* Return: 0 success
*         1 file not found
*-----------------------------------------------------------------------------------------------------
fOpen:              LINK      %FP,#0
                    MOVE.W    currentDrive,%D0                        | Get current drive
                    MOVE.W    %D0,F_DRIVE_ID                          | Local driveId variable

                    MOVE.W    %D0,-(%SP)                              | Get the filesystem type
                    BSR       getFileSysType
                    ADD.L     #2,%SP

                    MOVE.W    %D0,F_FILESYS_TYPE

          .ifdef              IS_68030
                    CMPI.W    #FS_FAT_P,%D0                           | FAT
                    BEQ       1f
          .endif

                    CMPI.W    #FS_CPM_P,%D0                           | CP/M
                    BEQ       2f

                    CMPI.W    #FS_NONE,%D0                            | None
                    BEQ       3f

                    PUTS      strUnsupportedType                      | Unsupported partition
                    BRA       4f

          .ifdef              IS_68030
                    /* FAT Partition */
1:                  MOVE.W    currentDrive,-(%SP)                     | driveId
                    BSR       getPartitionId                          | Get the drive's current partition
                    ADD       #2,%SP
                    MOVE.W    %D0,F_PARTITION_ID

                    EXT.L     %D0
                    MOVE.L    %D0,-(%SP)                              | Param - partitionId
                    MOVE.W    currentDrive,%D0
                    EXT.L     %D0
                    MOVE.L    %D0,-(%SP)                              | Param driveId
                    BSR       mediaInit                               | Initialise the FAT32 library
                    ADD.L     #8,%SP

                    PEA       strRead                                 | Read mode
                    MOVE.L    0x08(%FP),-(%SP)                        | Param: fileName
                    BSR       fOpenFAT                                | Open the file
                    ADD.L     #4,%SP
                    BNE       5f
                    MOVE.L    #1,%D0
                    BRA       4f
5:                  MOVE.L    #0,%D0
                    BRA       4f
          .endif

                    /* CP/M Partition */
2:                  MOVE.W    currentDrive,-(%SP)                     | driveId
                    BSR       getPartitionId                          | Get the drive's current partition
                    ADD       #2,%SP
                    MOVE.W    %D0,F_PARTITION_ID

                    EXT.L     %D0
                    MOVE.L    %D0,-(%SP)
                    MOVE.W    currentDrive,%D0                        | driveId
                    EXT.L     %D0
                    MOVE.L    %D0,-(%SP)
                    BSR       getPartitionStart                       | Get the offset (in sectors) to the start of the partition
                    ADD       #8,%SP
                    MOVE.L    %D0,F_PARTITION_OFFSET

                    MOVE.L    0x08(%FP),-(%SP)                        | Param: fileName
                    MOVE.L    F_PARTITION_OFFSET,-(%SP)               | Param: partitionOffset
                    BSR       fOpenCPM
                    ADD       #0x8,%SP
                    BRA       4f

                    /* NO Partition */
3:                  MOVE.W    #-1,F_PARTITION_ID                      | No partition
                    MOVE.L    #0,F_PARTITION_OFFSET                   | No offset

                    MOVE.L    0x08(%FP),-(%SP)                        | Param: fileName
                    MOVE.L    #0,-(%SP)                               | Param: partitionOffset
                    BSR       fOpenCPM
                    ADD       #0x8,%SP

4:                  UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* fread(word count, *buffer)
* Read count bytes into buffer, return the number of bytes read in %D0
*-----------------------------------------------------------------------------------------------------
fRead:              LINK      %FP,#0
                    MOVEM.L   %D1-%D3/%A0-%A2,-(%SP)

                    MOVE.W    F_FILESYS_TYPE,%D0

          .ifdef              IS_68030
                    CMPI.W    #FS_FAT_P,%D0                           | FAT
                    BEQ       1f
          .endif

                    CMPI.W    #FS_CPM_P,%D0                           | CP/M
                    BEQ       2f

                    CMPI.W    #FS_NONE,%D0                            | None
                    BEQ       2f

                    PUTS      strUnsupportedType                      | Unsupported partition
                    BRA       4f

                    /* FAT Partition */
          .ifdef              IS_68030
1:                  MOVE.L    0x0A(%FP),-(%SP)                        | Param - buffer address
                    MOVE.W    0x08(%FP),%D0
                    EXT.L     %D0
                    MOVE.L    %D0,-(%SP)                              | Param - byte count
                    BSR       fReadFAT
                    ADD       #0x08,%SP
                    BRA       4f
          .endif

                    /* CP/M Partition or raw CP/M file system */
2:                  MOVE.L    0x0A(%FP),-(%SP)                        | Param - buffer address
                    MOVE.W    0x08(%FP),-(%SP)                        | Param - byte count
                    BSR       fReadCPM
                    ADD       #0x06,%SP

4:                  MOVEM.L   (%SP)+,%D1-%D3/%A0-%A2
                    UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
*
*-----------------------------------------------------------------------------------------------------
fClose:             MOVE.W    F_FILESYS_TYPE,%D0

          .ifdef              IS_68030
                    CMPI.W    #FS_FAT_P,%D0                           | FAT
                    BEQ       1f
          .endif

                    CMPI.W    #FS_CPM_P,%D0                           | CP/M
                    BEQ       2f

                    CMPI.W    #FS_NONE,%D0                            | None
                    BEQ       2f

                    PUTS      strUnsupportedType                      | Unsupported partition
                    BRA       3f

                    /* FAT Partition */
          .ifdef              IS_68030
1:                  BSR       fCloseFAT                               | Close the file
*                    BSR       mediaClose                              | Close the FAT driver
                    BRA       3f
          .endif

                    /* CP/M Partition or raw CP/M file system */
2:                  BSR       fCloseCPM

3:                  RTS

*-----------------------------------------------------------------------------------------------------
* List the directory for the current drive/partition
*-----------------------------------------------------------------------------------------------------
listDirectory:      LINK      %FP,#-2                                 | local variable - word driveId

                    MOVE.W    currentDrive,%D1                        | Get current drive
                    MOVE.W    %D1,-2(%FP)                             | Local driveId variable

                    MOVE.W    %D1,-(%SP)
                    BSR       getFileSysType
                    ADD.L     #2,%SP

          .ifdef              IS_68030
                    CMPI.W    #FS_FAT_P,%D0
                    BEQ       1f
          .endif

                    CMPI.W    #FS_CPM_P,%D0
                    BEQ       2f

                    CMPI.W    #FS_CROMIX_P,%D0
                    BEQ       5f

                    CMPI.W    #FS_CROMIX_D,%D0
                    BEQ       6f

                    CMPI.W    #FS_NONE,%D0
                    BEQ       3f

                    PUTS      strUnsupportedType                      | Unsupported partition
                    BRA       4f

          .ifdef              IS_68030
                    /* FAT Partition */
1:                  MOVE.W    -2(%FP),-(%SP)                          | driveId
                    BSR       getPartitionId                          | Get the drive's current partition
                    ADD       #2,%SP
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
                    BRA       4f
          .endif

                    /* CP/M Partition */
2:                  MOVE.W    -2(%FP),-(%SP)                          | driveId
                    BSR       getPartitionId                          | Get the drive's current partition
                    ADD       #2,%SP
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
                    BRA       4f

6:
                    /* Cromix Disk */
                    MOVE.L    #0,%D0
                    JMP       7f

                    /* Cromix Partition */
5:                  MOVE.W    -2(%FP),-(%SP)                          | driveId
                    BSR       getPartitionId                          | Get the drive's current partition
                    ADD       #2,%SP
                    EXT.L     %D0
                    MOVE.L    %D0,-(%SP)
                    MOVE.W    -2(%FP),%D0                             | driveId
                    EXT.L     %D0
                    MOVE.L    %D0,-(%SP)
                    BSR       getPartitionStart                       | Get the offset (in sectors) to the start of the partition
                    ADD       #8,%SP

7:                  MOVE.L    %D0,-(%SP)                              | partitionStart
                    MOVE.W    -2(%FP),%D0                             | driveId
                    EXT.L     %D0
                    MOVE.L    %D0,-(%SP)
                    BSR       listCromixDirectory
                    ADD       #8,%SP
                    BRA       4f

                    /* No partition */
3:                  MOVE.L    #0,-(%SP)                               | Assume it is a CP/M Filesytem starting at sector 0
                    BSR       listCpmDirectory
                    ADD       #4,%SP

4:                  UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* getFileSysType(word driveId), returns %D0 = 0 none, 1 cpm, 2 fat, 3 other
*-----------------------------------------------------------------------------------------------------
getFileSysType:     LINK      %FP,#-2

                    MOVE.W    0x08(%FP),%D1                           | Get  driveId
                    MOVE.W    %D1,-2(%FP)                             | Local driveId variable

                    MOVE.W    %D1,-(%SP)
                    BSR       hasValidTable                           | Does this drive have a MBR partition table 
                    ADD       #2,%SP
                    TST.W     %D0
                    BNE       1f                                      | No

                    MOVE.W    -2(%FP),-(%SP)                          | driveId
                    BSR       getPartitionId                          | Get the drive's current partition
                    ADD       #2,%SP

                    MOVE.W    %D0,-(%SP)                              | partitionId
                    MOVE.W    -2(%FP),-(%SP)                          | driveID
                    BSR       getPartitionType                        | Get the partition type
                    ADD       #4,%SP

                    CMPI.B    #PID_FAT12,%D0                          | Check for FAT partition types
                    BEQ       2f
                    CMPI.B    #PID_FAT16,%D0
                    BEQ       2f
                    CMPI.B    #PID_FAT16B,%D0
                    BEQ       2f
                    CMPI.B    #PID_FAT32,%D0
                    BEQ       2f

                    CMPI      #PID_CPM80,%D0                          | Check for CP/M partition types
                    BEQ       3f
                    CMPI      #PID_CPM86,%D0
                    BEQ       3f
                    CMPI      #PID_CDOS,%D0
                    BEQ       3f

                    CMPI      #PID_CROMIX,%D0                         | Check for Cromix partition type
                    BEQ       5f

                    MOVE.W    #FS_OTHER,%D0
                    BRA       4f

                    /* Read the first disk sector and check for the cromix signature */
1:                  LEA       __free_ram_start__,%A0
                    MOVE.L    %A0,-(%SP)                              | Param - destination buffer address
                    MOVE.W    #1,-(%SP)                               | Param - count
                    MOVE.W    -2(%FP),-(%SP)                          | Param - drive
                    MOVE.L    #0,-(%SP)                               | Param - LBA
                    BSR       readDiskSector
                    ADD       #0x0c,%SP
                    CMPI.B    #'C',0x78(%A0)                          | CSTD at offset 0x78
                    BNE       1f
                    CMPI.B    #'S',0x79(%A0)
                    BNE       1f
                    CMPI.B    #'T',0x7A(%A0)
                    BNE       1f
                    CMPI.B    #'D',0x7B(%A0)
                    BNE       1f
                    MOVE.W    #FS_CROMIX_D,%D0
                    BRA       4f

1:                  MOVE.W    #FS_NONE,%D0
                    BRA       4f

2:                  MOVE.W    #FS_FAT_P,%D0
                    BRA       4f

3:                  MOVE.W    #FS_CPM_P,%D0
                    BRA       4f

5:                  MOVE.W    #FS_CROMIX_P,%D0

4:                  UNLK      %FP
                    RTS

*---------------------------------------------------------------------------------------------------------
                    .section  .rodata.strings
                    .global   strUnsupportedType

                    .align(2)
strRootDir:         .asciz    "/"
strRead:            .asciz    "r"
strUnsupportedType: .asciz    "\r\nUnsupported partition type\r\n"

