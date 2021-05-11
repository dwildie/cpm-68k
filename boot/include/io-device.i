DEV_PROP            =         'P'                                     | Propeller
DEV_SER_A           =         'A'                                     | Serial port A
DEV_SER_B           =         'B'                                     | Serial port B
DEV_USB             =         'U'                                     | USB port

* ----------------------------------------------------------------------------------
* The lower 2 bits of the IOBYTE are used to configure the console device at boot
* ----------------------------------------------------------------------------------
IO_USB              =         0x00                                    | USB port
IO_SER_A            =         0x01                                    | Serial port A
IO_PROP             =         0x02                                    | Serial port B
IO_DETECT           =         0x03                                    | Propeller console

IOBYTE              =         __ports_start__ + 0xEF                  | IOByte Port
