                    .include  "include/macros.i"
                    .include  "include/ascii.i"

                    .text
                    .global   writeRegs

          .ifdef              IS_68030
*-----------------------------------------------------------------------------------------------------
* Outout the register contents
*-----------------------------------------------------------------------------------------------------
writeRegs:          LINK      %FP,#0
                    MOVEM.L   %D0-%D7/%A0-%A7,-(%SP)

                    PUTS      strD0                                   | Line 1
                    BSR       writeHexLong
                    PUTS      strD4
                    MOVE.L    %D4,%D0
                    BSR       writeHexLong
                    PUTS      strA0
                    MOVE.L    %A0,%D0
                    BSR       writeHexLong
                    PUTS      strA4
                    MOVE.L    %A4,%D0
                    BSR       writeHexLong
                    PUTS      strPC
                    MOVE.L    4(%FP),%D0
                    BSR       writeHexLong

                    PUTS      strD1                                   | Line 2
                    MOVE.L    %D1,%D0
                    BSR       writeHexLong
                    PUTS      strD5
                    MOVE.L    %D5,%D0
                    BSR       writeHexLong
                    PUTS      strA1
                    MOVE.L    %A1,%D0
                    BSR       writeHexLong
                    PUTS      strA5
                    MOVE.L    %A5,%D0
                    BSR       writeHexLong
                    PUTS      strSR
                    MOVE      %SR,%D0
                    BSR       writeHexWord

                    PUTS      strD2                                   | Line 3
                    MOVE.L    %D2,%D0
                    BSR       writeHexLong
                    PUTS      strD6
                    MOVE.L    %D6,%D0
                    BSR       writeHexLong
                    PUTS      strA2
                    MOVE.L    %A2,%D0
                    BSR       writeHexLong
                    PUTS      strA6
                    MOVE.L    (%FP),%D0
                    BSR       writeHexLong
                    PUTS      strUSP
                    MOVE.L    (%FP),%D0
                    BSR       writeHexLong

                    PUTS      strD3                                   | Line 4
                    MOVE.L    %D3,%D0
                    BSR       writeHexLong
                    PUTS      strD7
                    MOVE.L    %D7,%D0
                    BSR       writeHexLong
                    PUTS      strA3
                    MOVE.L    %A3,%D0
                    BSR       writeHexLong
                    PUTS      strA7
                    MOVE.L    %A7,%D0
                    BSR       writeHexLong
                    PUTS      strSSP
                    MOVE.L    %SP,%D0
                    BSR       writeHexLong

                    MOVEM.L   (%SP)+,%D0-%D7/%A0-%A7
                    UNLK      %FP
                    RTS

*---------------------------------------------------------------------------------------------------------
                    .section  .rodata.strings
                    .align(2)

strD0:              .asciz    "\r\nD0: 0x"
strD1:              .asciz    "\r\nD1: 0x"
strD2:              .asciz    "\r\nD2: 0x"
strD3:              .asciz    "\r\nD3: 0x"
strD4:              .asciz    "  D4: 0x"
strD5:              .asciz    "  D5: 0x"
strD6:              .asciz    "  D6: 0x"
strD7:              .asciz    "  D7: 0x"
strA0:              .asciz    "  A0: 0x"
strA1:              .asciz    "  A1: 0x"
strA2:              .asciz    "  A2: 0x"
strA3:              .asciz    "  A3: 0x"
strA4:              .asciz    "  A4: 0x"
strA5:              .asciz    "  A5: 0x"
strA6:              .asciz    "  A6: 0x"
strA7:              .asciz    "  A7: 0x"

strPC:              .asciz    "  PC:  0x"
strSR:              .asciz    "  PC:  0x"
strUSP:             .asciz    "  USP: 0x"
strSSP:             .asciz    "  SSP: 0x"

          .endif
