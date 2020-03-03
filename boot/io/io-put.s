                    .include  "include/macros.i"
                    .include  "include/ascii.i"

                    .text
                    .global   newLine,writeDecimalWord,writeHexLong,writeHexWord,writeHexByte,writeHexDigit,PUT_BITB

*-----------------------------------------------------------------------------------------------------

*-----------------------------------------------------------------------------------------------------
* Output a CR/LF
*-----------------------------------------------------------------------------------------------------
newLine:            MOVE.L    %D1,-(%SP)
                    PUTCH     #CR                           | Send CR/LF to CRT
                    PUTCH     #LF
                    MOVE.L    (%SP)+,%D1
                    RTS

*-----------------------------------------------------------------------------------------------------
* Display the %D0.W value as an unsigned decimal number - padded with spaces
*-----------------------------------------------------------------------------------------------------
writeDecimalWord:   MOVEM.L   %D0-%D3,-(%SP)
                    CLR.L     %D1
                    MOVE.W    %D0,%D1

                    BNE       1f                            | If the number is zero, display it and return
                    PUTCH     #'0'
                    BRA       5f

1:                  MOVE.L    #10000,%D3                    | Initial divisor
                    CLR.L     %D2                           | Show zero flag

2:                  DIVU.W    %D3,%D1
                    MOVE.W    %D1,%D0                       | Get quotient
                    BNE       3f                            | If zero, check if it should be displayed
                    TST       %D2
                    BEQ       6f                            | Display a leading zero as a space
3:                  MOVEQ     #1,%D2                        | Set display zero flag
                    ADDI.B    #'0',%D0                      | Display the digit
                    BSR       writeCh
                    BRA       4f

6:                  PUTCH     #' '

4:                  CLR.W     %D1                           | Clear quotient
                    SWAP      %D1                           | get remainder in lower word
                    DIVU.W    #10,%D3                       | DIVISOR / 10
                    BNE       2b

5:                  MOVEM.L   (%SP)+,%D0-%D3
                    RTS

*-----------------------------------------------------------------------------------------------------
* Display the lowest nibble of %D0 as a single hex-digit
*-----------------------------------------------------------------------------------------------------
writeHexDigit:      MOVEM.L   %D0-%D1,-(%SP)

                    ANDI.B    #0x0F,%D0
                    CMPI.B    #0X0A,%D0
                    BLT       1f
                    ADDI.B    #'A'-'0'-0x0A,%D0
1:                  ADDI.B    #'0',%D0
                    BSR       writeCh

                    MOVEM.L   (%SP)+,%D0-%D1
                    RTS

*-----------------------------------------------------------------------------------------------------
* Display the lowest byte of %D0 as two hex-digits
*-----------------------------------------------------------------------------------------------------
writeHexByte:       ROL.B     #4,%D0
                    BSR       writeHexDigit                 | High nibble
                    ROL.B     #4,%D0
                    BSR       writeHexDigit                 | Low nibble
                    RTS

*-----------------------------------------------------------------------------------------------------
* Display the lowest word of %D0 as four hex-digits
*-----------------------------------------------------------------------------------------------------
writeHexWord:       ROL.W     #8,%D0
                    BSR       writeHexByte                  | High byte
                    ROL.W     #8,%D0
                    BSR       writeHexByte                  | Low byte
                    RTS

*-----------------------------------------------------------------------------------------------------
* Display %D0 as eight hex-digits
*-----------------------------------------------------------------------------------------------------
writeHexLong:       SWAP      %D0
                    BSR       writeHexWord                  | High word
                    SWAP      %D0
                    BSR       writeHexWord                  | Low word
                    RTS

*-----------------------------------------------------------------------------------------------------
* Display the lowest byte of %D0 as bits
*-----------------------------------------------------------------------------------------------------
PUT_BITB:           MOVEM.L   %D0-%D3,-(%SP)                | Save %D2 & %D3
                    MOVE.B    #7,%D3                        | Bit indicator (7,6,5...0)
                    MOVE.B    #8,%D2                        | Bit count

1:                  BTST      %D3,%D6
                    BEQ       SHOW_0
                    MOVE.B    #'1',%D0
                    BSR       writeCh
                    BRA       NEXT_BIT
SHOW_0:             MOVE.B    #'0',%D0
                    BSR       writeCh
NEXT_BIT:           SUBQ.B    #1,%D3
                    SUBQ.B    #1,%D2                        | 8 bits total
                    BNE       1b

                    MOVEM.L   (%SP)+,%D0-%D3                | Restore registers
                    RTS
