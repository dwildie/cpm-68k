                    .include  "include/macros.i"
                    .include  "include/ascii.i"

                    .text
                    .global   memDump
                    .global   memCmp
                    .global   memClr
                    .global   memByteTest
                    .global   memDWordTest

*-----------------------------------------------------------------------------------------------------
* Compare two memory regions %A0 & %A1 of length %D0 bytes. %D0 will return 0 if identical, otherwise, 1
*-----------------------------------------------------------------------------------------------------
memCmp:             MOVEM.L   %A0-%A1,-(%SP)

1:                  TST.L     %D0                                     | Check if we are done
                    BNE       2f                                      | No, Check next byte

                    MOVE.L    #0,%D0                                  | Yes, set D0 to zero and return 
                    BRA       3f

2:                  SUBQ.L    #1,%D0
                    CMP.B     (%A0)+,(%A1)+
                    BEQ       1b                                      | Equal, check next byte

                    MOVE.L    #1,%D0

3:                  MOVEM.L   (%SP)+,%A0-%A1
                    RTS

*---------------------------------------------------------------------------------------------------------
* memClr(*buffer, word length)
* Clear the memory
*---------------------------------------------------------------------------------------------------------
memClr:             LINK      %FP,#0
                    MOVEM.L   %D0/%A0,-(%SP)

                    MOVE.W    0x0C(%FP),%D0
                    MOVE.L    0x08(%FP),%A0

                    BRA       2f
1:                  MOVE.B    #0,(%A0,%D0.W)
2:                  DBRA      %D0,1b

                    MOVEM.L   (%SP)+,%D0/%A0
                    UNLK      %FP
                    RTS

*-------------------------------------------------------------------------
* Display %D0 bytes in RAM starting at %A0, %A1 is the displayed address
*-----------------------------------------------------------------------------------------------------
memDump:            MOVEM.L   %D1-%D4/%A0-%A1,-(%SP)
                    MOVE.L    %D0,%D2                                 | Total byte count

1:                  BSR       newLine                                 | New line 

                    MOVE.L    %A1,%D0                                 | Show current address
                    BSR       writeHexLong
                    PUTCH     #' '

                    MOVEQ.L   #0,%D3                                  | Line byte counter

2:                  MOVE.B    (%A0,%D3),%D0                           | Display 16 bytes as hex
                    BSR       writeHexByte
                    PUTCH     #' '

                    ADDQ.B    #1,%D3
                    CMPI.B    #16,%D3                                 | Have we done 16
                    BNE       2b

                    PUTCH     #' '
                    PUTCH     #' '

                    MOVE.L    #0,%D3                                  | Reset line byte counter
3:                  MOVE.B    (%A0,%D3),%D0                           | Display 16 bytes as ascii
                    CMP.B     #' ',%D0
                    BGE       4f                                      | Unprintable show a dot
                    PUTCH     #'.'
                    BRA       6f
4:                  CMP.B     #0x7F,%D0
                    BLT       5f                                      | Unprintable show a dot
                    PUTCH     #'.'
                    BRA       6f

5:                  BSR       writeCh                                 | Display as ascii character

6:                  ADDQ.B    #1,%D3
                    CMPI.B    #16,%D3                                 | Have we done 16
                    BNE       3b

                    ADD.L     #0x10,%A0                               | Increment location pointer by 16
                    ADD.L     #0x10,%A1                               | Increment display address by 16
                    SUBI.L    #0x10,%D2                               | Decrement total count by 16
                    BEQ       7f                                      | Done, exit

                    BRA       1b                                      | Do another line

7:                  BSR       newLine
                    MOVEM.L   (%SP)+,%D1-%D4/%A0-%A1                  | Done, restore regs and return 
                    RTS

          .ifdef              IS_68030
*-------------------------------------------------------------------------
* Test %D0 bytes in RAM starting at %A0
*-----------------------------------------------------------------------------------------------------
memByteTest:        MOVEM.L   %D1-%D5/%A0-%A3,-(%SP)
                    MOVE.L    %D0,%D2                                 | Total byte count
                    MOVE.L    #0,%D4                                  | Error count
                    MOVE.L    #0,%D5                                  | Iteration count

