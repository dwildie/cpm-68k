                    .include  "include/disk-def.i"
                    .include  "include/cpm-fs.i"
                    .include  "include/ascii.i"
                    .include  "include/macros.i"

                    .text
                    .global   fOpenCPM
                    .global   fReadCPM
                    .global   fCloseCPM

                    .global   readBlock                               | **** DEBUG

*-----------------------------------------------------------------------------------------------------
* fOpenCPM(long partitionOffset, char* fileName)
* Open fileName, 8 char name + 3 char type
* Return: 0 success
*         1 file not found
*-----------------------------------------------------------------------------------------------------
fOpenCPM:           LINK      %FP,#-extentsArrayBytes

                    MOVE.W    #0,recordCount
                    MOVE.L    #0,lastRecordSize
                    MOVE.L    #0,blockCount
                    MOVE.L    #0,blockArray
                    MOVE.l    0x08(%FP),partitionOffset

                    MOVE.L    #0,%D3                                  | Use %D3 as the extent count


                    MOVE.L    0x0C(%FP),-(%SP)                        | Format the name as 11 characters
                    BSR       formatName                              | in location fileName
                    ADDQ.L    #4,%SP

                    LEA       __free_ram_start__,%A0
                    MOVE.L    %A0,-(%SP)                              | Param buffer
                    MOVE.L    partitionOffset,-(%SP)                  | Param: partitionOffset
                    BSR       readCpmDirectory                        | Read the directory, %D0 contains the number of entries
                    ADD       #8,%SP

                    PEA       -extentsArrayBytes(%FP)                 | Target extent array
                    PEA       fileName                                | Formatted filename
                    MOVE.W    %D0,-(%SP)                              | Number of read extents
                    PEA       __free_ram_start__                      | Read directory extent array
                    BSR       findExtents
                    ADD.L     #0x0E,%SP

                    TST.B     %D0                                     | Check if any matching extents found
                    BNE       3f

                    MOVE.L    #1,%D0                                  | Error file not found, return 1
                    BRA       10f

3:                  LEA       -extentsArrayBytes(%FP),%A0             | The base of the extents array, %D0 already contains the count
                    BSR       processExtents
                    TST.B     %D0
                    BNE       10f                                     | Error


                    CLR.W     nextBlockIndex                          | initialise FCB
                    CLR.L     offsetIntoFile

                    LEA       __free_ram_start__,%A0                  | Setup the block buffer
                    MOVE.L    %A0,blockBuffer

                    BSR       readNextBlock                           | Read the first block now

                    MOVE.L    #0,%D0                                  | Success, return 0

10:                 UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* cpmFread(word count, *buffer)
* Read count bytes into buffer, return the number of bytes read in %D0
*-----------------------------------------------------------------------------------------------------
fReadCPM:           LINK      %FP,#0
                    MOVEM.L   %D1-%D3/%A0-%A2,-(%SP)

                    MOVE.W    0x08(%FP),%D3                           | Number of bytes to read less one for DBREQ
                    SUBQ.W    #1,%D3

                    CLR.W     %D1                                     | Offet into destination buffer
                    MOVE.L    0x0A(%FP),%A1                           | Destination buffer

                    MOVE.W    offsetIntoBlock,%D2                     | Offset into source block
                    MOVE.L    blockBuffer,%A2                         | Source block


1:                  MOVE.B    (%A2,%D2.W),(%A1,%D1.W)                 | Transfer one byte from the source to the destination
                    ADDQ.W    #1,%D1                                  | Increment both indexes
                    ADDQ.W    #1,%D2

                    CMP.W     blockBufferLen,%D2                      | Is this past the end of the current block ?
                    BLT       2f                                      | No, continue with transfer

                    BSR       readNextBlock                           | Yes, read the next block
                    BNE       3f                                      | No more blocks EOF
                    CLR.W     %D2

2:                  DBRA      %D3,1b

3:                  MOVE.W    %D2,offsetIntoBlock                     | Update offset variable
                    MOVE.W    %D1,%D0                                 | Return number of bytes read

                    MOVEM.L   (%SP)+,%D1-%D3/%A0-%A2
                    UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* Close the current file
*-----------------------------------------------------------------------------------------------------
fCloseCPM:
                    RTS

*-----------------------------------------------------------------------------------------------------
* Read next block
*-----------------------------------------------------------------------------------------------------
readNextBlock:      MOVEM.L   %D0-%D7/%A0-%A7,-(%SP)
                    MOVE.L    blockBuffer,%A0                         | Address of block buffer
                    MOVE.W    nextBlockIndex,%D0

                    CMP.W     blockCount,%D0
                    BLT       1f

                    MOVE.B    #1,%D0                                  | End of file, return non-zero
                    BRA       4f

