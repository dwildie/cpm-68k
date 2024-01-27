                    .include  "include/macros.i"
                    .include  "include/ascii.i"

                    .text
                    .global   readLn
                    .global   readLong

*-----------------------------------------------------------------------------------------------------
*  readLn: Read a line into the buffer pointed to by %A0 of size %D0, returns the input character count in %D0
*-----------------------------------------------------------------------------------------------------
readLn:             MOVEM.L   %D1-%D2,-(%SP)
                    MOVE.L    %D0,%D1
                    MOVE.L    #0,%D2                        | Buffer index

1:                  BSR       readCh                        | Read a character into %D0

                    TST.B     %D0                           | Check for a null character
                    BEQ       1b
                    
                    CMPI.B    #BS,%D0                       | Check for a backspace
                    BNE       2f
                    TST.B     %D2                           | Check for empty buffer
                    BEQ       2f

                    MOVE.B    #0,(%A0,%D2)                  | Clear the buffer
                    SUBQ.B    #1,%D2                        | Decrement the index
                    BSR       writeCh                       | backspace
                    PUTCH     #' '                          | space
                    PUTCH     #BS                           | backspace
                    BRA       1b                            | Go get the next char


2:                  CMPI.B    #CR,%D0                       | Check for end of line
                    BEQ       3f
                    CMPI.B    #LF,%D0
                    BEQ       3f

                    MOVE.B    %D0,(%A0,%D2)                 | Put the character in the buffer
                    ADDQ.L    #1,%D2                        | Increment the index
                    BSR       writeCh                       | echo it

                    CMP.B     %D2,%D1                       | Check if the buffer is full
                    BGT       1b                            | No, get another character

3:                  MOVE.B    %D2,%D0                       | Return the char count
                    MOVEM.L   (%SP)+,%D2-%D1
                    RTS

*-----------------------------------------------------------------------------------------------------
* readLong:  get a long (8 digit) hex number from the console into %D0
*-----------------------------------------------------------------------------------------------------
readLong:           MOVEM.L   %A1/%D1-%D2,-(%SP)
                    MOVE.L    #0,%D1                        | Set result to zero
                    MOVE.W    #8,%D2                        | Set digit counter

1:                  BSR       readCh                        | Read a character
                    ANDI.L    #0xFF,%D0                     | just to be safe

rl1:                CMPI.B    #CR,%D0                       | EOL ?
                    BEQ       5f                            | Done
                    CMPI.B    #LF,%D0
                    BEQ       5f

                    CMPI.B    #ESC,%D0                      | Escape ?
                    BEQ       4f                            | Bail

                    SUBI.B    #'0',%D0                      | subtract '0'
                    BLT       5f                            | <0? bad
                    CMPI.B    #0x09,%D0                     | less then or equal to 9?
                    BLS       2f                            | yes? we are done with this
                    SUBQ.B    #'A'-':',%D0                  | subtract diff 'A'-':'
                    BLT       5f                            | <0? bad
                    CMPI.B    #0x10,%D0                     | see if it is uppercase
                    BLT       2f                            | was uppercase
                    SUBI.B    #'a'-'A',%D0                  | was lowercase
                    CMPI.B    #0x10,%D0                     | compare with upper range
                    BGE       5f                            | >15? bad

2:                  BSR       writeHexDigit                 | Echo the character

                    ASL.L     #4,%D1                        | shift val to next nybble
                    ADD.B     %D0,%D1                       | accumulate number

                    SUBQ.B    #1,%D2                        | Decrement digit counter
                    BNE       1b                            | Done? No, get the next character

4:                  MOVE.L    #0xFFFFFFFF,%D1               | return -1

5:                  MOVE.L    %D1,%D0                       | Move result to %D0
                    MOVEM.L   (%SP)+,%D2-%D1/%A1
                    rts

