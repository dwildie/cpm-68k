                    .include  "include/macros.i"
                    .include  "include/vectors.i"
                    .include  "include/serial.i"

*-----------------------------------------------------------------------------------------------------
                    .bss

counts:             .ds.l     7

*-----------------------------------------------------------------------------------------------------

                    .text
                    .global   setVectors
                    .global   showIrqCounts
                    .global   zeroIrqCounts
                    .global   setIrqMask
                    .global   getIrqMask
                    .global   irqHandler                              | DEBUG

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
* Interrupt 1, S100 V5
*-----------------------------------------------------------------------------------------------------
irq1:               MOVEM.L   %D0-%D7/%A0-%A7,-(%SP)
                    MOVE.L    #0x1, %D2
                    BRA       irqHandler

*-----------------------------------------------------------------------------------------------------
* Interrupt 2, S100 V4
*-----------------------------------------------------------------------------------------------------
irq2:               MOVEM.L   %D0-%D7/%A0-%A7,-(%SP)
                    MOVE.L    #0x2, %D2
                    BRA       irqHandler

*-----------------------------------------------------------------------------------------------------
* Interrupt 3, S100 V3
*-----------------------------------------------------------------------------------------------------
irq3:               MOVEM.L   %D0-%D7/%A0-%A7,-(%SP)
                    MOVE.L    #0x3, %D2
                    BRA       irqHandler

*-----------------------------------------------------------------------------------------------------
* Interrupt 4, S100 V2
*-----------------------------------------------------------------------------------------------------
irq4:               PUTS      strInterruptRecvd
                    MOVE.L    #0x4, %D2
                    BRA       irqHandler

*-----------------------------------------------------------------------------------------------------
* Interrupt 5, S100 V1
*-----------------------------------------------------------------------------------------------------
irq5:               MOVEM.L   %D0-%D7/%A0-%A7,-(%SP)
                    MOVE.L    #0x5, %D2
                    BRA       sioIrqHandler
                    BRA       irqHandler
*-----------------------------------------------------------------------------------------------------
* Interrupt 6, S100 V0
*-----------------------------------------------------------------------------------------------------
irq6:               MOVEM.L   %D0-%D7/%A0-%A7,-(%SP)
                    MOVE.L    #0x6, %D2
                    BRA       irqHandler

*-----------------------------------------------------------------------------------------------------
* Interrupt 7
*-----------------------------------------------------------------------------------------------------
irq7:               MOVEM.L   %D0-%D7/%A0-%A7,-(%SP)
                    MOVE.L    #0x7, %D2
                    BRA       irqHandler

*-----------------------------------------------------------------------------------------------------
* Serial I/O IRQ Handler
*-----------------------------------------------------------------------------------------------------
sioIrqHandler:      MOVE.L    #3,%D1                                  | Read port A, register 3 - IP
                    BSR       serValA
                    MOVE.L    %D0,%D3

                    MOVE.L    #0,%D1                                  | Read port A, register 0 - status
                    BSR       serValA
                    MOVE.L    %D0,%D4

                    MOVE.B    #'S',%D0                                | Display status value
                    BSR       writeCh
                    MOVE.B    %D4,%D0
                    BSR       writeHexByte

                    MOVE.B    #',',%D0
                    BSR       writeCh
                    MOVE.B    #'I',%D0                                | Display IP value
                    BSR       writeCh
                    MOVE.B    %D3,%D0
                    BSR       writeHexByte

                    BTST      #ZSCC_B_RX_IP,%D3                       | Check if Channel B Rx IP
                    BEQ       1f

                    MOVE.B    #',',%D0
                    BSR       writeCh
                    MOVE.B    #'B',%D0
                    BSR       writeCh
                    MOVE.B    ZSCC_B_DATA,%D0                         | Read a byte from channel B
                    BSR       writeCh

1:                  BTST      #ZSCC_B_TX_IP,%D3                       | Check if Channel B Tx IP
                    BEQ       2f

                    MOVE.L    #0x28,%D0                               | Issue "Reset Tx Int pending" cmd to 8530
                    MOVE.L    #0,%D1
                    BSR       serCmdB

