                    .include  "include/serial.i"
                    .include  "include/ascii.i"
                    .include  "include/macros.i"

* ----------------------------------------------------------------------------------
                    .text

                    .global   serInitA,serStatusA,serCmdA,serValA,writeChA,readChA,loopA,serOutA,serInA
                    .global   serInitB,serStatusB,serCmdB,serValB,writeChB,readChB,loopB,serOutB,serInB
                    .global   serStatusUSB,writChUSB,readChUSB,loopUSB,serOutUSB,serInUSB
                    .global   serReset

* ----------------------------------------------------------------------------------
* Initialise serial port a
* ----------------------------------------------------------------------------------
serInitA:           MOVEM.L   %D0-%D1/%A0-%A1,-(%SP)
                    MOVE.L    #ZSCC_A_CTL,%A0
                    BSR       serInit
                    MOVEM.L   (%SP)+,%D0-%D1/%A0-%A1
                    RTS

* ----------------------------------------------------------------------------------
* Display status of serial port a
* ----------------------------------------------------------------------------------
serStatusA:         MOVE.L    #ZSCC_A_CTL,%A0
                    BRA       serStatus

* ----------------------------------------------------------------------------------
* Output the byte in D0 to the command register D1 for serial port a
* ----------------------------------------------------------------------------------
serCmdA:            MOVE.L    #ZSCC_A_CTL,%A0
                    BRA       serCmd

* ----------------------------------------------------------------------------------
* Retrieve the value in D0, of the control register in D1, for serial port a
* ----------------------------------------------------------------------------------
serValA:            MOVE.L    #ZSCC_A_CTL,%A0
                    BRA       serVal

* ----------------------------------------------------------------------------------
* Output the byte (character) in D0 to the serial port a
* ----------------------------------------------------------------------------------
writeChA:           MOVE.L    %D1,-(%SP)                              | > Save D1
                    BSR       a_outch
                    MOVE.L    (%SP)+,%D1                              | < Restore D1
                    RTS

* ----------------------------------------------------------------------------------
* Read a byte (character) from serial port a into D0
* ----------------------------------------------------------------------------------
readChA:            MOVE.L    %D1,-(%SP)                              | > Save D1
                    BSR       a_inch
                    MOVE.L    (%SP)+,%D1                              | < Restore D1
                    RTS

* ----------------------------------------------------------------------------------
* Loopback serial port a
* ----------------------------------------------------------------------------------
loopA:              MOVEM.L   %D1/%A0-%A1,-(%SP)                      | > Save D1
                    MOVE.L    #ZSCC_A_CTL,%A0
                    MOVE.L    #ZSCC_A_DATA,%A1
                    BSR       loopBack
                    MOVEM.L   (%SP)+,%D1/%A0-%A1                      | < Restore D1
                    RTS

* ----------------------------------------------------------------------------------
* Input from serial port a
* ----------------------------------------------------------------------------------
serInA:             MOVEM.L   %D1/%A0-%A1,-(%SP)                      | > Save D1
                    MOVE.L    #ZSCC_A_CTL,%A0
                    MOVE.L    #ZSCC_A_DATA,%A1
                    BSR       serIn
                    MOVEM.L   (%SP)+,%D1/%A0-%A1                      | < Restore D1
                    RTS

* ----------------------------------------------------------------------------------
* Output to serial port a
* ----------------------------------------------------------------------------------
serOutA:            MOVEM.L   %D1/%A0-%A1,-(%SP)                      | > Save D1
                    MOVE.L    #ZSCC_A_CTL,%A0
                    MOVE.L    #ZSCC_A_DATA,%A1
                    BSR       serOut
                    MOVEM.L   (%SP)+,%D1/%A0-%A1                      | < Restore D1
                    RTS

* ----------------------------------------------------------------------------------
* Initialise serial port b
* ----------------------------------------------------------------------------------
serInitB:           MOVEM.L   %D0-%D1/%A0-%A1,-(%SP)
                    MOVE.L    #ZSCC_B_CTL,%A0
                    BSR       serInit
                    MOVEM.L   (%SP)+,%D0-%D1/%A0-%A1
                    RTS

* ----------------------------------------------------------------------------------
* Display status of serial port b
* ----------------------------------------------------------------------------------
serStatusB:         MOVE.L    #ZSCC_B_CTL,%A0
                    BRA       serStatus

* ----------------------------------------------------------------------------------
* Output the byte in D0 to the command register D1 for the serial port b
* ----------------------------------------------------------------------------------
serCmdB:            MOVE.L    #ZSCC_B_CTL,%A0
                    BRA       serCmd

