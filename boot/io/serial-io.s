          .ifdef              IS_68030
                    .include  "include/serial.i"
                    .include  "include/ascii.i"

* ----------------------------------------------------------------------------------
                    .text

                    .global   a_keystat,a_outch,a_inch
                    .global   b_keystat,b_outch,b_inch
                    .global   u_keystat,u_outch,u_inch

* ----------------------------------------------------------------------------------
* Get a serial port a input status in %D0, Z= nothing, 2 = char present
* ----------------------------------------------------------------------------------
a_keystat:          MOVE.B    ZSCC_A_CTL,%D0                          | Get a keyboard status in %D0, Z= nothing, 2 = char present
                    AND.B     #SER_RDA,%D0
                    RTS

* ----------------------------------------------------------------------------------
* Output the character in %D0.B to serial port a
* ----------------------------------------------------------------------------------
a_outch:            MOVE.B    ZSCC_A_CTL,%D1                          | Check status is ready to receive character
                    AND.B     #SER_TBE,%D1
                    BEQ       a_outch                                 | loop till ready
                    MOVE.B    %D0,ZSCC_A_DATA                         | Output ASCII (in %D0) to hardware port
                    RTS

* ----------------------------------------------------------------------------------
* Read a character from serial port a
* ----------------------------------------------------------------------------------
a_inch:             MOVE.B    ZSCC_A_CTL,%D1                          | Get the status in %D1
                    AND.B     #SER_RDA,%D1
                    BEQ       a_inch
                    MOVE.B    ZSCC_A_DATA,%D0                         | Get ASCII (in %D0) from hardware port
                    RTS                                               | Return from subroutine, input char is in %D0

* ----------------------------------------------------------------------------------
* Get a serial port b input status in %D0, Z= nothing, 2 = char present
* ----------------------------------------------------------------------------------
b_keystat:          MOVE.B    ZSCC_B_CTL,%D0                          | Get a keyboard status in %D0, Z= nothing, 2 = char present
                    AND.B     #SER_RDA,%D0
                    RTS

* ----------------------------------------------------------------------------------
* Output the character in %D0.B to serial port b
* ----------------------------------------------------------------------------------
b_outch:            MOVE.B    ZSCC_B_CTL,%D1                          | Check status is ready to receive character
                    AND.B     #SER_TBE,%D1
                    BEQ       b_outch                                 | loop till ready
                    MOVE.B    %D0,ZSCC_B_DATA                         | Output ASCII (in %D0) to hardware port
                    RTS

* ----------------------------------------------------------------------------------
* Read a character from serial port b
* ----------------------------------------------------------------------------------
b_inch:             MOVE.B    ZSCC_B_CTL,%D1                          | Get the status in %D1
                    AND.B     #SER_RDA,%D1
                    BEQ       b_inch
                    MOVE.B    ZSCC_B_DATA,%D0                         | Get ASCII (in %D0) from hardware port
                    RTS                                               | Return from subroutine, input char is in %D0

* ----------------------------------------------------------------------------------
* Get a usb port input status in %D0, Z= nothing, 2 = char present
* ----------------------------------------------------------------------------------
u_keystat:          MOVE.B    ZSCC_A_CTL,%D0                          | Get a keyboard status in %D0, Z= nothing, 2 = char present
                    AND.B     #SER_RDA,%D0
                    RTS

* ----------------------------------------------------------------------------------
* Output the character in %D0.B to usb port
* ----------------------------------------------------------------------------------
u_outch:            MOVE.B    USB_STATUS,%D1                          | Check TBE bit, must be zero
                    AND.B     #USB_TBE,%D1
                    BNE       u_outch
                    MOVE.B    %D0,USB_DATA                            | Write char to the data port
                    RTS

* ----------------------------------------------------------------------------------
* Read a character from usb port
* ----------------------------------------------------------------------------------
u_inch:             MOVE.B    USB_STATUS,%D1                          | Check RDA bit, must be zero
                    AND.B     #USB_RDA,%D1
                    BNE       u_inch
                    MOVE.B    USB_DATA,%D0                            | Read char from data port
                    RTS                                               | Return from subroutine, input char is in %D0

          .endif

