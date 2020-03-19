                    .include  "include/disk-def.i"
                    .include  "include/file-sys.i"
                    .include  "include/macros.i"

                    .text
                    .global   loadBootLoader
                    .global   lbl1

LOAD_ADDRESS        =         0xFE0000
BOOT_SECTORS        =         DEF_DD_BOOT_TRACKS * DEF_DD_SEC_TRK

*-----------------------------------------------------------------------------------------------------
* loadBootLoader
*-----------------------------------------------------------------------------------------------------
loadBootLoader:     LINK      %FP,#-2                                 | local variable - word driveId

                    MOVE.W    currentDrive,%D1                        | Get current drive
                    MOVE.W    %D1,-2(%FP)                             | Local driveId variable

                    MOVE.W    %D1,-(%SP)
                    BSR       getFileSysType
                    ADD.L     #2,%SP

*                    CMPI.W    #FS_FAT,%D0
*                    BEQ       1f

                    CMPI.W    #FS_CPM,%D0
                    BEQ       2f

                    CMPI.W    #FS_NONE,%D0
                    BEQ       3f

                    PUTS      strUnsupportedType                      | Unsupported partition
                    BRA       4f


                    /* CP/M partition */
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
                    BSR       setLBA
                    BRA       4f

                    /* No partition, assume raw CP/M file system */
3:                  CLR.L     %D0                                     | Start at LBA 0, ie. track 0, sector 0
                    BSR       setLBA

4:                  MOVE.L    #BOOT_SECTORS,%D0                       | Number of CP/M sectors in the boot tracks
                    LSR.L     #SECT_HDD_CPM_SHIFT,%D0                 | Convert to HDD sectors
                    MOVE.L    #LOAD_ADDRESS,%A2                       | Load address
                    BSR       readSectors                             | Read the block
                    BNE       5f                                      | Error?

                    MOVE.L    #LOAD_ADDRESS,%A0
lbl1:               JMP       (%A0)                                   | Good luck

5:                  UNLK      %FP
                    RTS
