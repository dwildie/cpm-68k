          .ifdef              IS_68030
                    .include  "include/serial.i"
                    .include  "include/ascii.i"

* ----------------------------------------------------------------------------------
                    .text

                    .global   serInitA,writeChA,readChA,loopA,serOutA
                    .global   serInitB,writeChB,readChB,loopB,serOutB
                    .global   writChUSB,readChUSB,loopUSB,serOutUSB

* ----------------------------------------------------------------------------------
* Initialise serial port a
* ----------------------------------------------------------------------------------
serInitA:           MOVEM.L   %D0-%D1/%A0-%A1,-(%SP)
                    MOVE.L    #ZSCC_A_CTL,%A0
                    BSR       serInit
                    MOVEM.L   (%SP)+,%D0-%D1/%A0-%A1
                    RTS

* ----------------------------------------------------------------------------------
* Output the byte (character) in D0 to the serial port a
* ----------------------------------------------------------------------------------
writeChA:           MOVEM.L   %D1/%A0-%A1,-(%SP)                      | > Save D1
                    MOVE.L    #ZSCC_A_CTL,%A0
                    MOVE.L    #ZSCC_A_DATA,%A1
                    BSR       outch
                    MOVEM.L   (%SP)+,%D1/%A0-%A1                      | < Restore D1
                    RTS

* ----------------------------------------------------------------------------------
* Read a byte (character) from serial port a into D0
* ----------------------------------------------------------------------------------
readChA:            MOVEM.L   %D1/%A0-%A1,-(%SP)                      | > Save D1
                    MOVE.L    #ZSCC_A_CTL,%A0
                    MOVE.L    #ZSCC_A_DATA,%A1
                    BSR       getch
                    MOVEM.L   (%SP)+,%D1/%A0-%A1                      | < Restore D1
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
* Output the byte (character) in D0 to the serial port b
* ----------------------------------------------------------------------------------
writeChB:           MOVEM.L   %D1/%A0-%A1,-(%SP)                      | > Save D1
                    MOVE.L    #ZSCC_B_CTL,%A0
                    MOVE.L    #ZSCC_B_DATA,%A1
                    BSR       outch
                    MOVEM.L   (%SP)+,%D1/%A0-%A1                      | < Restore D1
                    RTS

* ----------------------------------------------------------------------------------
* Read a byte (character) from serial port a into D0
* ----------------------------------------------------------------------------------
readChB:            MOVEM.L   %D1/%A0-%A1,-(%SP)                      | > Save D1
                    MOVE.L    #ZSCC_B_CTL,%A0
                    MOVE.L    #ZSCC_B_DATA,%A1
                    BSR       getch
                    MOVEM.L   (%SP)+,%D1/%A0-%A1                      | < Restore D1
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
* Output to serial port b
* ----------------------------------------------------------------------------------
serOutB:            MOVEM.L   %D1/%A0-%A1,-(%SP)                      | > Save D1
                    MOVE.L    #ZSCC_B_CTL,%A0
                    MOVE.L    #ZSCC_B_DATA,%A1
                    BSR       serOut
                    MOVEM.L   (%SP)+,%D1/%A0-%A1                      | < Restore D1
                    RTS

* ----------------------------------------------------------------------------------
* Output the byte (character) in D0 to the serial port usb
* ----------------------------------------------------------------------------------
writeChUSB:         MOVEM.L   %D1,-(%SP)                              | > Save D1

1:                  MOVE.B    USB_STATUS,%D1                          | Check TBE bit, must be zero
                    AND.B     #USB_TBE,%D1
                    TST.B     %D1
                    BNE       1b

                    MOVE.B    %D0,USB_DATA                            | Write char to the data port

                    MOVEM.L   (%SP)+,%D1                              | < Restore D1
                    RTS

* ----------------------------------------------------------------------------------
* Read a byte (character) from serial port usb into D0
* ----------------------------------------------------------------------------------
readChUSB:          MOVEM.L   %D1,-(%SP)                              | > Save D1

1:                  MOVE.B    USB_STATUS,%D1                          | Check RDA bit, must be zero
                    AND.B     #USB_RDA,%D1
                    BNE       1b

                    MOVE.B    USB_DATA,%D0                            | Read char from data port

                    MOVEM.L   (%SP)+,%D1                              | < Restore D1
                    RTS

* ----------------------------------------------------------------------------------
* Loopback serial port usb
* ----------------------------------------------------------------------------------
loopUSB:            BSR       readChUSB                               | Wait for and read a character
                    CMPI      #ESC,%D0                                | If it is an Escape char, exit
                    BEQ       2f

                    BSR       writeChUSB                              | Echo it back to the usb port
                    BSR       writeCh                                 | Display it on the console

                    CMPI      #CR,%D0
                    BNE       loopUSB

                    MOVE.B    #LF,%D0                                 | Output a line feed char for every carriage return
                    BSR       writeChUSB                              | Echo it back to the serial port
                    BSR       writeCh                                 | Display it on the console

                    BRA       loopUSB                                 | Do it again

                    RTS