* ----------------------------------------------------------------------------------
* Retrieve the value in D0, of the control register in D1, for serial port b
* ----------------------------------------------------------------------------------
serValB:            MOVE.L    #ZSCC_B_CTL,%A0
                    BRA       serVal

* ----------------------------------------------------------------------------------
* Output the byte (character) in D0 to the serial port b
* ----------------------------------------------------------------------------------
writeChB:           MOVE.L    %D1,-(%SP)                              | > Save D1
                    BSR       b_outch
                    MOVE.L    (%SP)+,%D1                              | < Restore D1
                    RTS

* ----------------------------------------------------------------------------------
* Read a byte (character) from serial port a into D0
* ----------------------------------------------------------------------------------
readChB:            MOVE.L    %D1,-(%SP)                              | > Save D1
                    BSR       b_inch
                    MOVE.L    (%SP)+,%D1                              | < Restore D1
                    RTS

* ----------------------------------------------------------------------------------
* Loopback serial port b
* ----------------------------------------------------------------------------------
loopB:              MOVEM.L   %D1/%A0-%A1,-(%SP)                      | > Save D1
                    MOVE.L    #ZSCC_B_CTL,%A0
                    MOVE.L    #ZSCC_B_DATA,%A1
                    BSR       loopBack
                    MOVEM.L   (%SP)+,%D1/%A0-%A1                      | < Restore D1
                    RTS

* ----------------------------------------------------------------------------------
* Input from serial port b
* ----------------------------------------------------------------------------------
serInB:             MOVEM.L   %D1/%A0-%A1,-(%SP)                      | > Save D1
                    MOVE.L    #ZSCC_B_CTL,%A0
                    MOVE.L    #ZSCC_B_DATA,%A1
                    BSR       serIn
                    MOVEM.L   (%SP)+,%D1/%A0-%A1                      | < Restore D1
                    RTS

* ----------------------------------------------------------------------------------
* Output to serial port b
* ----------------------------------------------------------------------------------
serOutB:            MOVEM.L   %D1/%A0-%A1,-(%SP)                      | > Save D1
                    MOVE.L    #ZSCC_B_CTL,%A0
                    MOVE.L    #ZSCC_B_DATA,%A1
                    BSR       serOut
                    MOVEM.L   (%SP)+,%D1/%A0-%A1                      | < Restore D1
                    RTS

* ----------------------------------------------------------------------------------
* Display status of USB port a
* ----------------------------------------------------------------------------------
serStatusUSB:       MOVE.B    USB_STATUS,%D3

                    PUTS      strRDA
                    BTST      #USB_RDA,%D3
                    BNE       1f
                    PUTCH     #'1'
                    BRA       2f
1:                  PUTCH     #'0'

2:                  PUTS      strTBE
                    BTST      #USB_TBE,%D3
                    BNE       1f
                    PUTCH     #'1'
                    BRA       2f
1:                  PUTCH     #'0'

2:                  RTS

* ----------------------------------------------------------------------------------
* Output the byte (character) in D0 to the serial port usb
* ----------------------------------------------------------------------------------
writeChUSB:         MOVE.L    %D1,-(%SP)                              | > Save D1
                    BSR       u_outch
                    MOVE.L    (%SP)+,%D1                              | < Restore D1
                    RTS

* ----------------------------------------------------------------------------------
* Read a byte (character) from serial port usb into D0
* ----------------------------------------------------------------------------------
readChUSB:          MOVEM.L   %D1,-(%SP)                              | > Save D1
1:                  BSR       u_inch
                    MOVEM.L   (%SP)+,%D1                              | < Restore D1
                    RTS

* ----------------------------------------------------------------------------------
* Loopback serial port usb
* ----------------------------------------------------------------------------------
loopUSB:            BSR       keystat                                 | Check for a console keystroke
                    BEQ       1f                                      | No, check USB
                    BSR       inch                                    | Yes, read console char
                    CMPI.B    #ESC,%D0                                | If it is an Escape char, exit
                    BEQ       2f

1:                  BSR       u_keystat                               | Check for a USB keystroke
                    BEQ       loopUSB                                 | No, start again
                    BSR       readChUSB                               | Yes, read USB char
                    CMPI.B    #ESC,%D0                                | If it is an Escape char, exit
                    BEQ       2f

                    BSR       writeChUSB                              | Echo it back to the usb port
                    BSR       writeCh                                 | Display it on the console

                    CMPI.B    #CR,%D0
                    BNE       loopUSB

                    MOVE.B    #LF,%D0                                 | Output a line feed char for every carriage return
                    BSR       writeChUSB                              | Echo it back to the serial port
                    BSR       writeCh                                 | Display it on the console

                    BRA       loopUSB                                 | Do it again

                    RTS