1:                  BSR       newLine                                 | New line 

                    MOVE.B    #0x0,%D0
                    BSR       writeHexByte
                    PUTCH     #' '
                    MOVE.L    %A0,%D0
                    BSR       writeHexLong

                    MOVE.L    #0,%D3                                  | Fill test space with zeros
                    MOVE.L    %A0,%A3
2:                  MOVE.B    #0x0,(%A3)+

                    MOVE.L    %A3,%D0
                    AND.L     #0xFFFF,%D0
                    TST.L     %D0
                    BNE       3f
                    PUTBS     #8
                    MOVE.L    %A3,%D0
                    BSR       writeHexLong

3:                  ADDI.L    #1,%D3
                    CMP.L     %D2,%D3
                    BNE       2b

                    PUTBS     #11
                    MOVE.B    #0x55,%D0
                    BSR       writeHexByte
                    PUTCH     #' '
                    MOVE.L    %A0,%D0
                    BSR       writeHexLong

                    MOVE.L    #0,%D3                                  | Test for zero and write 0x55
                    MOVE.L    %A0,%A3
4:                  MOVE.B    (%A3),%D1
                    CMPI.B    #0x0,%D1
                    BEQ       5f

                    BSR       newLine                                 | Display error
                    MOVE.L    %A3,%D0
                    BSR       writeHexLong
                    PUTS      strExpected
                    MOVE.B    #0x0,%D0
                    BSR       writeHexByte
                    PUTS      strRead
                    MOVE.B    %D1,%D0
                    BSR       writeHexByte
                    BSR       newLine
                    ADDI.L    #1,%D4                                  | Increment error count

5:                  MOVE.B    #0x55,(%A3)+

                    MOVE.L    %A3,%D0
                    AND.L     #0xFFFF,%D0
                    TST.L     %D0
                    BNE       6f
                    PUTBS     #8
                    MOVE.L    %A3,%D0
                    BSR       writeHexLong

6:                  ADDI.L    #1,%D3
                    CMP.L     %D2,%D3
                    BNE       4b

                    PUTBS     #11
                    MOVE.B    #0xaa,%D0
                    BSR       writeHexByte
                    PUTCH     #' '
                    MOVE.L    %A0,%D0
                    BSR       writeHexLong

                    MOVE.L    #0,%D3                                  | Test for 0x55 and write 0xaa
                    MOVE.L    %A0,%A3
4:                  MOVE.B    (%A3),%D1
                    CMPI.B    #0x55,%D1
                    BEQ       5f

                    BSR       newLine                                 | Display error
                    MOVE.L    %A3,%D0
                    BSR       writeHexLong
                    PUTS      strExpected
                    MOVE.B    #0x55,%D0
                    BSR       writeHexByte
                    PUTS      strRead
                    MOVE.B    %D1,%D0
                    BSR       writeHexByte
                    BSR       newLine
                    ADDI.L    #1,%D4                                  | Increment error count

5:                  MOVE.B    #0xaa,(%A3)+

                    MOVE.L    %A3,%D0
                    AND.L     #0xFFFF,%D0
                    TST.L     %D0
                    BNE       6f
                    PUTBS     #8
                    MOVE.L    %A3,%D0
                    BSR       writeHexLong

6:                  ADDI.L    #1,%D3
                    CMP.L     %D2,%D3
                    BNE       4b

                    PUTBS     #11
                    MOVE.B    #0xff,%D0
                    BSR       writeHexByte
                    PUTCH     #' '
                    MOVE.L    %A0,%D0
                    BSR       writeHexLong

                    MOVE.L    #0,%D3                                  | Test for 0xaa and write 0xff
                    MOVE.L    %A0,%A3
4:                  MOVE.B    (%A3),%D1
                    CMPI.B    #0xaa,%D1
                    BEQ       5f

                    BSR       newLine                                 | Display error
                    MOVE.L    %A3,%D0
                    BSR       writeHexLong
                    PUTS      strExpected
                    MOVE.B    #0xaa,%D0
                    BSR       writeHexByte
                    PUTS      strRead
                    MOVE.B    %D1,%D0
                    BSR       writeHexByte
                    BSR       newLine
                    ADDI.L    #1,%D4                                  | Increment error count

5:                  MOVE.B    #0xff,(%A3)+

                    MOVE.L    %A3,%D0
                    AND.L     #0xFFFF,%D0
                    TST.L     %D0
                    BNE       6f
                    PUTBS     #8
                    MOVE.L    %A3,%D0
                    BSR       writeHexLong

