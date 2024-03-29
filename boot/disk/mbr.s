                    .include  "include/macros.i"
                    .include  "include/mbr.i"
                    .include  "include/disk.i"
                    .include  "include/ide.i"

                    .text

                    .global   readMBR
                    .global   showPartitions
                    .global   getPartitionStart
                    .global   hasValidTable
                    .global   setPartitionId
                    .global   getPartitionId
                    .global   getPartitionType
                    .global   getDiskSize

*---------------------------------------------------------------------------------------------------------
* hasValidTable(word driveId)
*---------------------------------------------------------------------------------------------------------
hasValidTable:      LINK      %FP,#0
                    MOVE.L    %A0,-(%SP)

                    MOVE.W    0x08(%FP),%D0                           | Current drive
                    EXT.L     %D0
                    MULU.W    #PT_SIZE,%D0
                    LEA       PART_TABLE_A,%A0
                    ADD.L     %D0,%A0                                 | Base of drive table

                    TST.W     PT_VALID(%A0)
                    BEQ       1f

                    MOVE.W    #0,%D0                                  | PT_VALID is non zero, return 0 = success
                    BRA       2f

1:                  MOVE.W    #1,%D0                                  | PT_VALID is zero, return 1 = error				

2:                  MOVE.L    (%SP)+,%A0
                    UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* setPartitionId(word driveId, word partitionId)
*-----------------------------------------------------------------------------------------------------
setPartitionId:     LINK      %FP,#0
                    MOVE.L    %A0,-(%SP)

                    MOVE.W    0x08(%FP),%D0                           | driveId
                    EXT.L     %D0
                    MULU.W    #PT_SIZE,%D0
                    LEA       PART_TABLE_A,%A0                        | Base of drive table
                    ADD.L     %D0,%A0                                 | Base of drive entry

                    MOVE.W    0x0A(%FP),PT_CURRENT(%A0)               | Set the current partition

                    MOVE.L    (%SP)+,%A0
                    UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* getPartitionId(word driveId)
*-----------------------------------------------------------------------------------------------------
getPartitionId:     LINK      %FP,#0
                    MOVE.L    %A0,-(%SP)

                    MOVE.W    0x08(%FP),%D0                           | driveId
                    EXT.L     %D0
                    MULU.W    #PT_SIZE,%D0
                    LEA       PART_TABLE_A,%A0                        | Base of drive table
                    ADD.L     %D0,%A0                                 | Base of drive entry

                    MOVE.W    PT_CURRENT(%A0),%D0                     | Return the current partition

                    MOVE.L    (%SP)+,%A0
                    UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* getPartitionType(word driveId, word partitionId)
*-----------------------------------------------------------------------------------------------------
getPartitionType:   LINK      %FP,#0
                    MOVE.L    %A0,-(%SP)

                    MOVE.W    0x08(%FP),%D0                           | driveId
                    EXT.L     %D0
                    MULU.W    #PT_SIZE,%D0
                    LEA       PART_TABLE_A,%A0
                    ADD.L     %D0,%A0                                 | Base of drive table
                    ADD.L     #PT_ENTRIES,%A0                         | Base of drive partition entries table

                    MOVE.W    0x0A(%FP),%D0                           | partitionId
                    EXT.L     %D0
                    MULU.W    #PE_SIZE,%D0
                    ADD.L     %D0,%A0

                    MOVE.B    PE_TYPE(%A0),%D0                        | Return the partition type

                    MOVE.L    (%SP)+,%A0
                    UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* getPartitionStart(long driveId, long partitionId)
*-----------------------------------------------------------------------------------------------------
getPartitionStart:  LINK      %FP,#0
                    MOVE.L    %A0,-(%SP)

                    MOVE.L    0x08(%FP),%D0                           | driveId
                    MULU.W    #PT_SIZE,%D0
                    LEA       PART_TABLE_A,%A0
                    ADD.L     %D0,%A0                                 | Base of drive table
                    ADD.L     #PT_ENTRIES,%A0                         | Base of drive partition entries table

                    MOVE.L    0x0C(%FP),%D0                           | partitionId
                    MULU.W    #PE_SIZE,%D0
                    ADD.L     %D0,%A0

                    MOVE.L    PE_START(%A0),%D0                       | Return the starting sector

                    MOVE.L    (%SP)+,%A0
                    UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* getDiskSize(word driveId)
