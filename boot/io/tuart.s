                    .include  "include/macros.i"

* ----------------------------------------------------------------------------------
* Test routines for a Cromemco TU-ART board
* ----------------------------------------------------------------------------------
                    .text

                    .global   tuart_init
                    .global   tuart_a_status, tuart_a_init
                    .global   tuart_b_status, tuart_b_init

PORT_A              =         __ports_start__ + 0x20
PORT_B              =         __ports_start__ + 0x50

PORT_STATUS         =         0x00
PORT_DATA           =         0x01
PORT_CMD            =         0x02
PORT_MASK           =         0x03

PORT_A_STATUS       =         PORT_A + PORT_STATUS
PORT_A_DATA         =         PORT_A + PORT_DATA
PORT_A_CMD          =         PORT_A + PORT_CMD
PORT_A_MASK         =         PORT_A + PORT_MASK

PORT_B_STATUS       =         PORT_B + PORT_STATUS
PORT_B_DATA         =         PORT_B + PORT_DATA
PORT_B_CMD          =         PORT_B + PORT_CMD
PORT_B_MASK         =         PORT_B + PORT_MASK

CMD_RESET           =         0x09                                    | Reset + INTA command

B9600               =         0xC0
MASK_RDA            =         0x10
MASK_TBE            =         0x20
* ----------------------------------------------------------------------------------
* Initialise ports a & b
* ----------------------------------------------------------------------------------
tuart_init:         BSR       tuart_a_init
                    BSR       tuart_b_init
                    RTS

* ----------------------------------------------------------------------------------
* Initialise port a
* ----------------------------------------------------------------------------------
tuart_a_init:       PUTS      strInitA
                    MOVE.B    #CMD_RESET, PORT_A_CMD                  | Reset the UART & enable INT Ack
                    MOVE.B    #B9600, PORT_A_STATUS                   | 9600 baud, 1 stop bit
                    MOVE.B    #MASK_RDA, PORT_A_MASK                  | RDA interrupt only
                    RTS

* ----------------------------------------------------------------------------------
* Initialise port b
* ----------------------------------------------------------------------------------
tuart_b_init:       PUTS      strInitB
                    MOVE.B    #CMD_RESET, PORT_B_CMD                  | Reset the UART & enable INT Ack
                    MOVE.B    #B9600, PORT_B_STATUS                   | 9600 baud, 1 stop bit
                    MOVE.B    #0x0, PORT_B_MASK                       | No interrupts
                    RTS

* ----------------------------------------------------------------------------------
* Display status, data & interrupt address registers for port a
* ----------------------------------------------------------------------------------
tuart_a_status:     PUTS      strStatusA
                    MOVE.B    PORT_A_STATUS,%D0
                    BSR       writeHexByte
                    PUTS      strData
                    MOVE.B    PORT_A_DATA,%D0
                    BSR       writeHexByte
                    PUTS      strIntAddr
                    MOVE.B    PORT_A_MASK,%D0
                    BSR       writeHexByte
                    BSR       newLine
                    RTS

* ----------------------------------------------------------------------------------
* Display status, data & interrupt address registers for port b
* ----------------------------------------------------------------------------------
tuart_b_status:     PUTS      strStatusB
                    MOVE.B    PORT_B_STATUS,%D0
                    BSR       writeHexByte
                    PUTS      strData
                    MOVE.B    PORT_B_DATA,%D0
                    BSR       writeHexByte
                    PUTS      strIntAddr
                    MOVE.B    PORT_B_MASK,%D0
                    BSR       writeHexByte
                    BSR       newLine
                    RTS

* ----------------------------------------------------------------------------------
                    .section  .rodata.strings
                    .align(2)

strInitA:           .asciz    "Port A: init\r\n"
strInitB:           .asciz    "Port B: init\r\n"
strStatusA:         .asciz    "Port A: status=0x"
strStatusB:         .asciz    "Port B: status=0x"
strData:            .asciz    ", data=0x"
strIntAddr:         .asciz    ", addr=0x"