2:                  BTST      #ZSCC_A_RX_IP,%D3                       | Check if Channel A Rx IP
                    BEQ       3f

                    MOVE.B    #',',%D0
                    BSR       writeCh
                    MOVE.B    #'A',%D0
                    BSR       writeCh
                    MOVE.B    ZSCC_A_DATA,%D0                         | Read a byte from channel A
                    BSR       writeCh

3:                  BTST      #ZSCC_A_TX_IP,%D3                       | Check if Channel A Tx IP
                    BEQ       4f

                    MOVE.L    #0x28,%D0                               | Issue "Reset Tx Int pending" cmd to 8530
                    MOVE.L    #0,%D1
                    BSR       serCmdA

4:                  MOVE.L    #0x38,%D0                               | Issue "Reset Highest IUS" cmd to 8530
                    MOVE.L    #0,%D1
                    BSR       serCmdA

                    MOVE.B    #' ',%D0
                    BSR       writeCh

                    BRA       irqHandler

*-----------------------------------------------------------------------------------------------------
* IRQ Handler
*-----------------------------------------------------------------------------------------------------
irqHandler:         LEA       counts,%A0
                    LSL.L     #2,%D2
                    ADD.L     #1,-4(%A0,%D2)
                    MOVEM.L   (%SP)+,%D0-%D7/%A0-%A7
                    RTE

*-----------------------------------------------------------------------------------------------------
* Set the IRQ mask to the value in D0
*-----------------------------------------------------------------------------------------------------
setIrqMask:         AND       #0x7,%D0                                | 3 least significant bits
                    LSL       #8,%D0
                    MOVE      %SR,%D1
                    AND       #0xF800,%D1
                    OR        %D0,%D1
                    MOVE      %D1,%SR
                    RTS

*-----------------------------------------------------------------------------------------------------
* Get the IRQ mask
*-----------------------------------------------------------------------------------------------------
getIrqMask:         MOVE      %SR,%D0                                 | Retrieve the current IRQ Mask
                    LSR       #8,%D0
                    AND       #0x7,%D0
                    RTS

*-----------------------------------------------------------------------------------------------------
* Zero the irq counts
*-----------------------------------------------------------------------------------------------------
zeroIrqCounts:      BSR       getIrqMask
                    MOVE.L    %D0,-(%SP)

                    MOVE.L    #7,%D0
                    BSR       setIrqMask

                    LEA       counts,%A0                              | Base of the counts array
                    MOVE.L    #0,%D1                                  | Start a zero

1:                  MOVE.L    %D1,%D0
                    LSL.L     #2,%D0
                    MOVE.L    #0,0(%A0,%D0)                           | Zero the counter

                    CMPI.B    #6,%D1                                  | All done
                    BEQ       2f
                    ADD.L     #1,%D1                                  | Next counter
                    BRA       1b

2:                  MOVE.L    (%SP)+,%D0
                    BSR       setIrqMask
                    RTS

*-----------------------------------------------------------------------------------------------------
* Display the current irq counts
*-----------------------------------------------------------------------------------------------------
showIrqCounts:      BSR       getIrqMask
                    MOVE.L    %D0,-(%SP)

                    MOVE.L    #7,%D0
                    BSR       setIrqMask

                    PUTS      strIrqCounts
                    LEA       counts,%A0
                    MOVE.L    #0,%D1

1:                  PUTCH     #'['
                    MOVE.L    %D1,%D0
                    ADD.L     #1,%D0
                    BSR       writeHexDigit
                    PUTCH     #']'
                    PUTCH     #' '
                    MOVE.L    %D1,%D0
                    LSL.L     #2,%D0
                    MOVE.L    0(%A0,%D0),%D0
                    BSR       writeHexLong
                    BSR       newLine

                    CMPI.B    #6,%D1
                    BEQ       2f
                    ADD.L     #1,%D1
                    BRA       1b

2:                  MOVE.L    (%SP)+,%D0
                    BSR       setIrqMask
                    RTS

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
strIrqCounts:       .asciz    "\r\nInterrupt counts:\r\n"

