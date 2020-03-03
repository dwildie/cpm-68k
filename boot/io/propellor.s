CON_STAT            =         0x00FF0000                    | Console status port
CON_IN              =         0x00FF0001                    | Console input port. Normally the Propeller Driven S-100 Console-IO Board
CON_OUT             =         0x00FF0001                    | Console output port. Normally the Propeller Driven S-100 Console-IO Board
IOBYTE              =         0x00FF00EF                    | IOBYTE Port on S100Computers SMB Board.

                    .text

* ----------------------------------------------------------------------------------

                    .global   cls
                    .type     cls, @function
*
* Clear screen
*
cls:                MOVE.L    %D0,-(%SP)                    | > Save D0
                    MOVE.B    #0x1f,%D0
                    BSR       writeCh
                    MOVE.L    (%SP)+,%D0                    | < Restore D0
                    RTS

* ----------------------------------------------------------------------------------

                    .global   keystat
                    .type     keystat, @function
*
* Get a keyboard status in %D0, Z= nothing, 2 = char present
*
keystat:            MOVE.B    (CON_STAT),%D0                | Get a keyboard status in %D0, Z= nothing, 2 = char present
                    AND.B     #0x02,%D0
                    TST.B     %D0
                    RTS
                    .include  "include/ascii.i"

* ----------------------------------------------------------------------------------

                    .global   writeCh
                    .type     writeCh, @function
*
* Output the byte (character) in D0 to the console port
*

writeCh:            MOVE.L    %D1,-(%SP)                    | > Save D1	

                    BSR       outch

                    MOVE.L    (%SP)+,%D1                    | < Restore D1
                    RTS

* ----------------------------------------------------------------------------------

                    .global   writeStr
                    .type     writeStr, @function

*
* Output the null terminated string, pointed to by A2, to the console port
*
writeStr:           MOVEM.L   %D0-%D1,-(%SP)                | > Save D1	

1:                  MOVE.B    (%A2)+,%D0
                    TST.B     %D0
                    BEQ       2f                            | If null character found
                    BSR       outch                         | Output the character
                    BRA       1b                            | Next

2:                  MOVEM.L   (%SP)+,%D1-%D0                | < Restore D1
                    RTS

* ----------------------------------------------------------------------------------

                    .type     outch, @function

outch:              MOVE.B    (CON_STAT),%D1                | Check CRT status is ready to receive character
                    AND.B     #0x04,%D1
                    TST.B     %D1
                    BEQ       outch

                    MOVE.B    %D0,(CON_OUT)                 | Output ASCII (in %D0) to hardware port 01H

                    RTS


* ----------------------------------------------------------------------------------

                    .global   readCh
                    .type     readCh, @function

*
* Read a character from keyboard into %D0 (NOTE will NOT be echoed)
*
readCh:             MOVE.L    %D1,-(%SP)                    | > Save D1	

1:                  MOVE.B    (CON_STAT),%D1                | Get the keyboard status in %D1
                    AND.B     #0x02,%D1
                    TST.B     %D1                           | Are we ready
                    BEQ       1b

                    MOVE.B    (CON_IN),%D0                  | Get ASCII (in %D0) from hardware port 01H
*                    BSR       outch               | Echo it on console

                    CMPI.B    #CR,%D0                       | If char is CR (Enter key), also output a LF
                    BNE       2f
*                    MOV.B     #LF,%D0             | Output LF
*                    BSR       outch
                    MOVE.L    #CR,%D0                       | Restore CR to D0

2:                  MOVE.L    (%SP)+,%D1                    | < Restore D1
                    RTS                                     | Return from subroutine, inpu char is in %D0

          .end