1:                  BSR       readBlock
                    CLR.W     offsetIntoBlock

                    MOVE.W    nextBlockIndex,%D0                      | Increment block index
                    ADDQ.W    #1,%D0
                    MOVE.W    %D0,nextBlockIndex

                    CMP.W     blockCount,%D0                          | Is this the last block?
                    BNE       2f                                      | No

                    SUBQ.W    #1,%D0                                  | Yes, may not be full length
                    LSL.W     #DEF_BLOCK_128_SHIFT,%D0                | Convert to records (cpm sectors)
                    MOVE.W    recordCount,%D1
                    SUB.W     %D0,%D1                                 | Remaining cpm sectors in this block
                    MULU.W    #DEF_DD_SEC_SIZE,%D1                    | Convert to bytes
                    MOVE.W    %D1,blockBufferLen
                    BRA       3f

2:                  MOVE.W    #DEF_DD_BLOCK_SIZE,blockBufferLen       | Full size block                 
3:                  MOVE.B    #0,%D0

                    MOVEM.L   (%SP)+,%D0-%D7/%A0-%A7
4:                  RTS

*-----------------------------------------------------------------------------------------------------
* Read block, %D0 block index, %A0 buffer address
*-----------------------------------------------------------------------------------------------------
readBlock:          LSL.W     #1,%D0                                  | Multiply by 2
                    CLR.L     %D1
                    LEA       blockArray,%A1

                    MOVE.W    (%A1,%D0.W),%D1                         | Get the block index
                    LSL.L     #DEF_BLOCK_512_SHIFT,%D1                | Convert to sector offset, ie LBA

                    MOVE.W    #DEF_DD_DIR_START,%D2                   | Add in the offset for any boot tracks
                    EXT.L     %D2                                     | To long
                    LSR.L     #SECT_HDD_CPM_SHIFT,%D2                 | From CPM sectors to HDD sectors
                    ADD.L     %D2,%D1

                    ADD.L     partitionOffset,%D1                     | Add the offset to the start of the partition
                    MOVE.L    %D1,%D0                                 | Set the drive's LBA value
                    BSR       setLBA

                    MOVE.L    #1,%D0                                  | Read one block
                    LSL.L     #DEF_BLOCK_512_SHIFT,%D0                | Convert to sectors
                    MOVE.L    %A0,%A2                                 | Buffer address
                    BSR       readSectors                             | Read the block

                    BEQ       1f                                      | Success

                    MOVE.B    #1,%D0
                    BRA       2f

1:                  CLR.B     %D0
2:                  RTS

*-----------------------------------------------------------------------------------------------------
* Find each extent for the specified file
* findExtents(Extent *readExtents, word readExtentCount, char *formattedFileName, Extent *foundExtentArray)
* Return %D0 = Number of extents found
*-----------------------------------------------------------------------------------------------------
findExtents:        LINK      %FP,#0

                    MOVE.L    0x08(%FP),%A2                           | Read directory extent array
                    MOVE.W    0x0C(%FP),%D2                           | Number of read extents
                    MOVE.L    0x0E(%FP),%A3                           | Formatted filename
                    MOVE.L    0x12(%FP),%A4                           | Target extent array

                    MOVE.L    #0,%D4                                  | Use %D4 as matched extent count

1:                  CMPI.B    #0,USER_NUMBER_OFFSET(%A2)              | User number must be in the range 0 - 15
                    BLT       2f                                      | Skip this entry
                    CMPI.B    #0x0F,USER_NUMBER_OFFSET(%A2)
                    BGT       2f                                      | Skip

                    LEA       FILE_NAME_OFFSET(%A2),%A0               | Compare this entry to the filename
                    MOVE.L    %A3,%A1                                 | Required file name
                    MOVE.L    #11,%D0                                 | 10 characters to compare
                    BSR       memCmp
                    TST.B     %D0                                     | Check the result
                    BNE       2f                                      | Do not match

                    MOVE.L    %A2,(%A4)+                              | Store the extents pointer                
                    ADDI.L    #1,%D4                                  | Increment the matched extents count

2:                  ADD.L     #DEF_DD_DIR_ENTRY,%A2                   | Move to the next entry
                    DBEQ      %D2,1b

                    MOVE.L    %D4,%D0                                 | Return the matched extent count

                    UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* Process each of the extents for the file, assume that the extents are not in sequential order
* %A0 points to the array of 32 byte extents
* %D0 specifies the number of extents
* Return %D0 = 0 - No error
*              -2 - Extent not found
*-----------------------------------------------------------------------------------------------------
processExtents:     MOVE.W    %D0,%D4                                 | The number of extents to be processed
                    LEA       blockArray,%A3                          | Initialise the target block array index
                    MOVE.W    #0,%D1                                  | Extent sequence number
                    CLR.W     blockCount

4:                  MOVE.W    #0,%D2                                  | Extent index