* ----------------------------------------------------------------------------------
* Input from serial port usb
* ----------------------------------------------------------------------------------
serInUSB:           BSR       keystat                                 | Check for a console keystroke
                    BEQ       1f                                      | No, check USB
                    BSR       inch                                    | Yes, read console char
                    CMPI.B    #ESC,%D0                                | If it is an Escape char, exit
                    BEQ       2f

1:                  BSR       u_keystat                               | Check for a USB keystroke
                    BEQ       serInUSB                                | No, start again
                    BSR       readChUSB                               | Yes, read USB char
                    CMPI.B    #ESC,%D0                                | If it is an Escape char, exit
                    BEQ       2f

                    BSR       writeCh                                 | Echo it to the console

                    CMPI.B    #CR,%D0                                 | If it is a carriage return output a line feed as well
                    BNE       serInUSB

                    MOVE.B    #LF,%D0                                 | Output a line feed char for every carriage return
                    BSR       writeCh                                 | Echo it on the console

                    BRA       serInUSB
2:                  RTS

* ----------------------------------------------------------------------------------
* Output to serial port usb
* ----------------------------------------------------------------------------------
serOutUSB:          BSR       readCh                                  | Read a character from console keyboard

                    CMPI.B    #ESC,%D0                                | If it is an Escape char, exit
                    BEQ       2f

                    BSR       writeChUSB                              | Write it to the usb port
                    BSR       writeCh                                 | Echo it to the console

                    CMPI.B    #CR,%D0                                 | If it is a carriage return output a line feed as well
                    BNE       serOutUSB

                    MOVE.B    #LF,%D0                                 | Output a line feed char for every carriage return
                    BSR       writeChUSB                              | Write to the usb port
                    BSR       writeCh                                 | Echo it on the console

                    BRA       serOutUSB
2:                  RTS

* ----------------------------------------------------------------------------------
* Input from the configured serial port
* ----------------------------------------------------------------------------------
serIn:              BSR       getch                                   | Wait for and read a character
                    CMPI.B    #ESC,%D0                                | If it is an Escape char, exit
                    BEQ       2f

                    BSR       writeCh                                 | Display it on the console

                    CMPI.B    #CR,%D0
                    BNE       serIn

                    MOVE.B    #LF,%D0                                 | Output a line feed char for every carriage return
                    BSR       writeCh                                 | Display it on the console

                    BRA       serIn                                   | Do it again
2:                  RTS


* ----------------------------------------------------------------------------------
* Output to the configured serial port
* ----------------------------------------------------------------------------------
serOut:             BSR       readCh                                  | Read a character from console keyboard

                    CMPI.B    #ESC,%D0                                | If it is an Escape char, exit
                    BEQ       2f

                    BSR       outch                                   | Write it to the serial port
                    BSR       writeCh                                 | Echo it to the console

                    CMPI.B    #CR,%D0
                    BNE       serOut

                    MOVE.B    #LF,%D0                                 | Output a line feed char for every carriage return
                    BSR       outch                                   | Write to the serial port
                    BSR       writeCh                                 | Echo it on the console

                    BRA       serOut
2:                  RTS

* ----------------------------------------------------------------------------------
* Read a character from a serial port
* ----------------------------------------------------------------------------------
getch:              BTST      #ZSCC_RDA,(%A0)                         | Wait until the RDA bit is set
                    BEQ       getch
                    MOVE.B    (%A1),%D0                               | Get ASCII (in %D0) from hardware port
                    RTS                                               | Return from subroutine, input char is in %D0

* ----------------------------------------------------------------------------------
* Output the character in %D0.B
* ----------------------------------------------------------------------------------
outch:              BTST      #ZSCC_TBE,(%A0)                         | Wait until the TBE bit is set
                    BEQ       outch
                    MOVE.B    %D0,(%A1)                               | Output ASCII (in %D0) to hardware port 01H
                    RTS

* ----------------------------------------------------------------------------------
* Loopback, read a character from the port then write it back to the port
* ----------------------------------------------------------------------------------
loopBack:           BSR       getch                                   | Wait for and read a character
                    CMPI.B    #ESC,%D0                                | If it is an Escape char, exit
                    BEQ       2f

                    BSR       outch                                   | Echo it back to the serial port
                    BSR       writeCh                                 | Display it on the console

                    CMPI.B    #CR,%D0
                    BNE       loopBack

                    MOVE.B    #LF,%D0                                 | Output a line feed char for every carriage return
                    BSR       outch                                   | Echo it back to the serial port
                    BSR       writeCh                                 | Display it on the console

                    BRA       loopBack                                | Do it again
2:                  RTS

