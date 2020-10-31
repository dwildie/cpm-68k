*---------------------------------------------------------------------------------------------------------
* S100Computers Serial I/O Board ports
*---------------------------------------------------------------------------------------------------------
ZSCC_B_CTL          =         __ports_start__ + 0xA0
ZSCC_A_CTL          =         ZSCC_B_CTL + 0x1
ZSCC_B_DATA         =         ZSCC_B_CTL + 0x2
ZSCC_A_DATA         =         ZSCC_B_CTL + 0x3

USB_STATUS          =         __ports_start__ + 0xAA
USB_DATA            =         __ports_start__ + 0xAC

SER_TBE             =         0x04
SER_RDA             =         0x01

USB_TBE             =         0x80
USB_RDA             =         0x40
