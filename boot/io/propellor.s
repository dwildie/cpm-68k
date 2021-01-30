                    .include  "include/ascii.i"

* ----------------------------------------------------------------------------------
                    .section  .ports.prop

CON_STAT:           ds.b      1
CON_IO:             ds.b      1
* ----------------------------------------------------------------------------------

PROP_TBE            =         0x04
PROP_RDA            =         0x02

                    .text

                    .global   p_keystat
                    .global   p_outch
                    .global   p_inch

* ----------------------------------------------------------------------------------
* Get a keyboard status in %D0, Z= nothing, 2 = char present
* ----------------------------------------------------------------------------------
p_keystat:          MOVE.B    CON_STAT,%D0                            | Get a keyboard status in %D0, Z= nothing, 2 = char present
                    AND.B     #PROP_RDA,%D0
                    TST.B     %D0
                    RTS

* ----------------------------------------------------------------------------------
* Output a character from %D1.B
* ----------------------------------------------------------------------------------
p_outch:            MOVE.B    CON_STAT,%D1                            | Check CRT status is ready to receive character
                    AND.B     #PROP_TBE,%D1
                    TST.B     %D1
                    BEQ       outch
                    MOVE.B    %D0,CON_IO                              | Output ASCII (in %D0) to hardware port 01H
                    RTS

* ----------------------------------------------------------------------------------
* Input a character from keyboard into %D0 (NOTE will NOT be echoed)
* ----------------------------------------------------------------------------------
p_inch:             MOVE.B    CON_STAT,%D1                            | Get the keyboard status in %D1
                    AND.B     #PROP_RDA,%D1
                    TST.B     %D1                                     | Are we ready
                    BEQ       p_inch

                    MOVE.B    CON_IO,%D0                              | Get ASCII (in %D0) from hardware port 01H
                    RTS                                               | Return from subroutine, input char is in %D0

          .end
