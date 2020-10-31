                    .include  "include/macros.i"
                    .include  "include/io-device.i"

* ----------------------------------------------------------------------------------
* Route io calls to the selected device
* ----------------------------------------------------------------------------------

                    .data
device:             .byte     DEV_PROP

* ----------------------------------------------------------------------------------
                    .text

                    .global   setIODevice
                    .global   keystat
                    .global   outch
                    .global   inch

* ----------------------------------------------------------------------------------
* Set the current IO device, device is specified in %DO.B
* ----------------------------------------------------------------------------------
setIODevice:        CMPI.B    #DEV_PROP,%D0
                    BEQ       1f

                    CMPI.B    #DEV_SER_A,%D0
                    BNE       2f
                    BSR       serInitA
                    BRA       1f

2:                  CMPI.B    #DEV_SER_B,%D0
                    BNE       3f
                    BSR       serInitB
                    BRA       1f

3:                  CMPI.B    #DEV_USB,%D0
                    BEQ       1f

                    PUTS      strUnknownDevice
                    PUTCH     %D0
                    BSR       newLine

1:                  MOVE.B    %D0,device
                    RTS

* ----------------------------------------------------------------------------------
* Get a keyboard status in %D0, Z= nothing, 2 = char present
* ----------------------------------------------------------------------------------
keystat:            CMPI.B    #DEV_PROP,device
                    BEQ       p_keystat
                    CMPI.B    #DEV_SER_A,device
                    BEQ       a_keystat
                    CMPI.B    #DEV_SER_B,device
                    BEQ       b_keystat
                    CMPI.B    #DEV_USB,device
                    BEQ       u_keystat
                    RTS


* ----------------------------------------------------------------------------------
* Output a character from %D1.B
* ----------------------------------------------------------------------------------
outch:              CMPI.B    #DEV_PROP,device
                    BEQ       p_outch
                    CMPI.B    #DEV_SER_A,device
                    BEQ       a_outch
                    CMPI.B    #DEV_SER_B,device
                    BEQ       b_outch
                    CMPI.B    #DEV_USB,device
                    BEQ       u_outch
                    RTS

* ----------------------------------------------------------------------------------
* Input a character into %D1.B
* ----------------------------------------------------------------------------------
inch:               CMPI.B    #DEV_PROP,device
                    BEQ       p_inch
                    CMPI.B    #DEV_SER_A,device
                    BEQ       a_inch
                    CMPI.B    #DEV_SER_B,device
                    BEQ       b_inch
                    CMPI.B    #DEV_USB,device
                    BEQ       u_inch
                    RTS

*---------------------------------------------------------------------------------------------------------
                    .section  .rodata.strings
                    .align(2)
strUnknownDevice:   .asciz    "Unknown I/O device "

          .end