5:                  LSL.L     #2,%D2
                    MOVE.L    (%A0,%D2.W),%A1                         | Look for the matching extent
                    LSR.L     #2,%D2

                    MOVE.B    X_HIGH_OFFSET(%A1),%D0                  | Get the extent number from the extent
                    LSL.W     #8,%D0
                    ADD.B     X_LOW_OFFSET(%A1),%D0
                    CMP.W     %D0,%D1
                    BEQ       6f                                      | Match

                    ADDQ.L    #1,%D2
                    CMP.L     %D2,%D4                                 | Check if all extents have been scanned
                    BNE       5b                                      | Check the next extent

                    MOVE.B    #2,%D0                                  | Error, extent not found, return 2
                    BNE       10f

6:                  CLR.W     %D7
                    MOVE.B    RC_OFFSET(%A1),%D7                      | Add to the record count
                    ADD.W     %D7,recordCount

7:                  MOVE.W    #0,%D6                                  | 8 blocks per extent

8:                  MOVE.B    BLOCK_0_HI_OFFSET(%A1,%D6.W),%D7        | Get the block number
                    LSL.W     #8,%D7
                    ADD.B     BLOCK_0_LO_OFFSET(%A1,%D6.W),%D7
                    BEQ       9f                                      | Skip zeros
                    MOVE.W    %D7,(%A3)+                              | Move the block to the FCB block array
                    ADDQ      #1,blockCount                           | Increment the FCB block count

9:                  ADDQ.W    #2,%D6                                  | Increment by two bytes
                    CMPI.W    #0x10,%D6                               | 16 bytes, 8 words
                    BNE       8b

                    ADDQ.W    #1,%D1                                  | Increment sequence number
                    CMP.W     %D1,%D4                                 | Check if all extents have been processed
                    BNE       4b

                    MOVE.B    #0,%D0                                  | Success return 0
10:                 RTS

*-----------------------------------------------------------------------------------------------------
* Format the filename in 11 uppercase characters, CP/M directory format
*-----------------------------------------------------------------------------------------------------
formatName:         LINK      %FP,#0
                    MOVEM.L   %A0-%A2/%D0-%D2,-(%SP)

                    MOVE.L    8(%FP),%A0                              | Source pointer
                    LEA       fileName,%A2                            | Target pointer
                    MOVE.W    #0,%D0                                  | Source index
                    MOVE.W    #0,%D2                                  | Target index

1:                  MOVE.B    (%A0,%D0.W),%D1                         | Get the next character
                    ADDQ.B    #1,%D0                                  | Increment source index

                    CMPI.B    #'.',%D1
                    BNE       3f

2:                  CMPI.B    #8,%D2                                  | Pad target with spaces till 8 characters
                    BEQ       1b
                    MOVE.B    #' ',(%A2,%D2.W)
                    ADDI.B    #1,%D2
                    BRA       2b


3:                  CMPI.B    #0x00,%D1                               | Check for terminating null character
                    BNE       5f

4:                  CMPI.B    #11,%D2
                    BEQ       6f
                    MOVE.B    #' ',(%A2,%D2.W)
                    ADDQ.B    #1,%D2
                    BRA       4b

5:                  BSR       toUpperChar                             | Convert to upper case
                    MOVE.B    %D1,(%A2,%D2.W)                         | Move to target
                    ADDQ.B    #1,%D2                                  | Increment target index

                    CMPI.B    #11,%D2                                 | Finish at 11 target characters
                    BNE       1b

6:                  MOVEM.L   (%SP)+,%A0-%A2/%D0-%D2
                    UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
                    .bss

                    .global   blockArray,blockCount,recordCount

maxFileBlocks       =         256
maxFileExtents      =         maxFileBlocks / 8
extentsArrayBytes   =         maxFileExtents * 2                      | (extent is word)

fileControlBlock:
name:               ds.l      1
recordCount:        ds.w      1
lastRecordSize:     ds.w      1
blockCount:         ds.w      1
blockArray:         ds.w      maxFileBlocks                           | 256 * 2k blocks = max 512k byte file
partitionOffset:    ds.l      1                                       | Offset to the start of the partition

nextBlockIndex:     ds.w      1                                       | Block array index for the current block
offsetIntoBlock:    ds.w      1                                       | Offset into current block
offsetIntoFile:     ds.w      1                                       | Offset into file

blockBuffer:        ds.l      1                                       | Max size #DEF_DD_BLOCK_SIZE
blockBufferLen:     ds.w                                              | Total number of bytes in the buffer, may be less than #DEF_DD_BLOCK_SIZE for the last block

fileName:           ds.b      10

*---------------------------------------------------------------------------------------------------------
                    .section  .rodata.strings
                    .align(2)

strDebugFound:      .asciz    "\r\nMatched extent "


