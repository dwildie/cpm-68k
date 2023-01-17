                    .text     0
                    .global   _start
                    .global   fatTable
                    .global   biosTable
*---------------------------------------------------------------------------------------------------------
* Entry point
*---------------------------------------------------------------------------------------------------------
_start:             LINK      %FP,#0

                    BSR       initDataSegs                            | initialise data segments

                    MOVE.L    20(%FP), fatTable
                    MOVE.L    16(%FP), biosTable

		    MOVE.L    12(%FP),%A0                             | argv
	            MOVE.L    %A0, -(%SP)

		    MOVE.L    8(%FP),%D0                              | argc
	            MOVE.L    %D0, -(%SP)

                    JSR       main
                    ADD       #8,%SP

                    UNLK      %FP
                    RTS

*---------------------------------------------------------------------------------------------------------
* Initialise the initialised & uninitialised data segments
*---------------------------------------------------------------------------------------------------------
initDataSegs:       
		    MOVEA.L   #__bss_start, %A0                     | Zero bss section
                    MOVEA.L   #_end, %A1

1:                  CMPA.L    %A0, %A1                                | Initialise each byte to 0x00
                    BEQ       2f
                    MOVE.B    #0x00,(%A0)+
                    BRA       1b
2:		    RTS


*---------------------------------------------------------------------------------------------------------
                    .data
                    .align(4)
fatTable:		    DC.L     0
biosTable:          DC.L     0
