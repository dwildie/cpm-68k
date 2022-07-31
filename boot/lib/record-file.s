                    .include  "include/macros.i"
                    .include  "include/ascii.i"

                    .global   loadRecordFile
                    .global   processCount,processHeader,processData  | ********* DEBUG

MAX_REC_SIZE        =         0x100
MAX_DATA_SIZE       =         0x80

*-----------------------------------------------------------------------------------------------------
                    .data
                    .align    2
dataRecordCount:    .word     0

*-----------------------------------------------------------------------------------------------------
                    .text

*-----------------------------------------------------------------------------------------------------
* loadRecordFile(*fileName)
* Read the specified file from the disk and load into memory
* Return: 0 success
*         1 file not found
*-----------------------------------------------------------------------------------------------------
loadRecordFile:     LINK      %FP,#0
                    MOVEM.L   %D1-%D7/%A0-%A7,-(%SP)

                    MOVE.L    8(%FP),-(%SP)
                    BSR       fOpen
                    ADDQ.L    #4,%SP                                  | Clean up stack
                    BNE       3f                                      | Error, could not open file

                    CLR.W     dataRecordCount
1:                  BSR       readRecord                              | Read every record in the file
                    BEQ       1b

2:                  CMPI.B    #1,%D0                                  | 1 is end of file, so return 0
                    BNE       3f
                    MOVE.B    #0,%D0

3:                  MOVEM.L   (%SP)+,%D1-%D7/%A0-%A7
                    UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* Read one record from the file, validate and process
*-----------------------------------------------------------------------------------------------------
readRecord:         LINK      %FP,#-(MAX_DATA_SIZE+MAX_REC_SIZE)

                    LEA       -(MAX_DATA_SIZE+MAX_REC_SIZE)(%FP),%A1  | Ascii record buffer
                    LEA       -MAX_REC_SIZE(%FP),%A2                  | Data buffer

1:                  MOVE.L    %A1,-(%SP)                              | Skip any leading CR or LF chars
                    MOVE.W    #1,-(%SP)
                    BSR       fRead
                    ADDQ.L    #6,%SP
                    BEQ       eof                                     | No more chars ?, must be end of file

                    CMPI.L    #0xFFFFFFFF,%D0                         | FAT file will return -1
                    BEQ       eof

                    CMPI.B    #CTRLZ,(%A1)                            | Ctrl-Z = end of file
                    BEQ       eof
                    CMPI.B    #0,(%A1)                                | Null = end of file
                    BEQ       eof
                    CMPI.B    #CR,(%A1)
                    BEQ       1b
                    CMPI.B    #LF,(%A1)
                    BEQ       1b

                    CMPI.B    #'S',(%A1)                              | First char must be an 'S'
                    BNE       errUnexpectedChar

                    CLR.B     %D4                                     | Use D4 for the checksum

                    MOVE.L    %A1,-(%SP)                              | Read next three chars, type + size
                    MOVE.W    #3,-(%SP)
                    BSR       fRead
                    ADDQ.L    #6,%SP
                    CMPI.B    #3,%D0                                  | Check that we got three chars
                    BNE       errUnexpectedEOF

                    MOVE.B    (%A1),%D5                               | Record type

                    PEA       1(%A1)                                  | Convert the size to a byte value
                    BSR       asciiToByte
                    ADDQ.L    #4,%SP

                    EXT.W     %D0                                     | To word
                    ADD.B     %D0,%D4                                 | Size is included in the checksum

                    MOVE.W    %D0,%D2                                 | Save byte count in %D2
                    MOVE.W    %D0,%D3                                 | Remaining char count Which is twice the byte count
                    LSL.W     #1,%D3

                    CMPI.B    #'2',%D5                                | A S2 record has a three byte (24bit) address
                    BNE       6f                                      | This would prevent 16bit reads on the hex data
                    MOVE.B    #0x00,(%A2)+                            | Insert a null byte to preserve the 16 bit alignment

6:                  MOVE.L    %A1,-(%SP)                              | Read remaining chars, address + data + checksum
                    MOVE.W    %D3,-(%SP)
                    BSR       fRead
                    ADDQ.L    #6,%SP
                    CMP.B     %D3,%D0                                 | Check that we got all the chars
                    BNE       errUnexpectedEOF

                    MOVE.W    %D2,%D3                                 | Use D3 as the loop counter
                    SUBI.W    #2,%D3                                  | Exclude the checksum, less one for DBRA

