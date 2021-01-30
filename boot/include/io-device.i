DEV_PROP            =         'P'                                     | Propeller
DEV_SER_A           =         'A'                                     | Serial port A
DEV_SER_B           =         'B'                                     | Serial port B
DEV_USB             =         'U'                                     | USB port

* ----------------------------------------------------------------------------------
* The lower 2 bits of the IOBYTE are used to configure the console device at boot
* ----------------------------------------------------------------------------------
IO_PROP             =         0x00                                    | Propeller console
IO_SER_A            =         0x01                                    | Serial port A
IO_SER_B            =         0x02                                    | Serial port B
IO_USB              =         0x03                                    | USB port

IOBYTE              =         __ports_start__ + 0xEF                  | IOByte Port
