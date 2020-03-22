                    .include  "include/macros.i"
                    .include  "include/file-sys.i"
                    .include  "include/ide.i"

MAX_FAT_VDISKS      =         10                                      | Max number of virtual disks
SEEK_SET            =         0                                       | Seek from the begining
HDD_SECT_MULU_SHIFT =         9                                       | The number of places to left shift to multiply by HDD_SECTOR_SIZE

*-----------------------------------------------------------------------------------------------------
                    .bss
                    .align(2)

D_PARTITION_ID:     ds.w      1
D_FILESYS_TYPE:     ds.w      1
D_PARTITION_OFFSET: ds.l      1

D_FAT_FILES:        ds.l      MAX_FAT_VDISKS

*-----------------------------------------------------------------------------------------------------
                    .data
                    .align(2)
D_FAT_NAMES:        .long     strDriveA
                    .long     strDriveB
                    .long     strDriveC
                    .long     strDriveD
                    .long     strDriveE
                    .long     strDriveF
                    .long     strDriveG
                    .long     strDriveH
                    .long     strDriveI
                    .long     strDriveJ

*-----------------------------------------------------------------------------------------------------

                    .text
                    .global   initDisks
                    .global   readDiskSector
                    .global   writeDiskSector
                    .global   openVDisk                               | **** DEBUG

*-----------------------------------------------------------------------------------------------------
* initDisks()
*-----------------------------------------------------------------------------------------------------
initDisks:          LINK      %FP,#0
                    MOVE.W    currentDrive,%D0                        | Get current drive

                    MOVE.W    %D0,-(%SP)                              | Get the filesystem type
                    BSR       getFileSysType
                    ADD.L     #2,%SP

                    MOVE.W    %D0,D_FILESYS_TYPE

                    CMPI.W    #FS_FAT,%D0                             | FAT
                    BEQ       1f

                    CMPI.W    #FS_CPM,%D0                             | CP/M
                    BEQ       2f

                    CMPI.W    #FS_NONE,%D0                            | None
                    BEQ       3f

                    PUTS      strUnsupportedType                      | Unsupported partition
                    BRA       4f

                    /* FAT Partition */
1:                  MOVE.W    #0,-(%SP)                               | Open virtual drive A
                    BSR       openVDisk
                    ADD       #2,%SP
                    BRA       4f

                    /* CP/M Partition */
2:                  MOVE.W    currentDrive,-(%SP)                     | driveId
                    BSR       getPartitionId                          | Get the drive's current partition
                    ADD       #2,%SP
                    MOVE.W    %D0,D_PARTITION_ID

                    EXT.L     %D0
                    MOVE.L    %D0,-(%SP)                              | Param - partitionId
                    MOVE.W    currentDrive,%D0
                    EXT.L     %D0
                    MOVE.L    %D0,-(%SP)                              | Param - driveId
                    BSR       getPartitionStart                       | Get the offset (in sectors) to the start of the partition
                    ADD       #8,%SP
                    MOVE.L    %D0,D_PARTITION_OFFSET
                    BRA       4f

                    /* NO Partition, assume raw CP/M file sys */
3:                  MOVE.L    #0,D_PARTITION_OFFSET
                    BRA       4f

4:                  UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* readDiskSector(long lba, word drive, word count, char *address)
*-----------------------------------------------------------------------------------------------------
readDiskSector:     LINK      %FP,#0

                    CMPI.W    #FS_FAT,D_FILESYS_TYPE
                    BEQ       1f

                    CMPI.W    #FS_CPM,D_FILESYS_TYPE
                    BEQ       2f

                    CMPI.W    #FS_NONE,D_FILESYS_TYPE
                    BEQ       2f

                    PUTS      strUnsupportedType                      | Unsupported partition
                    BRA       3f

                    /* FAT Partition */
1:                  MOVE.L    0x10(%FP),-(%SP)                        | Param - buffer addres
                    MOVE.W    0x0E(%FP),-(%SP)                        | Param - sector count
                    MOVE.W    0x0C(%FP),-(%SP)                        | Param - drive id
                    MOVE.L    0x08(%FP),-(%SP)                        | Param - lba
                    BSR       readVDisk
                    ADD       #0x0c,%SP
                    BRA       3f

                    /* CP/M Partition or raw CP/M file system */
2:                  MOVE.W    0x0C(%FP),%D0                           | drive index
                    MULU.W    #0x2000,%D0                             | Calculate CPM partition offset 1024 tracks * 32 sectors/track * 512 /128
                    ADD.L     D_PARTITION_OFFSET,%D0                  | Add the MBR partition offset
                    ADD.L     0x08(%FP),%D0                           | Add the requested LBA value
                    BSR       setLBA

                    MOVE.W    0x0E(%FP),%D0                           | Sector count
                    MOVE.L    0x10(%FP),%A2                           | Buffer address
                    BSR       readSectors                             | Read the sectors

