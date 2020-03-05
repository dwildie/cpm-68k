                    .include  "include/macros.i"
                    .include  "include/disk-def.i"
                    .include  "include/cpm-fs.i"
                    .include  "include/ide.i"

                    .text
                    .global   cpmDirectory
                    .global   readDirectory

*-----------------------------------------------------------------------------------------------------
* Display the directory listing for the currently selected drive
*-----------------------------------------------------------------------------------------------------
cpmDirectory:       BSR       newLine                       | Display the header text
                    PUTS      strDirHeading
                    BSR       writeDrive
                    BSR       newLine
                    BSR       newLine

                    LEA       __free_ram_start__,%A0
                    BSR       readDirectory                 | Read the directory, %D0 return  the number of entries
                    BGT       1f                            | Succeeded
                    RTS                                     | Failed, return

1:                  MOVE.L    %A0,%A2                       | Read each 32 byte directory entry
                    MOVE.W    %D0,%D4

readEntry:          MOVE.B    USER_NUMBER_OFFSET(%A2),%D0   | User number
                    CMPI.B    #0,%D0                        | User number must be in the range 0 - 15
                    BLT       END_ENTRY                     | Skip this entry
                    CMPI.B    #0x0F,%D0
                    BGT       END_ENTRY                     | Skip this entry

                    MOVE.B    X_HIGH_OFFSET(%A2),%D2        | High extent byte
                    LSL.W     #8,%D2
                    MOVE.B    X_LOW_OFFSET(%A2),%D2         | Low extent byte
                    TST.W     %D2
                    BNE       END_ENTRY                     | Skip if the extent number is not zero

                    ADDI      #'0',%D0
                    BSR       writeCh
                    PUTCH     #':'

                    MOVE.B    #0,%D7                        | Count ouput chars for alignment

                    MOVE.L    #0,%D2                        | File name
1:                  MOVE.B    FILE_NAME_OFFSET(%A2,%D2),%D0
                    CMPI.B    #' ',%D0                      | Strip whitespace
                    BEQ       2f
                    BSR       writeCh
                    ADDQ.B    #1,%D7
2:                  ADDQ.B    #1,%D2
                    CMPI.B    #FILE_NAME_LEN,%D2
                    BNE       1b

                    PUTCH     #'.'
                    ADDQ.B    #1,%D7

                    MOVE.L    #0,%D2                        | File type
3:                  MOVE.B    FILE_TYPE_OFFSET(%A2,%D2),%D0
                    CMPI.B    #' ',%D0                      | Strip whitespace
                    BEQ       4f
                    BSR       writeCh
                    ADDQ.B    #1,%D7

4:                  ADDQ.B    #1,%D2
                    CMPI.B    #FILE_TYPE_LEN,%D2
                    BNE       3b

6:                  PUTCH     #' '                          | Add spaces to align size column
                    ADDQ.B    #1,%D7
                    CMPI.B    #14,%D7
                    BLE       6b

                    MOVE.L    %A2,%A3                       | Read the record and byte counts for this entry
                    ADD.L     #FILE_NAME_OFFSET,%A3
                    BSR       readExtents

                    MOVE.W    %D0,%D3                       | Move RC to %D3
                    SWAP      %D0                           | BC to lower word
                    TST.W     %D0                           | If BC is not zero subtract one from RC
                    BEQ       5f
                    SUBI.W    #1,%D3                        | Size = (RC - 1) * 128 + BC
5:                  MULU.W    #0x80,%D3

                    AND.L     #0xFFFF,%D0
                    ADD.L     %D0,%D3

                    MOVE.L    %D3,%D0                       | Display as decimal
                    BSR       writeDecimalWord

                    BSR       newLine

END_ENTRY:          ADD.L     #DEF_DD_DIR_ENTRY,%A2
                    SUBI.W    #1,%D4
                    BNE       readEntry

                    RTS

*-----------------------------------------------------------------------------------------------------
* Read the directory into the buffer %A0, return number of entries in %D0
*-----------------------------------------------------------------------------------------------------
readDirectory:      MOVEM.L   %D2-%D6/%A0-%A1,-(%SP)

                    MOVE.W    #DEF_DD_DIR_START,%D0
                    ANDI.L    #0xFFFF,%D0                   | #DEF_DD_DIR_START is word, ensure upper word is zero
                    BSR       setLBA                        | Seek to start of directory

                    MOVE.W    #DEF_DD_DIR_SECS,%D0          | Calculate the number of ide sectors to be read
                    MULU.W    #DEF_DD_SEC_SIZE,%D0
                    DIVU.W    #IDE_SEC_SIZE,%D0

                    MOVE.L    %A0,%A2

                    BSR       readSectors
                    BEQ       1f

                    MOVE.W    #-1,%D0                        | Error
                    BRA       2f

1:                  MOVE.W    #DEF_DD_MAX_DIRS,%D0          | Succeeded, return number of entries read

2:                  MOVEM.L   (%SP)+,%D2-%D6/%A0-%A1
                    RTS

*-----------------------------------------------------------------------------------------------------
* Read the extents for the file name pointed to by %A3
* Returns the record count in %D0 low word and the last extent byte count in %D0 high word
*-----------------------------------------------------------------------------------------------------
readExtents:        MOVEM.L   %D2-%D6/%A0-%A1,-(%SP)
                    MOVE.L    #0,%D3                        | Record count
                    MOVE.L    #0,%D4                        | Byte count
                    LEA       __free_ram_start__,%A4        | Start at the first directory entry
                    MOVE.W    #DEF_DD_MAX_DIRS,%D2          | Count of directory entries

readExtent:         MOVE.L    %A3,%A0                       | Compare the names
                    LEA       FILE_NAME_OFFSET(%A4),%A1
                    MOVE.L    #11,%D0
                    BSR       memCmp
                    TST.B     %D0                           | Check the result
                    BNE       endExtent                     | Do not match

                    MOVE.L    #0,%D6                        | Names match, add to the record count
                    MOVE.B    RC_OFFSET(%A4),%D6
                    ADD.L     %D6,%D3

                    TST.B     BC_OFFSET(%A4)                | If the byte count is not zero, copy it
                    BEQ       endExtent
                    MOVE.B    BC_OFFSET(%A4),%D4

endExtent:          ADD.L     #DEF_DD_DIR_ENTRY,%A4         | Move to the next entry
                    SUBQ.W    #1,%D2                        | Decrement count
                    BNE       readExtent

                    MOVE.W    %D4,%D0
                    SWAP      %D1
                    MOVE      %D3,%D0

                    MOVEM.L   (%SP)+,%D2-%D6/%A0-%A1
                    RTS

*---------------------------------------------------------------------------------------------------------
                    .section  .rodata.strings
                    .align(2)

strDirHeading:      .asciz    "Directory listing for drive "