* ----------------------------------------------------------------------------------
* Output to serial port usb
* ----------------------------------------------------------------------------------
serOutUSB:          BSR       readCh                                  | Read a character from console keyboard

                    CMPI      #ESC,%D0                                | If it is an Escape char, exit
                    BEQ       2f

                    BSR       writeChUSB                              | Write it to the usb port
                    BSR       writeCh                                 | Echo it to the console

                    CMPI      #CR,%D0                                 | If it is a carriage return output a line feed as well
                    BNE       serOutUSB

                    MOVE.B    #LF,%D0                                 | Output a line feed char for every carriage return
                    BSR       writeChUSB                              | Write to the usb port
                    BSR       writeCh                                 | Echo it on the console

                    BRA       serOutUSB
2:                  RTS


* ----------------------------------------------------------------------------------
* Output to the configuraed serial port
* ----------------------------------------------------------------------------------
serOut:             BSR       readCh                                  | Read a character from console keyboard

                    CMPI      #ESC,%D0                                | If it is an Escape char, exit
                    BEQ       2f

                    BSR       outch                                   | Write it to the serial port
                    BSR       writeCh                                 | Echo it to the console

                    CMPI      #CR,%D0
                    BNE       serOut

                    MOVE.B    #LF,%D0                                 | Output a line feed char for every carriage return
                    BSR       outch                                   | Write to the serial port
                    BSR       writeCh                                 | Echo it on the console

                    BRA       serOut
2:                  RTS

* ----------------------------------------------------------------------------------
* Read a character from a serial port
* ----------------------------------------------------------------------------------
getch:              MOVE.B    (%A0),%D1                               | Get the status in %D1
                    AND.B     #SER_RDA,%D1
                    TST.B     %D1                                     | Are we ready
                    BEQ       getch

                    MOVE.B    (%A1),%D0                               | Get ASCII (in %D0) from hardware port
                    RTS                                               | Return from subroutine, input char is in %D0

* ----------------------------------------------------------------------------------
* Output the character in %D0.B
* ----------------------------------------------------------------------------------
outch:              MOVE.B    (%A0),%D1                               | Check CRT status is ready to receive character
                    AND.B     #SER_TBE,%D1
                    TST.B     %D1
                    BEQ       outch

                    MOVE.B    %D0,(%A1)                               | Output ASCII (in %D0) to hardware port 01H
                    RTS

* ----------------------------------------------------------------------------------
* Loopback, read a character from the port then write it back to the port
* ----------------------------------------------------------------------------------
loopBack:           BSR       getch                                   | Wait for and read a character
                    CMPI      #ESC,%D0                                | If it is an Escape char, exit
                    BEQ       2f

                    BSR       outch                                   | Echo it back to the serial port
                    BSR       writeCh                                 | Display it on the console

                    CMPI      #CR,%D0
                    BNE       loopBack

                    MOVE.B    #LF,%D0                                 | Output a line feed char for every carriage return
                    BSR       outch                                   | Echo it back to the serial port
                    BSR       writeCh                                 | Display it on the console

                    BRA       loopBack                                | Do it again
2:                  RTS

* ----------------------------------------------------------------------------------
* Initialise the serial port using the controle port in D0
* ----------------------------------------------------------------------------------
serInit:            MOVE.L    #initCmdLen,%D0                         | Byte count of init commands
                    LEA       initCmds,%A1                            | Start of SCCINIT table
1:                  MOVE.B    (%A1)+,%D1                              | Table of Zilog SCC Initilization values
                    MOVE.B    %D1,(%A0)                               | Program the SCC Channel B (A1,A3 or 10,12H) for 19K Baud
                    SUB.B     #1,%D0                                  | All 14 values
                    TST.B     %D0
                    BNE       1b
                    RTS

* ----------------------------------------------------------------------------------
initCmds:           dc.b      0x04                                    | Point to WR4
                    dc.b      0x44                                    | X16 clock,1 Stop,NP

                    dc.b      0x03                                    | Point to WR3
                    dc.b      0xC1                                    | Enable reciever, Auto Enable, Recieve 8 bits

                    dc.b      0x05                                    | Point to WR5
                    dc.b      0xEA                                    | Enable, Transmit 8 bits

                    dc.b      0x0B                                    | Point to WR11
                    dc.b      0x56                                    | Recieve/transmit clock = BRG

                    dc.b      0x0C                                    | Point to WR12
                    dc.b      0x02                                    | Low byte 38,400 Baud

                    dc.b      0x0D                                    | Point to WR13
                    dc.b      0x00                                    | High byte for Baud

                    dc.b      0x0E                                    | Point to WR14
                    dc.b      0x01                                    | Use 4.9152 MHz Clock. Note SD Systems uses a 2.4576 MHz clock, enable BRG

                    dc.b      0x0F                                    | Point to WR15
                    dc.b      0x00                                    | Generate Int with CTS going high
initCmdsEnd:

initCmdLen          =         initCmdsEnd - initCmds

          .endif