3:                  UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* writeDiskSector(long lba, word drive, word count, char *address)
*-----------------------------------------------------------------------------------------------------
writeDiskSector:    LINK      %FP,#0

                    CMPI.W    #FS_FAT,D_FILESYS_TYPE
                    BEQ       1f

                    CMPI.W    #FS_CPM,D_FILESYS_TYPE
                    BEQ       2f

                    CMPI.W    #FS_NONE,D_FILESYS_TYPE
                    BEQ       2f

                    PUTS      strUnsupportedType                      | Unsupported partition
                    BRA       3f

                    /* FAT Partition */
1:                  MOVE.L    0x10(%FP),-(%SP)                        | Param - buffer addres
                    MOVE.W    0x0E(%FP),-(%SP)                        | Param - sector count
                    MOVE.W    0x0C(%FP),-(%SP)                        | Param - drive id
                    MOVE.L    0x08(%FP),-(%SP)                        | Param - lba
                    BSR       writeVDisk
                    ADD       #0x0c,%SP
                    BRA       3f

                    /* CP/M Partition or raw CP/M file system */
2:                  MOVE.W    0x0C(%FP),%D0                           | drive index
                    MULU.W    #0x2000,%D0                             | Calculate CPM partition offset 1024 tracks * 32 sectors/track * 512 /128
                    ADD.L     D_PARTITION_OFFSET,%D0                  | Add the MBR partition offset
                    ADD.L     0x08(%FP),%D0                           | Add the requested LBA value
                    BSR       setLBA

                    MOVE.W    0x0E(%FP),%D0                           | Sector count
                    MOVE.L    0x10(%FP),%A2                           | Buffer address
                    BSR       writeSectors                            | Write the sectors

3:                  UNLK      %FP
                    RTS

*---------------------------------------------------------------------------------------------------------
* writeVDisk(long lba, word drive, word count, char *address)
*---------------------------------------------------------------------------------------------------------
writeVDisk:         LINK      %FP,#-4

                    MOVE.W    0x0C(%FP),-(%SP)                        | Open the disk image if it isn't and return file*
                    BSR       openVDisk
                    ADD       #2,%SP

                    TST.L     %D0
                    BNE       2f                                      | File was opened

                    PUTS      strVDiskOpenError                       | Display an error message
                    MOVE.W    0x0C(%FP),%D0
                    ADD.B     #'A',%D0
                    BSR       writeCh
                    BSR       newLine

                    MOVE.W    #1,%D0                                  | Return 1 = open error
                    BRA       5f

2:                  MOVE.L    %D0,-4(%FP)                             | Save the file pointer

                    /* Seek to the required LBA offset */
                    MOVE.L    #SEEK_SET,-(%SP)                        | Param - origin
                    MOVE.L    0x08(%FP),%D0                           | LBA
                    MOVE.W    #HDD_SECT_MULU_SHIFT,%D1                | Shift left 9 ( x 512) to get byte offset
                    LSL.L     %D1,%D0
                    MOVE.L    %D0,-(%SP)                              | Param - offset
                    MOVE.L    -4(%FP),-(%SP)                          | Param - file*
                    BSR       fl_fseek                                | Seek to the required LBA
                    ADD       #0x0C,%SP

                    TST       %D0
                    BEQ       3f                                      | Successful

                    PUTS      strVDiskSeekError
                    MOVE.W    #2,%D0                                  | Return 2 = seek error
                    BRA       5f

                    /* Write required sectors */
3:                  MOVE.L    -4(%FP),-(%SP)                          | Param - file pointer
                    MOVE.W    0x0E(%FP),%D0                           | Sector count
                    EXT.L     %D0                                     | To long
                    MOVE.L    %D0,-(%SP)                              | Param - count
                    MOVE.L    #IDE_SEC_SIZE,-(%SP)                    | Param - size
                    MOVE.L    0x10(%FP),-(%SP)                        | Param - buffer address
                    BSR       fl_fwrite                               | Write the specified sectors
                    ADD       #0x10,%SP

                    MOVE.W    0x0E(%FP),%D1                           | Specified sector count
                    EXT.L     %D1                                     | To long
                    MOVE.W    #HDD_SECT_MULU_SHIFT,%D2                | To Bytes
                    LSL.L     %D2,%D1
                    CMP.W     %D1,%D0
                    BEQ       4f                                      | Successful

                    PUTS      strVDiskReadError
                    MOVE.W    #2,%D0                                  | Return 3 = read error
                    BRA       5f

                    /* Flush to disk */
4:                  MOVE.L    -4(%FP),-(%SP)                          | Param - file pointer
                    BSR       fl_fflush                               | Flush the written sectors
                    MOVE.W    #0,%D0                                  | Return 0 = successful

5:                  UNLK      %FP
                    RTS

