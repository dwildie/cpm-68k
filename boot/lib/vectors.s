                    .include  "include/macros.i"
                    .include  "include/vectors.i"

                    .text
                    .global   setVectors
                    
*-----------------------------------------------------------------------------------------------------
* Set up the interupt vectors
*-----------------------------------------------------------------------------------------------------
setVectors:         MOVE.L    #busError,VECTOR_BUS_ERR
                    MOVE.L    #addressError,VECTOR_ADD_ERR
                    MOVE.L    #illInstrError,VECTOR_ILLEG_INST
                    MOVE.L    #zeroDivideError,VECTOR_ZERO_DIV
                    MOVE.L    #unexpectedError,VECTOR_CHK
                    MOVE.L    #unexpectedError,VECTOR_TRAPV
                    MOVE.L    #unexpectedError,VECTOR_PRIV_INST
                    MOVE.L    #trace,VECTOR_TRACE
                    MOVE.L    #biosHandler,VECTOR_TRAP
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