6:                  ADDI.L    #1,%D3
                    CMP.L     %D2,%D3
                    BNE       4b

                    MOVE.L    #0,%D3                                  | Test for 0xff
                    MOVE.L    %A0,%A3
4:                  MOVE.B    (%A3),%D1
                    CMPI.B    #0xff,%D1
                    BEQ       5f

                    BSR       newLine                                 | Display error
                    MOVE.L    %A3,%D0
                    BSR       writeHexLong
                    PUTS      strExpected
                    MOVE.B    #0xff,%D0
                    BSR       writeHexByte
                    PUTS      strRead
                    MOVE.B    %D1,%D0
                    BSR       writeHexByte
                    BSR       newLine
                    ADDI.L    #1,%D4                                  | Increment error count

5:                  ADDI.L    #1,%D3

                    MOVE.L    %A3,%D0
                    AND.L     #0xFFFF,%D0
                    TST.L     %D0
                    BNE       6f
                    PUTBS     #8
                    MOVE.L    %A3,%D0
                    BSR       writeHexLong

6:                  CMP.L     %D2,%D3
                    BNE       4b

                    ADDI.L    #1,%D5                                  | Increment iteration count

                    PUTCH     #CR                                     | Display status
                    MOVE.L    %D5,%D0
                    BSR       writeDecimalWord
                    PUTS      strIterations
                    MOVE.L    %D4,%D0
                    BSR       writeDecimalWord
                    PUTS      strErrors

                    BSR       keystat                                 | If not key press, repeat
                    BEQ       1b

                    MOVEM.L   (%SP)+,%D1-%D5/%A0-%A3
                    RTS

*-------------------------------------------------------------------------
* Test %D0 DWords of RAM starting at %A0
*-----------------------------------------------------------------------------------------------------
memDWordTest:       MOVEM.L   %D1-%D5/%A0-%A3,-(%SP)
                    MOVE.L    %D0,%D2                                 | Total byte count
                    MOVE.L    #0,%D4                                  | Error count
                    MOVE.L    #0,%D5                                  | Iteration count

1:                  BSR       newLine                                 | New line 

                    MOVE.L    #0x0,%D0
                    BSR       writeHexLong
                    PUTCH     #' '
                    MOVE.L    %A0,%D0
                    BSR       writeHexLong

                    MOVE.L    #0,%D3                                  | Fill test space with zeros
                    MOVE.L    %A0,%A3
2:                  MOVE.L    #0x0,(%A3)+

                    MOVE.L    %A3,%D0
                    AND.L     #0xFFFC,%D0
                    TST.L     %D0
                    BNE       3f
                    PUTBS     #8
                    MOVE.L    %A3,%D0
                    BSR       writeHexLong

3:                  ADDI.L    #1,%D3
                    CMP.L     %D2,%D3
                    BNE       2b

                    PUTBS     #17
                    MOVE.L    #0x55555555,%D0
                    BSR       writeHexLong
                    PUTCH     #' '
                    MOVE.L    %A0,%D0
                    BSR       writeHexLong

                    MOVE.L    #0,%D3                                  | Test for zero and write 0x55
                    MOVE.L    %A0,%A3
4:                  MOVE.L    (%A3),%D1
                    CMPI.L    #0x0,%D1
                    BEQ       5f

                    BSR       newLine                                 | Display error
                    MOVE.L    %A3,%D0
                    BSR       writeHexLong
                    PUTS      strExpected
                    MOVE.L    #0x0,%D0
                    BSR       writeHexLong
                    PUTS      strRead
                    MOVE.L    %D1,%D0
                    BSR       writeHexLong
                    BSR       newLine
                    ADDI.L    #1,%D4                                  | Increment error count

5:                  MOVE.L    #0x55555555,(%A3)+

                    MOVE.L    %A3,%D0
                    AND.L     #0xFFFC,%D0
                    TST.L     %D0
                    BNE       6f
                    PUTBS     #8
                    MOVE.L    %A3,%D0
                    BSR       writeHexLong

6:                  ADDI.L    #1,%D3
                    CMP.L     %D2,%D3
                    BNE       4b

                    PUTBS     #17
                    MOVE.L    #0xaaaaaaaa,%D0
                    BSR       writeHexLong
                    PUTCH     #' '
                    MOVE.L    %A0,%D0
                    BSR       writeHexLong

                    MOVE.L    #0,%D3                                  | Test for 0x55 and write 0xaa
                    MOVE.L    %A0,%A3
