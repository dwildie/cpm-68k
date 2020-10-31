                    .include  "include/ascii.i"

* ----------------------------------------------------------------------------------
* Low level I/O routines
* ----------------------------------------------------------------------------------

                    .text

                    .global   writeStr
                    .global   writeStrn
                    .global   writeCh
                    .global   readCh
                    .global   waitCh

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
* Read a character from keyboard into %D0 (NOTE will NOT be echoed)
* ----------------------------------------------------------------------------------
readCh:             MOVE.L    %D1,-(%SP)                              | > Save D1	
                    BSR       inch
2:                  MOVE.L    (%SP)+,%D1                              | < Restore D1
                    RTS                                               | Return from subroutine, input char is in %D0

* ----------------------------------------------------------------------------------
* Wait for any character to be entered
* ----------------------------------------------------------------------------------
waitCh:             MOVEM.L   %D0-%D1,-(%SP)                          | > Save D0,D1	
                    BSR       inch
                    MOVEM.L   (%SP)+,%D0-%D1                          | < Restore D0,D1
                    RTS


          .end
