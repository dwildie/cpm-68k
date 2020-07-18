                    .include  "include/ascii.i"

* ----------------------------------------------------------------------------------
                    .section  .ports.prop

CON_STAT:           ds.b      1
CON_IO:             ds.b      1
* ----------------------------------------------------------------------------------

                    .text

                    .global   keystat
                    .global   writeStr
                    .global   writeStrn
                    .global   writeCh
                    .global   readCh
                    .global   waitCh

* ----------------------------------------------------------------------------------
* Get a keyboard status in %D0, Z= nothing, 2 = char present
* ----------------------------------------------------------------------------------
keystat:            MOVE.B    CON_STAT,%D0                            | Get a keyboard status in %D0, Z= nothing, 2 = char present
                    AND.B     #0x02,%D0
                    TST.B     %D0
                    RTS

* ----------------------------------------------------------------------------------
* Output the byte (character) in D0 to the console port
* ----------------------------------------------------------------------------------
writeCh:            MOVE.L    %D1,-(%SP)                              | > Save D1	
                    BSR       outch
                    MOVE.L    (%SP)+,%D1                              | < Restore D1
                    RTS

* ----------------------------------------------------------------------------------
* writeStrn(char *str, long count)
* Output the count bytes from str to the console port
* ----------------------------------------------------------------------------------
                    .type     writeStrn,function
writeStrn:          LINK      %FP,#0
                    MOVEM.L   %D0-%D2/%A0,-(%SP)

                    MOVE.L    0x0C(%FP),%D2
                    MOVE.L    0x08(%FP),%A0
                    BRA       2f

1:                  MOVE.B    (%A0)+,%D0
                    BSR       outch
2:                  DBRA      %D2,1b

                    MOVEM.L   (%SP)+,%D0-%D2/%A0
                    UNLK      %FP
                    RTS
* ----------------------------------------------------------------------------------
* Output the null terminated string, pointed to by A2, to the console port
* ----------------------------------------------------------------------------------
writeStr:           MOVEM.L   %D0-%D1,-(%SP)                          | > Save D1	

1:                  MOVE.B    (%A2)+,%D0
                    TST.B     %D0
                    BEQ       2f                                      | If null character found
                    BSR       outch                                   | Output the character
                    BRA       1b                                      | Next

2:                  MOVEM.L   (%SP)+,%D1-%D0                          | < Restore D1
                    RTS

* ----------------------------------------------------------------------------------
* Output the chracter in %D1.B
* ----------------------------------------------------------------------------------
outch:              MOVE.B    CON_STAT,%D1                            | Check CRT status is ready to receive character
                    AND.B     #0x04,%D1
                    TST.B     %D1
                    BEQ       outch

                    MOVE.B    %D0,CON_IO                              | Output ASCII (in %D0) to hardware port 01H

                    RTS


* ----------------------------------------------------------------------------------
* Read a character from keyboard into %D0 (NOTE will NOT be echoed)
* ----------------------------------------------------------------------------------
readCh:             MOVE.L    %D1,-(%SP)                              | > Save D1	

1:                  MOVE.B    CON_STAT,%D1                            | Get the keyboard status in %D1
                    AND.B     #0x02,%D1
                    TST.B     %D1                                     | Are we ready
                    BEQ       1b

                    MOVE.B    CON_IO,%D0                              | Get ASCII (in %D0) from hardware port 01H

                    CMPI.B    #CR,%D0                                 | If char is CR (Enter key), also output a LF
                    BNE       2f
                    MOVE.L    #CR,%D0                                 | Restore CR to D0

2:                  MOVE.L    (%SP)+,%D1                              | < Restore D1
                    RTS                                               | Return from subroutine, input char is in %D0

* ----------------------------------------------------------------------------------
* Wait for any character to be entered
* ----------------------------------------------------------------------------------
waitCh:             MOVE.L    %D1,-(%SP)                              | > Save D1	

1:                  MOVE.B    CON_STAT,%D1                            | Get the keyboard status in %D1
                    AND.B     #0x02,%D1
                    TST.B     %D1                                     | Are we ready
                    BEQ       1b

                    MOVE.B    CON_IO,%D1                              | Read the char from hardware port 01H

                    MOVE.L    (%SP)+,%D1                              | < Restore D1
                    RTS
                    
                    
          .end
