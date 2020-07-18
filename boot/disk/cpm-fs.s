                    .include  "include/macros.i"
                    .include  "include/disk-def.i"
                    .include  "include/cpm-fs.i"
                    .include  "include/ide.i"

                    .text
                    .global   listCpmDirectory
                    .global   readCpmDirectory
                    .global   isValidName                             | ***DEBUG

*-----------------------------------------------------------------------------------------------------
* Display the directory listing for the currently selected drive
* listCpmDirectory(word offset)
*-----------------------------------------------------------------------------------------------------
listCpmDirectory:   LINK      %FP,#0
                    BSR       newLine                                 | Display the header text
                    PUTS      strDirHeading
                    BSR       writeDrive
                    BSR       newLine
                    BSR       newLine

                    LEA       __free_ram_start__,%A0
                    MOVE.L    %A0,-(%SP)
                    MOVE.L    0x8(%FP),-(%SP)
                    BSR       readCpmDirectory                        | Read the directory starting at offset, %D0 return  the number of entries
                    ADD       #8,%SP
                    BGT       1f                                      | Succeeded
                    BRA       8f                                      | Failed, return

1:                  MOVE.L    %A0,%A2                                 | Read each 32 byte directory entry
                    MOVE.W    %D0,%D4

readEntry:          MOVE.B    USER_NUMBER_OFFSET(%A2),%D0             | User number
                    CMPI.B    #0,%D0                                  | User number must be in the range 0 - 15
                    BLT       7f                                      | Skip this entry
                    CMPI.B    #0x0F,%D0
                    BGT       7f                                      | Skip this entry

                    MOVE.B    X_HIGH_OFFSET(%A2),%D2                  | High extent byte
                    LSL.W     #8,%D2
                    MOVE.B    X_LOW_OFFSET(%A2),%D2                   | Low extent byte
                    TST.W     %D2
                    BNE       7f                                      | Skip if the extent number is not zero

zzzz:               MOVE.L    %A2,%A3                                 | Debug
                    ADD.L     #FILE_NAME_OFFSET,%A3                   | Debug
                    MOVEM.L   %A3,-(%SP)                              | Debug
*                    PEA       FILE_NAME_OFFSET(%A2)                   | Check that this is a valid filename
                    BSR       isValidName
                    ADD.L     #4,%SP
                    BNE       7f                                      | No, skip

                    ADDI      #'0',%D0                                | Output the user number
                    BSR       writeCh
                    PUTCH     #':'

                    MOVE.B    #0,%D7                                  | Count ouput chars for alignment
                    MOVE.L    #0,%D2                                  | File name
1:                  MOVE.B    FILE_NAME_OFFSET(%A2,%D2),%D0
                    CMPI.B    #' ',%D0                                | Strip whitespace
                    BEQ       2f
                    BSR       writeCh
                    ADDQ.B    #1,%D7
2:                  ADDQ.B    #1,%D2
                    CMPI.B    #FILE_NAME_LEN,%D2
                    BNE       1b

                    PUTCH     #'.'
                    ADDQ.B    #1,%D7

                    MOVE.L    #0,%D2                                  | File type
3:                  MOVE.B    FILE_TYPE_OFFSET(%A2,%D2),%D0
                    CMPI.B    #' ',%D0                                | Strip whitespace
                    BEQ       4f
                    BSR       writeCh
                    ADDQ.B    #1,%D7

4:                  ADDQ.B    #1,%D2
                    CMPI.B    #FILE_TYPE_LEN,%D2
                    BNE       3b

6:                  PUTCH     #' '                                    | Add spaces to align size column
                    ADDQ.B    #1,%D7
                    CMPI.B    #14,%D7
                    BLE       6b

                    MOVE.L    %A2,%A3                                 | Read the record and byte counts for this entry
                    ADD.L     #FILE_NAME_OFFSET,%A3
                    BSR       readExtents

                    MOVE.W    %D0,%D3                                 | Move RC to %D3
                    SWAP      %D0                                     | BC to lower word
                    TST.W     %D0                                     | If BC is not zero subtract one from RC
                    BEQ       5f
                    SUBI.W    #1,%D3                                  | Size = (RC - 1) * 128 + BC
5:                  MULU.W    #0x80,%D3

                    AND.L     #0xFFFF,%D0
                    ADD.L     %D0,%D3

                    MOVE.L    %D3,%D0                                 | Display as decimal
                    BSR       writeDecimalWord

                    BSR       newLine

7:                  ADD.L     #DEF_DD_DIR_ENTRY,%A2
                    SUBI.W    #1,%D4
                    BNE       readEntry