2:                  PEA       (%A1)                                   | Convert each ascii pair to byte value and store in data buffer
                    BSR       asciiToByte
                    ADDQ.L    #4,%SP
                    ADD.B     %D0,%D4                                 | Add to the checksum
                    MOVE.B    %D0,(%A2)+                              | Move to the data buffer
                    ADD.L     #2,%A1
                    DBRA      %D3,2b

                    PEA       (%A1)                                   | Get the checksum
                    BSR       asciiToByte                             | The actual checksum is in %D0
                    ADDQ.L    #4,%SP
                    NOT.B     %D4                                     | Calculated checksum is in %D4
                    CMP.B     %D0,%D4                                 | Must be the same
                    BNE       errChecksum

                    SUBQ.W    #1,%D2                                  | Call the relevant subroutine to process the record

                    CMPI.B    #'0',%D5                                | S0 Header record
                    BNE       3f
                    PEA       -MAX_REC_SIZE(%FP)                      | Data buffer
                    MOVE.W    %D2,-(%SP)                              | Data size
                    BSR       processHeader
                    ADDQ.L    #6,%SP
                    BRA       9f

3:                  CMPI.B    #'3',%D5                                | S1,S2,S3 Data records
                    BGT       4f
                    PEA       -MAX_REC_SIZE(%FP)                      | Data buffer
                    MOVE.W    %D2,-(%SP)                              | Data size
                    MOVE.W    %D5,-(%SP)                              | Record type
                    BSR       processData
                    ADDQ.L    #8,%SP
                    BRA       9f

4:                  CMPI.B    #'4',%D5                                | S4 Reserved
                    BEQ       errUnknownType

                    CMPI.B    #'6',%D5                                | S5,S6 Count record
                    BGT       5f
                    PEA       -MAX_REC_SIZE(%FP)                      | Data buffer
                    MOVE.W    %D2,-(%SP)                              | Data size
                    MOVE.W    %D5,-(%SP)                              | Record type
                    BSR       processCount
                    ADDQ.L    #8,%SP
                    BEQ       9f
                    BRA       errCount                                | Count mismatch, return an error

5:                  CMPI.B    #'9',%D5                                | S9 Start record
                    BGT       errUnknownType
                    PEA       -MAX_REC_SIZE(%FP)                      | Data buffer
                    MOVE.W    %D2,-(%SP)                              | Data size
                    MOVE.W    %D5,-(%SP)                              | Record type
                    BSR       processStart
                    ADDQ.L    #8,%SP
                    BRA       eof

9:                  MOVE.B    #0,%D0                                  | Return SUCCESS
                    BRA       ret

eof:                MOVE.B    #1,%D0                                  | Return 1 end of file
                    BRA       ret

errUnexpectedChar:  PUTS      strExpectedS                            | Error, unexpected character
                    MOVE.B    (%A1),%D0
                    BSR       writeHexByte
                    BSR       newLine
                    MOVE.B    #2,%D0                                  | Return error 2
                    BRA       ret

errUnexpectedEOF:   PUTS      strUnexpectedEOF                        | Unexpected end of file
                    MOVE.B    #3,%D0                                  | Return error 3
                    BRA       ret

errChecksum:        PUTS      strChecksum1
                    BSR       writeHexByte
                    PUTS      strChecksum2
                    MOVE.B    %D4,%D0
                    BSR       writeHexByte
                    BSR       newLine
                    MOVE.B    #4,%D0                                  | Return error 4
                    BRA       ret

errUnknownType:     PUTS      strUnknownType
                    MOVE.B    %D5,%D0
                    BSR       writeHexByte
                    BSR       newLine
                    MOVE.B    #5,%D0                                  | Return error 5
                    BRA       ret

errCount:           MOVE.B    #6,%D0
                    RTS

ret:                UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* processHeader(word size, *data)
* Process a header record
*-----------------------------------------------------------------------------------------------------
processHeader:      LINK      %FP,#0
                    MOVEM.L   %D1/%A1,-(%SP)

                    MOVE.W    0x08(%FP),%D1                           | Number of data bytes
                    MOVE.L    0x0A(%FP),%A1                           | Buffer address

                    TST.W     %D1                                     | Skip if no chars
                    BEQ       3f

                    PUTS      strHeader

                    BRA       2f                                      | start at bottom of loop
1:                  MOVE.B    (%A1)+,%D0
                    BEQ       2f
                    BSR       writeCh
2:                  DBRA      %D1,1b

3:                  PUTS      strReading

                    MOVEM.L   (%SP)+,%D1/%A1
                    UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* Process a data record
*-----------------------------------------------------------------------------------------------------
processData:        LINK      %FP,#0

                    MOVE.W    0x08(%FP),%D0                           | Record type
                    MOVE.W    0x0A(%FP),%D1                           | Number of data bytes
                    MOVE.L    0x0C(%FP),%A1                           | Buffer address

                    ADDQ.W    #1,dataRecordCount                      | Increment the data record count, used to validate S5 or S6

                    CLR.L     %D2                                     | Use D2 for the address

                    CMPI.B    #'3',%D0                                | S3 is a 32 bit address
                    BNE       1f
                    MOVE.W    (%A1)+,%D2                              | Upper word
                    SWAP      %D2
                    SUBQ.W    #2,%D1                                  | Decrement byte count by 2
                    BRA       2f

