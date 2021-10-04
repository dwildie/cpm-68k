                    .text

                    .global   toUpperChar
                    .global   stringcmp
                    .global   split
                    .global   asciiToLong
                    .global   asciiToByte

*-----------------------------------------------------------------------------------------------------
* Convert character in D1.B to upper case
*-----------------------------------------------------------------------------------------------------
toUpperChar:        CMP.B     #0x40,%D1                               | LC->UC in D1
                    BCS       1f
                    CMP.B     #0x7B,%D1
                    BCC       1f
                    AND.B     #0x5F,%D1
1:                  RTS


*-----------------------------------------------------------------------------------------------------
* compare the string at %A0 with the string at %A1, setting %D0 to 0 if they are the same. Zero will
* also be set. otherwise d0 will be 1. a0 and a1 are preserved, for repeated calling.
*-----------------------------------------------------------------------------------------------------
stringcmp:          MOVEM.L   %A0-%A1,-(%SP)
1:                  MOVE.B    (%A0)+,%D0                              | read in a1 char
                    BEQ       5f                                      | null, still need check a1
                    CMP.B     (%A1)+,%D0                              | compare
                    BEQ       1b                                      | match, keep checking
2:                  MOVE.W    #1,%D0                                  | not match
                    BRA       4f                                      | out we go
3:                  CLR.W     %D0                                     | match
4:                  MOVEM.L   (%SP)+,%A0-%A1
                    RTS

5:                  TST.B     (%A1)                                   | check null on right
                    BNE       2b                                      | not the same
                    BRA       3b                                      | out we go with match

*---------------------------------------------------------------------------------------------------------
* Split the input string, %A0 length %D0.B, into an array of tokens at %A1 length %D1.B
* String is split on occurances of ' ' & ':' characters
* Return the token count in %D0.B
*---------------------------------------------------------------------------------------------------------
split:              MOVEM.L   %A0-%A1/%D2-%D5,-(%SP)
                    MOVE.L    #0,%D2                                  | Character index
                    MOVE.L    #0xFF,%D3                               | Token index, start at -1

                    MOVE.B    #0,%D4                                  | 0 = not in token, 1 = in token
                    BRA       2f

1:                  ADDQ.B    #1,%D2
2:                  CMP.B     %D2,%D0                                 | Check if at end of input
                    BLE       4f

                    MOVE.B    (%A0,%D2),%D5                           | Get next input char
                    CMPI.B    #' ',%D5
                    BEQ       3f
                    CMPI.B    #':',%D5
                    BEQ       3f

                    TST.B     %D4                                     | Not a space, check if in token
                    BNE       1b                                      | Already in a token, keep looking for a space

                    ADDQ.B    #1,%D3                                  | Increment token index
                    LSL.L     #2,%D3                                  | Multiply by to get offset
                    MOVE.L    %A0,(%A1,%D3)                           | Point token to current input char
                    ADD.L     %D2,(%A1,%D3)
                    LSR.L     #2,%D3                                  | Back to an index
                    ADDQ.B    #1,%D4                                  | Set in token flag
                    BRA       1b

3:                  MOVE.B    #0,(%A0,%D2)                            | Replace space with null
                    TST.B     %D4
                    BEQ       1b                                      | Not in a token, keep scanning

                    SUBQ.B    #1,%D4                                  | Clear in token flag
                    BRA       1b                                      | Keep scanning

4:                  TST       %D4
                    BEQ       5f
                    MOVE.B    #0,(%A0,%D2)                            | Terminate the last token with a null

5:                  MOVE.B    %D3,%D0                                 | Return count = token index + 1
                    ADDQ.B    #1,%D0
                    MOVEM.L   (%SP)+,%A0-%A1/%D2-%D5
                    RTS

*---------------------------------------------------------------------------------------------------------
* Convert the string pointed to by A0 to a long
*---------------------------------------------------------------------------------------------------------
asciiToLong:        MOVEM.L   %A0/%D1-%D2,-(%SP)
                    MOVE.L    #0,%D0                                  | set result to zero
                    MOVE.W    #0,%D1                                  | clear digit counter

1:                  MOVE.B    (%A0)+,%D2                              | get the next character
                    CMP.B     #'!',%D2                                | see if it is a nonwsp char
                    BLS       5f                                      | yes? then we are done

                    SUB.B     #'0',%D2                                | subtract '0'
                    BLT       4f                                      | <0? bad
                    CMP.B     #0x09,%D2                               | less then or equal to 9?
                    BLS       2f                                      | yes? we are done with this
                    SUB.B     #'A'-':',%D2                            | subtract diff 'A'-':'
                    BLT       4f                                      | <0? bad
                    CMP.B     #0x10,%D2                               | see if it is uppercase
                    BLT       2f                                      | was uppercase
                    SUB.B     #'a-'A,%D2                              | was lowercase
                    CMP.B     #0x10,%D2                               | compare with upper range
                    BGE       4f                                      | >15? bad

2:                  ASL.L     #4,%D0                                  | shift val to next nybble
                    ADD.B     %D2,%D0                                 | accumulate number
                    ADDQ.B    #1,%D1                                  | inc digit counter
                    CMPI.B    #8,%D1                                  | too many digits?
                    BGT       4f                                      | yes? bad
                    BRA       1b                                      | get more

4:                  MOVE.L    #0xFFFFFFFF,%D0                         | mark 0 digits
5:                  MOVEM.L   (%SP)+,%A0/%D1-%D2
                    RTS

*-----------------------------------------------------------------------------------------------------
* asciiToByte(*str)
*-----------------------------------------------------------------------------------------------------
asciiToByte:        LINK      %FP,#0
                    MOVEM.L   %D1-%D2/%A0,-(%SP)

                    MOVE.L    8(%FP),%A0                              | Pointer to chars
                    MOVE.W    #0,%D1                                  | Set result to zero
                    MOVE.W    #1,%D2                                  | Set digit counter, less one for DBRA

1:                  MOVE.B    (%A0)+,%D0                              | Get a character

                    SUBI.B    #'0',%D0                                | subtract '0'
                    BLT       3f                                      | <0? bad
                    CMPI.B    #0x09,%D0                               | less then or equal to 9?
                    BLS       2f                                      | yes? we are done with this
                    SUBQ.B    #'A'-':',%D0                            | subtract diff 'A'-':'
                    BLT       3f                                      | <0? bad
                    CMPI.B    #0x10,%D0                               | see if it is uppercase
                    BLT       2f                                      | was uppercase
                    SUBI.B    #'a'-'A',%D0                            | was lowercase
                    CMPI.B    #0x10,%D0                               | compare with upper range
                    BGE       3f                                      | >15? bad

2:                  ASL.W     #4,%D1                                  | shift val to next nybble
                    ADD.B     %D0,%D1                                 | accumulate number

                    DBRA      %D2,1b                                  | Loop until all chars processed
                    BRA       4f

3:                  MOVE.W    #0xFFFF,%D1                             | return -1

4:                  MOVE.L    %D1,%D0                                 | Move result to %D0

                    MOVEM.L   (%SP)+,%D1-%D2/%A0
                    UNLK      %FP
                    RTS

