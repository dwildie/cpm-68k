                    .include  "include/macros.i"
                    .include  "include/file-sys.i"
                    .include  "include/ide.i"

MAX_FAT_VDISKS      =         10                                      | Max number of virtual disks
MAX_OPEN_FAT        =         4                                       | Maximum number of disks open concurrently, must be <= max open files in libfat
SEEK_SET            =         0                                       | Seek from the begining
HDD_SECT_MULU_SHIFT =         9                                       | The number of places to left shift to multiply by HDD_SECTOR_SIZE

TBL_FAT_ID_OFF      =         0x0                                     | Offset into a table record for the identifier
TBL_FAT_FILE_OFF    =         0x2                                     | Offset into a table record for the file*
TBL_FAT_LRU_OFF     =         0x6                                     | Offset into a table record for the LRU sequence
TBL_FAT_SIZE        =         0xa                                     | Table record size

*-----------------------------------------------------------------------------------------------------
                    .bss
                    .align(2)

D_PARTITION_ID:     ds.w      1
D_FILESYS_TYPE:     ds.w      1
D_PARTITION_OFFSET: ds.l      1

TBL_FAT:            ds.b      MAX_OPEN_FAT * TBL_FAT_SIZE             | FAT Drive-File table
D_SEQ_LRU:          ds.l      1                                       | FAT master LRU sequence

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
openVDisk:          LINK      %FP,#-2                                 | Local variable for drive id
                    MOVEM.L   %D1-%D5/%A2,-(%SP)

                    MOVE.W    0x08(%FP),%D0                           | Calculate disk identifier
                    ADD.W     #'A',%D0
                    AND.W     #0xFF,%D0
                    MOVE.W    %D0,-2(%FP)                             | Save it

                    /* Look for a record with the same identifier */
ovd1:               LEA       TBL_FAT,%A2                             | FAT Table base
                    MOVE.W    #0x0,%D1                                | First table record index
                    MOVE.W    #0x0,%D2                                | First table record offset

1:                  CMP.W     TBL_FAT_ID_OFF(%A2,%D2.W),%D0
                    BEQ       7f                                      | Found it

                    ADDI.W    #TBL_FAT_SIZE,%D2                       | Next record                  
                    ADDQ.W    #1,%D1                                  | Increment index
                    CMPI.W    #MAX_OPEN_FAT,%D1
                    BLT       1b

                    /* We didn't find it so look for an empty slot */
                    MOVE.W    #0x0,%D1                                | First table record index
                    MOVE.W    #0x0,%D2                                | First table record offset

3:                  TST.W     TBL_FAT_ID_OFF(%A2,%D2.W)
                    BEQ       6f                                      | Use this empty slot

                    ADDI.W    #TBL_FAT_SIZE,%D2                       | Next record                  
                    ADDQ.W    #1,%D1                                  | Increment index
                    CMPI.W    #MAX_OPEN_FAT,%D1
                    BLT       3b

                    /* We didn't find an empty slot find the least recently used slot and close the file */
                    MOVE.W    #0x1,%D1                                | Second table record index
                    MOVE.W    #TBL_FAT_SIZE,%D2                       | Second table record offset
                    MOVE.W    #0x0,%D3                                | First table record is initial LRU - index
                    MOVE.W    #0x0,%D4                                | First table record is initial LRU - offset

4:                  MOVE.L    TBL_FAT_LRU_OFF(%A2,%D2.W),%D5
                    CMP.L     TBL_FAT_LRU_OFF(%A2,%D4.W),%D5          | Is this slot's LRU less than current?
                    BGE       5f                                      | No

                    MOVE.W    %D1,%D3                                 | Yes, this slot is now current LRU
                    MOVE.L    %D2,%D4

5:                  ADDQ.W    #1,%D1                                  | Increment index
                    ADDI.W    #TBL_FAT_SIZE,%D2                       | Next record                  
                    CMPI.W    #MAX_OPEN_FAT,%D1
                    BLT       4b
                    MOVE.W    %D3,%D1
                    MOVE.W    %D4,%D2

                    /* %D1 is the index to the LRU slot, %D2 is the offset, close the file */
                    MOVE.L    TBL_FAT_FILE_OFF(%A2,%D2.W),-(%SP)      | Param - file*
                    BSR       fl_fclose                               | Close the file
                    ADD       #0x04,%SP
                    MOVE.L    #0,TBL_FAT_FILE_OFF(%A2,%D2.W)

                    /* %D1 is the index to an empty slot, %D2 is the offset, open the file */
6:                  MOVE.W    -2(%FP),TBL_FAT_ID_OFF(%A2,%D2.W)       | Set the records drive identifier

                    PEA       strFileMode                             | Param - mode
                    LEA       D_FAT_NAMES,%A1
                    MOVE.W    0x08(%FP),%D0                           | Calculate offset into file name list
                    LSL.W     #2,%D0
                    MOVE.L    (%A1,%D0.W),-(%SP)                      | Param - file name
                    BSR       fl_fopen
                    ADD       #0x08,%SP

                    MOVE.L    %D0,TBL_FAT_FILE_OFF(%A2,%D2.W)

7:                  ADDQ.L    #1,D_SEQ_LRU                            | Increment LRU seq
                    MOVE.L    D_SEQ_LRU,TBL_FAT_LRU_OFF(%A2,%D2.W)

                    MOVE.L    TBL_FAT_FILE_OFF(%A2,%D2.W),%D0         | Return the file pointer

ret:                MOVEM.L   (%SP)+,%D1-%D5/%A2
                    UNLK      %FP
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


