                    .include  "include/propeller.i"
                    .include  "include/ascii.i"

                    .text

                    .global   keystat
                    .global   writeStr
                    .global   writeCh
                    .global   readCh

* ----------------------------------------------------------------------------------
* Get a keyboard status in %D0, Z= nothing, 2 = char present
* ----------------------------------------------------------------------------------
keystat:            MOVE.B    (CON_STAT),%D0                | Get a keyboard status in %D0, Z= nothing, 2 = char present
                    AND.B     #0x02,%D0
                    TST.B     %D0
                    RTS

* ----------------------------------------------------------------------------------
* Output the byte (character) in D0 to the console port
* ----------------------------------------------------------------------------------
writeCh:            MOVE.L    %D1,-(%SP)                    | > Save D1	
                    BSR       outch
                    MOVE.L    (%SP)+,%D1                    | < Restore D1
                    RTS

* ----------------------------------------------------------------------------------
* Output the null terminated string, pointed to by A2, to the console port
* ----------------------------------------------------------------------------------
writeStr:           MOVEM.L   %D0-%D1,-(%SP)                | > Save D1	

1:                  MOVE.B    (%A2)+,%D0
                    TST.B     %D0
                    BEQ       2f                            | If null character found
                    BSR       outch                         | Output the character
                    BRA       1b                            | Next

2:                  MOVEM.L   (%SP)+,%D1-%D0                | < Restore D1
                    RTS

* ----------------------------------------------------------------------------------
* Output the chracter in %D1.B
* ----------------------------------------------------------------------------------
outch:              MOVE.B    (CON_STAT),%D1                | Check CRT status is ready to receive character
                    AND.B     #0x04,%D1
                    TST.B     %D1
                    BEQ       outch

                    MOVE.B    %D0,(CON_OUT)                 | Output ASCII (in %D0) to hardware port 01H

                    RTS


* ----------------------------------------------------------------------------------
* Read a character from keyboard into %D0 (NOTE will NOT be echoed)
* ----------------------------------------------------------------------------------
readCh:             MOVE.L    %D1,-(%SP)                    | > Save D1	

1:                  MOVE.B    (CON_STAT),%D1                | Get the keyboard status in %D1
                    AND.B     #0x02,%D1
                    TST.B     %D1                           | Are we ready
                    BEQ       1b

                    MOVE.B    (CON_IN),%D0                  | Get ASCII (in %D0) from hardware port 01H

                    CMPI.B    #CR,%D0                       | If char is CR (Enter key), also output a LF
                    BNE       2f
                    MOVE.L    #CR,%D0                       | Restore CR to D0

2:                  MOVE.L    (%SP)+,%D1                    | < Restore D1
                    RTS                                     | Return from subroutine, inpu char is in %D0

          .end