8:                  UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* isValidName(char* name) return 0 = success, 1 = error
*-----------------------------------------------------------------------------------------------------
isValidName:        LINK      %FP,#0
                    MOVEM.L   %D0-%D1/%A0,-(%SP)

                    MOVE.L    0x08(%FP),%A0                           | Address of name
                    MOVE.W    #11,%D1                                 | Length of name
                    BRA       2f

1:                  MOVE.B    (%A0,%D1.W),%D0
                    BSR       isValidChar
                    BNE       3f
2:                  DBRA      %D1,1b

                    MOVE.W    #0,%D0                                  | Name is valid, return 0 = success
                    BRA       4f

3:                  MOVE.W    #1,%D0                                  | Name is invalid, return 1 = error

4:                  MOVEM.L   (%SP)+,%D0-%D1/%A0
                    UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* Return 0 if %D0.B contains a valid name char, otherwise, return 1.
*-----------------------------------------------------------------------------------------------------
isValidChar:        CMPI.B    #' ',%D0
                    BLT       1f
                    CMPI.B    #0x7E,%D0
                    BGT       1f
                    MOVE.W    #0,%D0                                  | Char is valid, return 0 = success
                    BRA       2f
1:                  MOVE.W    #1,%D0                                  | Char is invalid, return 1 = error
2:                  RTS

*-----------------------------------------------------------------------------------------------------
* Read the directory starting at offset into the buffer return number of entries in %D0
* readCpmDirectory(long offset, byte* buffer)
*-----------------------------------------------------------------------------------------------------
readCpmDirectory:   LINK      %FP,#0
                    MOVEM.L   %D2-%D6/%A0-%A1,-(%SP)

                    MOVE.W    #DEF_DD_DIR_START,%D0
                    EXT.L     %D0                                     | To long
                    LSR.L     #SECT_HDD_CPM_SHIFT,%D0                 | From CPM sectors to HDD sectors
                    ADD.L     0x08(%FP),%D0
                    BSR       setLBA                                  | Seek to start of directory

                    MOVE.W    #DEF_DD_DIR_SECS,%D0                    | Calculate the number of ide sectors to be read
                    EXT.L     %D0
                    LSR.L     #SECT_HDD_CPM_SHIFT,%D0                 | From CPM sectors to HDD sectors

                    MOVE.L    0x0C(%FP),%A2

                    BSR       readSectors
                    BEQ       1f

                    MOVE.W    #-1,%D0                                 | Error
                    BRA       2f

1:                  MOVE.W    #DEF_DD_MAX_DIRS,%D0                    | Succeeded, return number of entries read

2:                  MOVEM.L   (%SP)+,%D2-%D6/%A0-%A1
                    UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* Read the extents for the file name pointed to by %A3
* Returns the record count in %D0 low word and the last extent byte count in %D0 high word
*-----------------------------------------------------------------------------------------------------
readExtents:        MOVEM.L   %D2-%D6/%A0-%A1,-(%SP)
                    MOVE.L    #0,%D3                                  | Record count
                    MOVE.L    #0,%D4                                  | Byte count
                    LEA       __free_ram_start__,%A4                  | Start at the first directory entry
                    MOVE.W    #DEF_DD_MAX_DIRS,%D2                    | Count of directory entries

readExtent:         MOVE.L    %A3,%A0                                 | Compare the names
                    LEA       FILE_NAME_OFFSET(%A4),%A1
                    MOVE.L    #11,%D0
                    BSR       memCmp
                    TST.B     %D0                                     | Check the result
                    BNE       endExtent                               | Do not match

                    MOVE.L    #0,%D6                                  | Names match, add to the record count
                    MOVE.B    RC_OFFSET(%A4),%D6
                    ADD.L     %D6,%D3

                    TST.B     BC_OFFSET(%A4)                          | If the byte count is not zero, copy it
                    BEQ       endExtent
                    MOVE.B    BC_OFFSET(%A4),%D4

endExtent:          ADD.L     #DEF_DD_DIR_ENTRY,%A4                   | Move to the next entry
                    SUBQ.W    #1,%D2                                  | Decrement count
                    BNE       readExtent

                    MOVE.W    %D4,%D0
                    SWAP      %D1
                    MOVE      %D3,%D0

                    MOVEM.L   (%SP)+,%D2-%D6/%A0-%A1
                    RTS

*---------------------------------------------------------------------------------------------------------
                    .section  .rodata.strings
                    .align(2)

strDirHeading:      .asciz    "CP/M directory listing for drive "