4:                  MOVE.L    (%A3),%D1
                    CMPI.L    #0x55555555,%D1
                    BEQ       5f

                    BSR       newLine                                 | Display error
                    MOVE.L    %A3,%D0
                    BSR       writeHexLong
                    PUTS      strExpected
                    MOVE.L    #0x55555555,%D0
                    BSR       writeHexLong
                    PUTS      strRead
                    MOVE.L    %D1,%D0
                    BSR       writeHexLong
                    BSR       newLine
                    ADDI.L    #1,%D4                                  | Increment error count

5:                  MOVE.L    #0xaaaaaaaa,(%A3)+

                    MOVE.L    %A3,%D0
                    AND.L     #0xFFFC,%D0
                    TST.L     %D0
                    BNE       6f
                    PUTBS     #8
                    MOVE.L    %A3,%D0
                    BSR       writeHexLong

6:                  ADDI.L    #1,%D3
                    CMP.L     %D2,%D3
                    BNE       4b

                    PUTBS     #17
                    MOVE.L    #0xffffffff,%D0
                    BSR       writeHexLong
                    PUTCH     #' '
                    MOVE.L    %A0,%D0
                    BSR       writeHexLong

                    MOVE.L    #0,%D3                                  | Test for 0xaa and write 0xff
                    MOVE.L    %A0,%A3
4:                  MOVE.L    (%A3),%D1
                    CMPI.L    #0xaaaaaaaa,%D1
                    BEQ       5f

                    BSR       newLine                                 | Display error
                    MOVE.L    %A3,%D0
                    BSR       writeHexLong
                    PUTS      strExpected
                    MOVE.L    #0xaaaaaaaa,%D0
                    BSR       writeHexLong
                    PUTS      strRead
                    MOVE.L    %D1,%D0
                    BSR       writeHexLong
                    BSR       newLine
                    ADDI.L    #1,%D4                                  | Increment error count

5:                  MOVE.L    #0xffffffff,(%A3)+

                    MOVE.L    %A3,%D0
                    AND.L     #0xFFFC,%D0
                    TST.L     %D0
                    BNE       6f
                    PUTBS     #8
                    MOVE.L    %A3,%D0
                    BSR       writeHexLong

6:                  ADDI.L    #1,%D3
                    CMP.L     %D2,%D3
                    BNE       4b

                    MOVE.L    #0,%D3                                  | Test for 0xff
                    MOVE.L    %A0,%A3
4:                  MOVE.L    (%A3)+,%D1
                    CMPI.L    #0xffffffff,%D1
                    BEQ       5f

                    BSR       newLine                                 | Display error
                    MOVE.L    %A3,%D0
                    BSR       writeHexLong
                    PUTS      strExpected
                    MOVE.L    #0xffffff,%D0
                    BSR       writeHexLong
                    PUTS      strRead
                    MOVE.L    %D1,%D0
                    BSR       writeHexLong
                    BSR       newLine
                    ADDI.L    #1,%D4                                  | Increment error count

5:                  ADDI.L    #1,%D3

                    MOVE.L    %A3,%D0
                    AND.L     #0xFFFC,%D0
                    TST.L     %D0
                    BNE       6f
                    PUTBS     #8
                    MOVE.L    %A3,%D0
                    BSR       writeHexLong

6:                  CMP.L     %D2,%D3
                    BNE       4b

                    ADDI.L    #1,%D5                                  | Increment iteration count

                    PUTCH     #CR                                     | Display status
                    MOVE.L    %D5,%D0
                    BSR       writeDecimalWord
                    PUTS      strIterations
                    MOVE.L    %D4,%D0
                    BSR       writeDecimalWord
                    PUTS      strErrors

                    BSR       keystat                                 | If not key press, repeat
                    BEQ       1b

                    MOVEM.L   (%SP)+,%D1-%D5/%A0-%A3
                    RTS
          .endif

*---------------------------------------------------------------------------------------------------------
                    .section  .rodata.strings
                    .align(2)

strPressAnyKey:     .asciz    "\r\nPress any key to continue..."
strExpected:        .asciz    " expected "
strRead:            .asciz    " read "
strIterations:      .asciz    " iterations, "
strErrors:          .asciz    " errors"