*-----------------------------------------------------------------------------------------------------
getDiskSize:        LINK      %FP,#0
                    MOVEM.L   %D1-%D6/%A2-%A4,-(%SP)

                    CLR.L     %D6
                    MOVE.W    0x08(%FP),%D6                           | Current drive
                    MULU.W    #PT_SIZE,%D6
                    LEA       PART_TABLE_A,%A3
                    ADD.L     %D6,%A3                                 | Base of drive partition entry

                    MOVE.L    PT_SECTORS(%A3),%D0

8:                  MOVEM.L   (%SP)+,%D1-%D6/%A2-%A4
                    UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* showPartitions(word driveId, word quiet)
* Read the MBR parttion table from the drive, validate and copy.
*-----------------------------------------------------------------------------------------------------
readMBR:            LINK      %FP,#0
                    MOVEM.L   %D1-%D6/%A2-%A4,-(%SP)

                    CLR.L     %D6
                    MOVE.W    0x08(%FP),%D6                           | Current drive
                    MULU.W    #PT_SIZE,%D6
                    LEA       PART_TABLE_A,%A3
                    ADD.L     %D6,%A3                                 | Base of drive partition entry

                    MOVE.W    #PT_SIZE,-(%SP)                         | Clear the table for this drive
                    MOVE.L    %A3,-(%SP)
                    BSR       memClr
                    ADD.L     #6,%SP

                    PEA       __free_ram_start__                      | Read the drive's ident information
                    BSR       getDriveIdent
                    ADD.L     #4,%SP
                    BNE       7f

                    LEA       __free_ram_start__,%A2
                    MOVE.L    ID_SEC_COUNT(%A2),%D1                   | Number of sectors, ie max LBA
                    TO_BIG_END %D1                                    | Convert to big endian
                    MOVE.L    %D1,PT_SECTORS(%A3)                     | Store in Partition table

                    MOVE.L    #0,%D0                                  | Read the first sector where the MBR should be
                    BSR       setIdeLba
                    MOVE.L    #1,%D0
                    LEA       __free_ram_start__,%A2
                    BSR       readSectors
                    BNE       7f

                    LEA       __free_ram_start__,%A2
                    CMPI.B    #0x55,0x1FE(%A2)                        | Validate the MBR signature
                    BNE       9f
                    CMPI.B    #0xAA,0x1FF(%A2)
                    BEQ       10f

9:                  TST       0x0A(%FP)                               | If quiet, don't show error
                    BNE       7f
                    PRT_ERR   strSignature                            | Error, invalid signature
                    BRA       7f

10:                 CLR.W     %D0
                    LEA       __free_ram_start__,%A2
                    ADD       #MBR_PRT_TBL_0,%A2                      | Offset to the MBR's first partition table entry
                    LEA       PT_ENTRIES(%A3),%A4                     | Offset to our first partition table entry

                    MOVE.L    PT_SECTORS(%A3),%D1                     | Load the total disk sector count into D1

1:                  MOVE.B    PRT_TYPE(%A2),%D2                       | Partition type
                    BEQ       6f                                      | 0x00 identifies an unused partition
                    MOVE.B    %D2,PE_TYPE(%A4)                        | Save in our table entry

                    MOVE.L    PRT_START_LBA(%A2),%D2                  | Partition start LBA
                    TO_BIG_END %D2                                    | Convert to big endian
                    MOVE.L    %D2,PE_START(%A4)                       | Save in our table entry
                    CMP.L     %D1,%D2                                 | Start LBA must be less then max LBA
                    BLE       2f

                    TST       0x0A(%FP)                               | If quiet, don't show error
                    BNE       7f
                    PRT_ERR   strStartMax                             | Error, start LBA > max LBA
                    BRA       7f