1:                  CMPI.B    #'2',%D0                                | S2 is a 24 bit address, padded with a null upper byte to prerve 16bit alignment
                    BNE       2f
                    MOVE.W    (%A1)+,%D2                              | null upper byte and lower byte of upper word
                    SWAP      %D2
                    SUBQ.W    #1,%D1                                  | Decrement byte count by 1, the padding byte is not counted

2:                  MOVE.W    (%A1)+,%D2                              | S1,S2 & S3, Lower word
                    SUBQ.W    #2,%D1                                  | Decrement byte count by 2

                    SUBQ.W    #1,%D1                                  | Byte count, Less one for DBRA
                    MOVE.L    %D2,%A2                                 | Target address

                                                                      | TODO Update to 16 or 32 bit transfer
3:                  MOVE.B    (%A1)+,(%A2)+                           | Transfer each byte into memory
                    DBRA      %D1,3b

                    ANDI.L    #0x7FF,%D2
                    BNE       4f
                    PUTCH     #'*'

4:                  UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* Process a count record
*-----------------------------------------------------------------------------------------------------
processCount:       LINK      %FP,#0

                    MOVE.W    0x08(%FP),%D0                           | Record type
                    MOVE.W    0x0A(%FP),%D1                           | Number of data bytes
                    MOVE.L    0x0C(%FP),%A1                           | Buffer address

                    CLR.L     %D2

                    CMPI.B    #'6',%D0
                    BNE       1f

                    MOVE.B    (%A1)+,%D2                              | 24bit value, read lower byte of upper word
                    SWAP      %D2

1:                  MOVE.W    (%A1),%D2                               | 16bit value
                    MOVE.W    dataRecordCount,%D3
                    CMP.W     %D2,%D3
                    BEQ       2f

                    PUTS      strCountError1
                    MOVE.W    %D3,%D0
                    BSR       writeHexWord
                    PUTS      strCountError2
                    MOVE.W    %D2,%D0
                    BSR       writeHexWord
                    BSR       newLine
                    MOVE.B    #1,%D0
                    BRA       3f

2:                  PUTS      strCount1
                    MOVE.W    %D3,%D0
                    BSR       writeDecimalWord
                    PUTS      strCount2
                    MOVE.B    #0,%D0

3:                  UNLK      %FP
                    RTS

*-----------------------------------------------------------------------------------------------------
* Process a start record
*-----------------------------------------------------------------------------------------------------
processStart:       LINK      %FP,#0

                    BSR       fClose                                  | Close the file

                    MOVE.W    0x08(%FP),%D0                           | Record type
                    MOVE.W    0x0A(%FP),%D1                           | Number of data bytes
                    MOVE.L    0x0C(%FP),%A1                           | Buffer address

                    CLR.L     %D2                                     | Will hold the start address

                    CMPI.B    #'7',%D0                                | S7 has 32bit address
                    BNE       1f
                    MOVE.W    (%A1)+,%D2                              | Read high word
                    SWAP      %D2
                    BRA       2f

1:                  CMPI.B    #'8',%D0                                | S8 has 24bit address
                    BNE       2f
                    MOVE.B    (%A1)+,%D2                              | Lower byte of upper word
                    SWAP      %D2
                    MOVE.B    (%A1)+,%D2                              | Upper byte of lower word
                    LSL.W     #8,%D2
                    MOVE.B    (%A1)+,%D2                              | Lower byte of lower word

                    BRA       3f

2:                  MOVE.W    (%A1),%D2                               | Lower word for S7,S8 & S9

3:                  PUTS      strStartAddress                         | Display the start address and prompt
                    MOVE.L    %D2,%D0
                    BSR       writeHexLong
                    BSR       newLine
*                    PUTS      strProceed
*
*                    BSR       readCh                                  | Get user response
*                    MOVE.B    %D0,%D1
*                    BSR       toUpperChar
*                    CMPI.B    #'Y',%D1
*                    BNE       4f
*
*                    PUTS      strBooting

                    MOVE.L    %D2,%A0
*boot:               JSR       (%A0)                                   | Good luck!

4:                  UNLK      %FP
                    RTS

*---------------------------------------------------------------------------------------------------------
                    .section  .rodata.strings
                    .align(2)

strUnknownType:     .asciz    "\r\nUnknown record type "
strExpectedS:       .asciz    "\r\nExpected the record to start with S, found 0x"
strUnexpectedEOF:   .asciz    "\r\nUnexpected end of file\r\n"
strChecksum1:       .asciz    "\r\nRead checksum 0x"
strChecksum2:       .asciz    " does not equal calculated checksum 0x"
strHeader:          .asciz    "\r\nFile header: "
strReading:         .asciz    "\r\nReading: "
strCount1:          .asciz    "\r\nRead "
strCount2:          .asciz    " data records\r\n"
strCountError1:     .asciz    "\r\nCount error, expected 0x"
strCountError2:     .asciz    " read %0x\r\n"
strStartAddress:    .asciz    "\r\nStart address: 0x"
strProceed:         .asciz    "Proceed with boot (y/N)? "
strBooting:         .asciz    "\r\nBooting ...\r\n"


