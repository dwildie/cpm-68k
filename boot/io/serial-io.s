                    .include  "include/serial.i"
                    .include  "include/ascii.i"

* ----------------------------------------------------------------------------------
* Primitive I/O routines for the 2 SIO + USB Board.
* ----------------------------------------------------------------------------------
                    .text

                    .global   a_keystat,a_outch,a_inch
                    .global   b_keystat,b_outch,b_inch
                    .global   u_keystat,u_outch,u_inch,u_detect

* ----------------------------------------------------------------------------------
* Get a serial port a input status in %D0, Z= nothing, 2 = char present
* ----------------------------------------------------------------------------------
a_keystat:          MOVE.B    ZSCC_A_CTL,%D0                          | Get a keyboard status in %D0, Z= nothing, 2 = char present
                    BTST      #ZSCC_RDA,%D0
                    RTS

* ----------------------------------------------------------------------------------
* Output the character in %D0.B to serial port a
* ----------------------------------------------------------------------------------
a_outch:            MOVE.B    ZSCC_A_CTL,%D1                          | Check status is ready to receive character
                    BTST      #ZSCC_TBE,%D1
                    BEQ       a_outch                                 | loop till ready
                    MOVE.B    %D0,ZSCC_A_DATA                         | Output ASCII (in %D0) to hardware port
                    RTS

* ----------------------------------------------------------------------------------
* Read a character from serial port a
* ----------------------------------------------------------------------------------
a_inch:             MOVE.B    ZSCC_A_CTL,%D1                          | Get the status in %D1
                    BTST      #ZSCC_RDA,%D1
                    BEQ       a_inch
                    MOVE.B    ZSCC_A_DATA,%D0                         | Get ASCII (in %D0) from hardware port
                    RTS                                               | Return from subroutine, input char is in %D0

* ----------------------------------------------------------------------------------
* Get a serial port b input status in %D0, Z= nothing, 2 = char present
* ----------------------------------------------------------------------------------
b_keystat:          MOVE.B    ZSCC_B_CTL,%D0                          | Get a keyboard status in %D0, Z= nothing, 2 = char present
                    BTST      #ZSCC_RDA,%D0
                    RTS

* ----------------------------------------------------------------------------------
* Output the character in %D0.B to serial port b
* ----------------------------------------------------------------------------------
b_outch:            MOVE.B    ZSCC_B_CTL,%D1                          | Check status is ready to receive character
                    BTST      #ZSCC_TBE,%D1
                    BEQ       b_outch                                 | loop till ready
                    MOVE.B    %D0,ZSCC_B_DATA                         | Output ASCII (in %D0) to hardware port
                    RTS

* ----------------------------------------------------------------------------------
* Read a character from serial port b
* ----------------------------------------------------------------------------------
b_inch:             MOVE.B    ZSCC_B_CTL,%D1                          | Get the status in %D1
                    BTST      #ZSCC_RDA,%D1
                    BEQ       b_inch
                    MOVE.B    ZSCC_B_DATA,%D0                         | Get ASCII (in %D0) from hardware port
                    RTS                                               | Return from subroutine, input char is in %D0

* ----------------------------------------------------------------------------------
* Get a usb port input status in %D0, Z= nothing, 2 = char present
* ----------------------------------------------------------------------------------
u_keystat:          MOVE.B    USB_STATUS,%D0                          | Get a keyboard status in %D0, Z= nothing, 2 = char present
                    AND.B     #USB_RDA,%D0
                    EOR.B     #USB_RDA,%D0
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

* ----------------------------------------------------------------------------------
* Determine if usb port present, Z set = not present
* ----------------------------------------------------------------------------------
u_detect:           MOVE.B    USB_STATUS,%D0                          | Check TBE bit, must be zero
                    AND.B     #USB_TBE,%D0
                    BNE       3f                                      | Not zero, USB cannot be present

                    MOVE.B    #'*',USB_DATA                           | Output a char

                    MOVE.W    #0x100,%D1                              | Read input characters until empty, max 0x100 attempts
1:                  MOVE.B    USB_DATA,%D0                            | Read char
                    MOVE.B    USB_STATUS,%D0                          | Check for no more characters
                    AND.B     #USB_RDA,%D0
                    BNE       2f

                    SUB.W     #1,%D1                                  | Decrement loop counter
                    BNE       1b
                    BRA       3f

2:                  MOVE.B    #'#',USB_DATA                           | Output a char
                    OR.B      #1,%D0
                    BRA       4f

3:                  EOR.B     %D0,%D0
4:                  RTS
