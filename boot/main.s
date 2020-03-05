                    .include  "include/macros.i"

                    .text     0
                    .global   _start

*---------------------------------------------------------------------------------------------------------
* Setup the reset vectors, initial SSP, & PC.  These will appear at 0x000000 immediately afte a hardware reset
*---------------------------------------------------------------------------------------------------------
                    DC.L      __stack_init__
                    DC.L      _start

*---------------------------------------------------------------------------------------------------------
* Offset the start of the code
*---------------------------------------------------------------------------------------------------------
                    .org      0x00000020

*---------------------------------------------------------------------------------------------------------
* Entry point
*---------------------------------------------------------------------------------------------------------
_start:             MOVEA.L   #__bss_start__, %A0           | Zero bss section
                    MOVEA.L   #__bss_end__, %A1

1:                  CMPA.L    %A0, %A1                      | Initialise each byte to 0x00
                    BEQ       2f
                    MOVE.B    #0x00,(%A0)+
                    BRA       1b

2:                  MOVEA.L   #__data_rom_start__,%A0       | A copy of the initialised data section is held in ROM
                    MOVEA.L   #__data_start__,%A1           | Copy it from ROM to RAM
                    MOVEA.L   #__data_end__,%A2

3:                  CMPA.L    %A2, %A1
                    BEQ       4f
                    MOVE.B    (%A0)+,(%A1)+
                    BRA       3b

4:                  BSR       setVectors                    | Setup the interupt vectors
                    PUTS      strID                         | Identification string
                    BSR       initialiseDiskSys             | Initialise the disk subsystem
                    BSR       listDrives                    | List the available drives
                    BSR       selectDriveA                  | Default to drive A
*                    BSR       initIdeDrive                 | Need this for the next read to work, TODO work out why?

                    BSR       cmdLoop                       | Into the endless command loop


*---------------------------------------------------------------------------------------------------------
                    .section  .rodata.strings
                    .align(2)
                    .global   strID

strID:              .asciz    "CP/M 68K S100 Boot Loader V0.0.1\n\r"

*---------------------------------------------------------------------------------------------------------
                    .data
                    .align(2)


          .end


