* ----------------------------------------------------------------------------------
* Console on CompuPro SS1 serial port, 2651 UART
* ----------------------------------------------------------------------------------

BASE                =         __ports_start__ + 0x50
DATA                =         BASE + 0x0C
STATUS              =         BASE + 0x0D
MODE                =         BASE + 0x0E
CMND                =         BASE + 0x0F

TBE                 =         0x01
RDA                 =         0x02

INIT_MODE1          =         0b11101110                              | 8 bits, no parity, two stop bits
INIT_MODE2          =         0b01111110                              | 9600 baud
INIT_CMND           =         0b00100111                              | Enable tx & rx, set DTR & CTS

* ----------------------------------------------------------------------------------
                    .data
initialised:        .byte     0

* ----------------------------------------------------------------------------------
                    .text

                    .global   p_init
                    .global   p_keystat
                    .global   p_outch
                    .global   p_inch

* ----------------------------------------------------------------------------------
* Initialise
* ----------------------------------------------------------------------------------
p_init:             MOVE.B    #INIT_MODE1,MODE
                    MOVE.B    #INIT_MODE2,MODE
                    MOVE.B    #INIT_CMND,CMND
                    MOVE.B    #1,initialised
                    RTS

* ----------------------------------------------------------------------------------
* Get a keyboard status in %D0, Z= nothing, 2 = char present
* ----------------------------------------------------------------------------------
p_keystat:          MOVE.B    STATUS,%D0                              | Get a keyboard status in %D0, Z= nothing, 2 = char present
                    AND.B     #RDA,%D0
                    RTS

* ----------------------------------------------------------------------------------
* Output a character from %D1.B
* ----------------------------------------------------------------------------------
p_outch:            TST.B     initialised                             | Ignore if not initialised
                    BEQ       1f
                    MOVE.B    STATUS,%D1                              | Check CRT status is ready to receive character
                    AND.B     #TBE,%D1
                    BEQ       p_outch                                 | Loop until the TBE bit is asserted
                    MOVE.B    %D0,DATA                                | Output ASCII (in %D0) to hardware port 01H
1:                  RTS

* ----------------------------------------------------------------------------------
* Input a character from keyboard into %D0
* ----------------------------------------------------------------------------------
p_inch:             MOVE.B    STATUS,%D1                              | Get the keyboard status in %D1
                    AND.B     #RDA,%D1
                    BEQ       p_inch                                  | Loop until the RDA bit is asserted
                    MOVE.B    DATA,%D0                                | Get ASCII (in %D0) from hardware port 01H
                    RTS                                               | Return from subroutine, input char is in %D0

          .end