2:                  MOVE.L    PRT_SEC_COUNT(%A2),%D3                  | Sector count
                    TO_BIG_END %D3                                    | Convert to big endian
                    MOVE.L    %D3,PE_SECTORS(%A4)                     | Save in our table entry
                    ADD.L     %D2,%D3                                 | Partion end LBA
                    SUBQ.L    #1,%D3
                    CMP.L     %D1,%D3                                 | End LBA must be less then max LBA
                    BLE       3f

                    TST       0x0A(%FP)                               | If quiet, don't show error
                    BNE       7f
                    PRT_ERR   strEndMax                               | Error, end LBA > max LBA
                    BRA       7f

3:                  CMP.L     %D2,%D3                                 | End LBA must be > start lba
                    BGT       4f

                    TST       0x0A(%FP)                               | If quiet, don't show error
                    BNE       7f
                    PRT_ERR   strStartEnd                             | Error, start LBA >= end LBA
                    BRA       7f

4:                  TST.W     %D0
                    BEQ       5f

                    CMP.L     %D5,%D2                                 | Start LBA must not be before previous partitions end LBA
                    BGT       5f

                    TST       0x0A(%FP)                               | If quiet, don't show error
                    BNE       7f
                    PRT_ERR   strStartLast
                    BRA       7f

5:                  MOVE.L    %D2,%D4                                 | Keep start LBA
                    MOVE.L    %D3,%D5                                 | Keep end LBA

                    MOVE.B    #1,PE_VALID(%A4)                        | Mark the entry in our table as valid

6:                  ADDQ.W    #1,%D0                                  | Increment count
                    ADD.L     #PRT_ENTRY_SIZE,%A2                     | Next entry in MBR partition table
                    ADD.L     #PE_SIZE,%A4                            | Next entry in our partition table
                    CMPI.W    #4,%D0
                    BLT       1b

                    MOVE.W    #1,PT_VALID(%A3)                        | Mark our table as valid
                    MOVE.W    #0,%D0                                  | Return 0 = success
                    BRA       8f

7:                  MOVE.W    #1,%D0

8:                  MOVEM.L   (%SP)+,%D1-%D6/%A2-%A4
                    UNLK      %FP
                    RTS


*-----------------------------------------------------------------------------------------------------
* showPartitions(word driveId)
* Display the parttion table
*-----------------------------------------------------------------------------------------------------
showPartitions:     LINK      %FP,#0
                    MOVEM.L   %D0-%D5/%A3,-(%SP)

                    MOVE.W    0x08(%FP),%D6                           | Current drive
                    EXT.L     %D6
                    MULU.W    #PT_SIZE,%D6
                    LEA       PART_TABLE_A,%A3
                    ADD.L     %D6,%A3                                 | Base of drive partition entry

                    TST.W     PT_VALID(%A3)
                    BNE       1f

                    PUTS      strInvalidMBR
                    BRA       6f

1:                  MOVE.W    PT_CURRENT(%A3),%D4                     | Keey the current partition id

                    PUTSP     #3                                      | Indent
                    PUTS      strSectors
                    MOVE.L    PT_SECTORS(%A3),%D0
                    BSR       writeHexLong
                    BSR       newLine

                    PUTSP     #3                                      | Indent
                    PUTS      strHeader

                    LEA       PT_ENTRIES(%A3),%A4                     | Offset to our first partition table entry
                    CLR.W     %D3

2:                  TST.B     PE_TYPE(%A4)                            | Partition type
                    BEQ       5f                                      | 0x00 identifies an unused partition

                    PUTSP     #3                                      | Indent
                    PUTCH     #'['
                    MOVE.B    %D3,%D0
                    BSR       writeHexDigit
                    PUTCH     #']'

                    CMP.W     %D4,%D3                                 | Is this the current drive
                    BNE       3f
                    PUTCH     #'*'                                    | Yes, highlight it
                    PUTSP     #5
                    BRA       4f