*---------------------------------------------------------------------------------------------------------
* readVDisk(long lba, word drive, word count, char *address)
*---------------------------------------------------------------------------------------------------------
readVDisk:          LINK      %FP,#-4

                    MOVE.W    0x0C(%FP),-(%SP)                        | Open the disk image if it isn't and return file*
                    BSR       openVDisk
                    ADD       #2,%SP

                    TST.L     %D0
                    BNE       2f                                      | File was opened

                    PUTS      strVDiskOpenError                       | Display an error message
                    MOVE.W    0x0C(%FP),%D0
                    ADD.B     #'A',%D0
                    BSR       writeCh
                    BSR       newLine

                    MOVE.W    #1,%D0                                  | Return 1 = open error
                    BRA       5f

2:                  MOVE.L    %D0,-4(%FP)                             | Save the file pointer

                    /* Seek to the required LBA offset */
                    MOVE.L    #SEEK_SET,-(%SP)                        | Param - origin
                    MOVE.L    0x08(%FP),%D0                           | LBA
                    MOVE.W    #HDD_SECT_MULU_SHIFT,%D1                | Shift left 9 ( x 512) to get byte offset
                    LSL.L     %D1,%D0
                    MOVE.L    %D0,-(%SP)                              | Param - offset
                    MOVE.L    -4(%FP),-(%SP)                          | Param - file*
                    BSR       fl_fseek                                | Seek to the required LBA
                    ADD       #0x0C,%SP

                    TST       %D0
                    BEQ       3f                                      | Successful

                    PUTS      strVDiskSeekError
                    MOVE.W    #2,%D0                                  | Return 2 = seek error
                    BRA       5f

                    /* Read required sectors */
3:                  MOVE.L    -4(%FP),-(%SP)                          | Param - file*
                    MOVE.W    0x0E(%FP),%D0                           | Sector count
                    EXT.L     %D0                                     | To long
                    MOVE.L    %D0,-(%SP)                              | Param - count
                    MOVE.L    #IDE_SEC_SIZE,-(%SP)                    | Param - size
                    MOVE.L    0x10(%FP),-(%SP)                        | Param - buffer address
                    BSR       fl_fread                                | Read the required sectors
                    ADD       #0x10,%SP

                    MOVE.W    0x0E(%FP),%D1                           | Required sector count
                    EXT.L     %D1                                     | To Long
                    MOVE.W    #HDD_SECT_MULU_SHIFT,%D2                | To Bytes
                    LSL.L     %D2,%D1
                    CMP.W     %D1,%D0
                    BEQ       4f                                      | Successful

                    PUTS      strVDiskReadError
                    MOVE.W    #2,%D0                                  | Return 3 = read error
                    BRA       5f

4:                  MOVE.W    #0,%D0                                  | Return 0 = successful

5:                  UNLK      %FP
                    RTS

*---------------------------------------------------------------------------------------------------------
* openVDisk(word diskIndex)
*---------------------------------------------------------------------------------------------------------
openVDisk:          LINK      %FP,#-4                                 | Local variable for offset

                    MOVE.W    0x08(%FP),%D0                           | Calculate disk index offset
                    EXT.L     %D0                                     | To long
                    LSL.L     #2,%D0                                  | x 4
                    MOVE.L    %D0,-4(%FP)                             | Save

                    LEA       D_FAT_FILES,%A0                         | Check if disk is already opened
                    ADD.L     %D0,%A0
                    MOVE.L    (%A0),%D0
                    BNE       1f                                      | Disk is open

                    PEA       strFileMode                             | Param - mode
                    LEA       D_FAT_NAMES,%A0
                    ADD.L     -4(%FP),%A0
                    MOVE.L    (%A0),-(%SP)                            | Param - file name
                    BSR       fl_fopen
                    ADD       #0x08,%SP

                    LEA       D_FAT_FILES,%A0                         | save File*
                    MOVE.L    -4(%FP),%D1
                    ADD.L     %D1,%A0
                    MOVE.L    %D0,(%A0)

1:                  UNLK      %FP
                    RTS

*---------------------------------------------------------------------------------------------------------
                    .section  .rodata.strings
                    .align(2)
                    .global   strDriveA

strFileMode:        .asciz    "r+"

strDriveA:          .asciz    "/drive_a.img"
strDriveB:          .asciz    "/drive_b.img"
strDriveC:          .asciz    "/drive_c.img"
strDriveD:          .asciz    "/drive_d.img"
strDriveE:          .asciz    "/drive_e.img"
strDriveF:          .asciz    "/drive_f.img"
strDriveG:          .asciz    "/drive_g.img"
strDriveH:          .asciz    "/drive_h.img"
strDriveI:          .asciz    "/drive_i.img"
strDriveJ:          .asciz    "/drive_j.img"

strVDiskOpenError:  .asciz    "Failed to open virtual disk "
strVDiskSeekError:  .asciz    "Failed to seek virtual disk "
strVDiskReadError:  .asciz    "Failed to read virtual disk "
strVDiskWriteError: .asciz    "Failed to write virtual disk "


