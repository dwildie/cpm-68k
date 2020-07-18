                    .include  "include/macros.i"
                    .include  "include/disk.i"

                    .text     0
                    .global   _start
                    .global   warmBoot

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
_start:             MOVEA.L   #__bss_start__, %A0                     | Zero bss section
                    MOVEA.L   #__bss_end__, %A1

1:                  CMPA.L    %A0, %A1                                | Initialise each byte to 0x00
                    BEQ       2f
                    MOVE.B    #0x00,(%A0)+
                    BRA       1b

2:                  MOVEA.L   #__data_rom_start__,%A0                 | A copy of the initialised data section is held in ROM
                    MOVEA.L   #__data_start__,%A1                     | Copy it from ROM to RAM
                    MOVEA.L   #__data_end__,%A2

3:                  CMPA.L    %A2, %A1
                    BEQ       4f
                    MOVE.B    (%A0)+,(%A1)+
                    BRA       3b

4:                  BSR       setVectors                              | Setup the interupt vectors
warmBoot:           PUTS      strID                                   | Identification string

                    BSR       initialiseDiskSys                       | Initialise the disk subsystem
                    BSR       initDrives                              | List the available drives
                    BSR       selectDriveA                            | Default to drive A

5:                  BSR       cmdLoop                                 | Into the endless command loop


*---------------------------------------------------------------------------------------------------------
                    .section  .rodata.strings
                    .align(2)
                    .global   strID
          .ifdef              IS_68000
strID:              .asciz    "S100 68000 Boot Monitor V0.2.1.R3\n\r"
          .endif

          .ifdef              IS_68030
strID:              .asciz    "S100 68030 Boot Monitor V0.2.1.R3\n\r"
          .endif

*---------------------------------------------------------------------------------------------------------
                    .data
                    .align(2)


          .end


