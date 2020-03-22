                    .include  "include/macros.i"

                    .text
                    .global   memDump
                    .global   memCmp
                    .global   memClr

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
1:                  MOVE.B    #0,(%A0,%D0)
2:                  DBRA      %D0,1b

                    MOVEM.L   (%SP)+,%D0/%A0
                    UNLK      %FP
                    RTS

*-------------------------------------------------------------------------
* Display %D0 bytes in RAM starting at %A0, %A1 is the displayed address
*-----------------------------------------------------------------------------------------------------
memDump:            MOVEM.L   %D1-%D4/%A0-%A1,-(%SP)
                    MOVE.L    %D0,%D2                                 | Total byte count
                    MOVE.B    #0,%D4                                  | Line counter

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

                    ADDI.B    #1,%D4                                  | Increment line counter
                    ANDI.B    #0x0f,%D4                               | Modulo 16
                    BNE       1b                                      | Do another line

                    PUTS      strPressAnyKey                          | Prompt for a key press before continuing
                    BSR       readCh
                    BRA       1b                                      | Do another line

7:                  BSR       newLine
                    MOVEM.L   (%SP)+,%D1-%D4/%A0-%A1                  | Done, restore regs and return 
                    RTS

*---------------------------------------------------------------------------------------------------------
                    .section  .rodata.strings
                    .align(2)

strPressAnyKey:     .asciz    "\r\nPress any key to continue..."
