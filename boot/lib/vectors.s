                    .text
                    .global   setVectors
                    .include  "include/macros.i"
                    .include  "include/vectors.i"
*-----------------------------------------------------------------------------------------------------
* Set up the interupt vectors
*-----------------------------------------------------------------------------------------------------
setVectors:         MOVE.L    #busError,VBUSERR
                    MOVE.L    #addressError,VADDERR
                    MOVE.L    #illInstrError,VILLEGINST
                    MOVE.L    #zeroDivideError,VZERODIV
                    MOVE.L    #unexpectedError,VCHK
                    MOVE.L    #unexpectedError,VTRAPV
                    MOVE.L    #unexpectedError,VPRIVINST
                    MOVE.L    #trace,VTRACE
                    MOVE.L    #biosHandler,VTRAP
                    RTS

*-----------------------------------------------------------------------------------------------------
* Exception handler:
*-----------------------------------------------------------------------------------------------------
busError:           PUTS      strBusError
                    RTE

*-----------------------------------------------------------------------------------------------------
* Exception handler:
*-----------------------------------------------------------------------------------------------------
addressError:       PUTS      strAddressError
                    MOVE.L    2(%SP),%D0
                    BSR       writeHexLong
                    PUTCH     #' '
                    BSR       readCh
                    RTE

*-----------------------------------------------------------------------------------------------------
* Exception handler:
*-----------------------------------------------------------------------------------------------------
illInstrError:      PUTS      strIllInstrError
                    RTE

*-----------------------------------------------------------------------------------------------------
* Exception handler:
*-----------------------------------------------------------------------------------------------------
zeroDivideError:    PUTS      strZeroDivideError
                    RTE

*-----------------------------------------------------------------------------------------------------
* Exception handler:
*-----------------------------------------------------------------------------------------------------
unexpectedError:    PUTS      strUnexpectedError
                    RTE

*-----------------------------------------------------------------------------------------------------
* Exception handler:
*-----------------------------------------------------------------------------------------------------
trace:              PUTS      strTrace
                    RTE

*---------------------------------------------------------------------------------------------------------
                    .section  .rodata.strings
                    .align(2)

strBusError:        .asciz    "\r\nBus error\r\n"
strAddressError:    .asciz    "\r\nAddress error\r\n"
strIllInstrError:   .asciz    "\r\nIllegal instruction error\r\n"
strZeroDivideError: .asciz    "\r\nDivide by zero error\r\n"
strUnexpectedError: .asciz    "\r\nUnexpected exception\r\n"
strTrace:           .asciz    "\r\nTrace:\r\n"

