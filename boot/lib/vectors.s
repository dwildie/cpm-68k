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

                    MOVE.L    #irq1,VECTOR_IRQ_1
                    MOVE.L    #irq2,VECTOR_IRQ_2
                    MOVE.L    #irq3,VECTOR_IRQ_3
                    MOVE.L    #irq4,VECTOR_IRQ_4
                    MOVE.L    #irq5,VECTOR_IRQ_5
                    MOVE.L    #irq6,VECTOR_IRQ_6
                    MOVE.L    #irq7,VECTOR_IRQ_7

                    MOVE.L    #biosHandler,VECTOR_TRAP
                    RTS

*-----------------------------------------------------------------------------------------------------
* Exception handler:
*-----------------------------------------------------------------------------------------------------
busError:           PUTS      strBusError
                    BSR       readCh
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
                    BSR       readCh
                    RTE

*-----------------------------------------------------------------------------------------------------
* Exception handler:
*-----------------------------------------------------------------------------------------------------
zeroDivideError:    PUTS      strZeroDivideError
                    BSR       readCh
                    RTE

*-----------------------------------------------------------------------------------------------------
* Exception handler:
*-----------------------------------------------------------------------------------------------------
unexpectedError:    PUTS      strUnexpectedError
                    BSR       readCh
                    RTE

*-----------------------------------------------------------------------------------------------------
* Exception handler:
*-----------------------------------------------------------------------------------------------------
trace:              PUTS      strTrace
                    RTE

*-----------------------------------------------------------------------------------------------------
* Interrupt 1
*-----------------------------------------------------------------------------------------------------
irq1:               PUTS      strInterruptRecvd
                    PUTCH     #'1'
                    BSR       newLine
                    RTE

*-----------------------------------------------------------------------------------------------------
* Interrupt 2
*-----------------------------------------------------------------------------------------------------
irq2:               PUTS      strInterruptRecvd
                    PUTCH     #'2'
                    BSR       newLine
                    RTE

*-----------------------------------------------------------------------------------------------------
* Interrupt 3
*-----------------------------------------------------------------------------------------------------
irq3:               PUTS      strInterruptRecvd
                    PUTCH     #'3'
                    BSR       newLine
                    RTE

*-----------------------------------------------------------------------------------------------------
* Interrupt 4
*-----------------------------------------------------------------------------------------------------
irq4:               PUTS      strInterruptRecvd
                    PUTCH     #'4'
                    BSR       newLine
                    RTE

*-----------------------------------------------------------------------------------------------------
* Interrupt 5
*-----------------------------------------------------------------------------------------------------
irq5:               PUTS      strInterruptRecvd
                    PUTCH     #'5'
                    BSR       newLine
                    RTE

*-----------------------------------------------------------------------------------------------------
* Interrupt 6
*-----------------------------------------------------------------------------------------------------
irq6:               PUTS      strInterruptRecvd
                    PUTCH     #'6'
                    BSR       newLine
                    RTE

*-----------------------------------------------------------------------------------------------------
* Interrupt 7
*-----------------------------------------------------------------------------------------------------
irq7:               PUTS      strInterruptRecvd
                    PUTCH     #'7'
                    BSR       newLine
                    RTE

*---------------------------------------------------------------------------------------------------------
                    .section  .rodata.strings
                    .align(2)

strBusError:        .asciz    "\r\nBus error, press any key to continue\r\n"
strAddressError:    .asciz    "\r\nAddress error, press any key to continue\r\n"
strIllInstrError:   .asciz    "\r\nIllegal instruction error, press any key to continue\r\n"
strZeroDivideError: .asciz    "\r\nDivide by zero error, press any key to continue\r\n"
strUnexpectedError: .asciz    "\r\nUnexpected exception, press any key to continue\r\n"
strTrace:           .asciz    "\r\nTrace:\r\n"
strInterruptRecvd:  .asciz    "\r\nInterrupt received "