* ----------------------------------------------------------------------------------
* Output the value in D0, for the control register in D1, for the control port in A0
* ----------------------------------------------------------------------------------
serCmd:             MOVE.B    (%A0),%D2                               | Read cmd register to clear register select
                    BSR       shortDelay
                    MOVE.B    %D1,(%A0)                               | Select register
                    BSR       shortDelay
                    MOVE.B    %D0,(%A0)                               | Write to selected register
                    RTS

* ----------------------------------------------------------------------------------
* Retrieve the value in D0, of the control register in D1, for the control port in A0
* ----------------------------------------------------------------------------------
serVal:             MOVE.B    (%A0),%D0                               | Read cmd register to clear register select         
                    BSR       shortDelay
                    MOVE.B    %D1,(%A0)                               | Select register
                    BSR       shortDelay
                    MOVE.B    (%A0),%D0                               | Read from selected register
                    RTS

shortDelay:         MOVE.L    %D0,-(%SP)
                    MOVE.L    #0x2,%D0
1:                  SUB.L     #0x1,%D0
                    BNE       1b
                    MOVE.L    (%SP)+, %D0
                    RTS

* ----------------------------------------------------------------------------------
* Display the serial port status using the controle port in A0
* ----------------------------------------------------------------------------------
serStatus:          MOVE.B    (%A0),%D3

                    PUTS      strRDA
                    BTST      #ZSCC_RDA,%D3
                    BEQ       1f
                    PUTCH     #'1'
                    BRA       2f
1:                  PUTCH     #'0'

2:                  PUTS      strTBE
                    BTST      #ZSCC_TBE,%D3
                    BEQ       1f
                    PUTCH     #'1'
                    BRA       2f
1:                  PUTCH     #'0'

2:                  PUTS      strDCD
                    BTST      #ZSCC_DCD,%D3
                    BEQ       1f
                    PUTCH     #'1'
                    BRA       2f
1:                  PUTCH     #'0'

2:                  PUTS      strCTS
                    BTST      #ZSCC_CTS,%D3
                    BEQ       1f
                    PUTCH     #'1'
                    BRA       2f
1:                  PUTCH     #'0'

2:                  RTS

* ----------------------------------------------------------------------------------
* Initialise the serial port using the controle port in A0
* ----------------------------------------------------------------------------------
serInit:            MOVE.B    (%A0),%D0                               | Read cmd register to clear register select
                    MOVE.L    #initCmdLen,%D0                         | Byte count of init commands
                    LEA       initCmds,%A1                            | Start of SCCINIT table
1:                  MOVE.B    (%A1)+,(%A0)                            | Table of Zilog SCC Initilization values, program for 38.4K Baud
                    SUB.B     #1,%D0                                  | All values
                    TST.B     %D0
                    BNE       1b
                    RTS

* ----------------------------------------------------------------------------------
* Hard reset the Z8530
* ----------------------------------------------------------------------------------
serReset:           MOVE.B    #0x09,ZSCC_A_CTL                        | WR 9
                    MOVE.B    #0xC0,ZSCC_A_CTL                        | Hard reset
                    RTS

* ----------------------------------------------------------------------------------
*  0x03FE -    150 baud
*  0x01FE -    300 baud
*  0x00FE -    600 baud
*  0x007E -  1,200 baud
*  0x003E -  2,400 baud
*  0x001E -  4,800 baud
*  0x000E -  9,600 baud
*  0x0006 - 19,200 baud
*  0x0002 - 38,400 baud
* ----------------------------------------------------------------------------------

* ----------------------------------------------------------------------------------
* Initialisation commands for each Z8530 channel
* ----------------------------------------------------------------------------------
initCmds:           dc.b      0x04, 0x44                              | WR4:  X16 clock, 1 Stop, NP
                    dc.b      0x0B, 0x50                              | WR11: Receive/transmit clock = BRG
                    dc.b      0x0C, 0x0E                              | WR12: Low byte for Baud
                    dc.b      0x0D, 0x00                              | WR13: High byte for Baud
                    dc.b      0x0E, 0x01                              | WR14: Use 4.9152 MHz Clock, enable BRG
                    dc.b      0x01, 0x12                              | WR1:  Enable Tx int, enable Rx int on all chars
                    dc.b      0x03, 0xC1                              | WR3:  Enable Rx, 8 bits, RTS/CTS/DCD auto enabled 
                    dc.b      0x05, 0xEA                              | WR5:  Enable TX, 8 bits, assert DTR & CTS
initCmdsEnd:

initCmdLen          =         initCmdsEnd - initCmds

*---------------------------------------------------------------------------------------------------------
                    .section  .rodata.strings
                    .align(2)

strRDA:             .asciz    ": RDA="
strTBE:             .asciz    ", TBE="
strDCD:             .asciz    ", DCD="
strCTS:             .asciz    ", CTS="