3:                  PUTSP     #6

4:                  MOVE.L    PE_START(%A4),%D0                       | Partition start LBA
                    BSR       writeHexLong
                    PUTSP     #2

                    MOVE.L    PE_SECTORS(%A4),%D1                     | Sector count
                    ADD.L     %D1,%D0                                 | Partion end LBA
                    SUBQ.L    #1,%D0
                    BSR       writeHexLong
                    PUTSP     #2

                    MOVE.L    %D1,%D0
                    BSR       writeHexLong
                    PUTSP     #2

                    MOVE.B    PE_TYPE(%A4),%D0                        | Partition type
                    BSR       writeHexByte
                    PUTSP     #3
                    BSR       showType

                    BSR       newLine

5:                  ADDQ.W    #1,%D3
                    ADD.L     #PE_SIZE,%A4
                    CMPI.W    #4,%D3
                    BLT       2b

6:                  MOVEM.L   (%SP)+,%D0-%D5/%A3
                    UNLK      %FP
                    RTS

*---------------------------------------------------------------------------------------------------------
* Display the partition type if recognised
*---------------------------------------------------------------------------------------------------------
showType:           CMP.B     #PID_FAT12,%D0
                    BNE       1f
                    PUTS      strFAT12
                    RTS

1:                  CMP.B     #PID_FAT16,%D0
                    BNE       1f
                    PUTS      strFAT16
                    RTS

1:                  CMP.B     #PID_FAT16B,%D0
                    BNE       1f
                    PUTS      strFAT16B
                    RTS

1:                  CMP.B     #PID_FAT32,%D0
                    BNE       1f
                    PUTS      strFAT32
                    RTS

1:                  CMP.B     #PID_CPM80,%D0
                    BNE       1f
                    PUTS      strCPM80
                    RTS

1:                  CMP.B     #PID_CPM86,%D0
                    BNE       1f
                    PUTS      strCPM86
                    RTS

1:                  CMP.B     #PID_CROMIX,%D0
                    BNE       1f
                    PUTS      strCROMIX
                    RTS

1:                  CMP.B     #PID_OS9,%D0
                    BNE       1f
                    PUTS      strOS9
                    RTS

1:                  CMP.B     #PID_CDOS,%D0
                    BNE       1f
                    PUTS      strCDOS
1:                  RTS

*---------------------------------------------------------------------------------------------------------
                    .bss
                    .align(2)
PART_TABLE_A:       ds.b      PT_SIZE
PART_TABLE_B:       ds.b      PT_SIZE

*---------------------------------------------------------------------------------------------------------
                    .section  .rodata.strings
                    .global   strInvalidMBR

                    .align(2)
strSectors:         .asciz    "Sectors: "
strPartition:       .asciz    "   Partition ["
strEndPartition:    .asciz    "]  "
strStartMax:        .asciz    "], starting LBA is greater than max sectors\r\n"
strEndMax:          .asciz    "], ending LBA is greater than max sectors\r\n"
strStartEnd:        .asciz    "], end LBA must be grater than start LBA\r\n"
strStartLast:       .asciz    "], start LBA is less than previous partition's end LBA\r\n"
strHeader:          .asciz    "Partition   Start       End   Sectors  Id   Type\r\n"
strInvalidMBR:      .asciz    "   No valid MBR partition table\r\n"
strSignature:       .asciz    "   Invalid MBR signature\r\n"
strFAT12:           .asciz    "FAT12"
strFAT16:           .asciz    "FAT16"
strFAT16B:          .asciz    "FAT16B"
strFAT32:           .asciz    "FAT32"
strCPM80:           .asciz    "CP/M"
strCPM86:           .asciz    "CP/M"
strCDOS:            .asciz    "CDOS"
strCROMIX:          .asciz    "Cromix"
strOS9:             .asciz    "OS-9"


