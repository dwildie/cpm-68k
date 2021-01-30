                    .include  "include/macros.i"
                    .include  "include/disk.i"

                    .text     0
                    .global   _start
                    .global   warmBoot
                    .global   initDataSegs
                    .global   cmxTable

*---------------------------------------------------------------------------------------------------------
* Setup the reset vectors, initial SSP, & PC.  These will appear at 0x000000 immediately afte a hardware reset
*---------------------------------------------------------------------------------------------------------
                    DC.L      __stack_init__
                    DC.L      _start

*---------------------------------------------------------------------------------------------------------
* Offset the start of the code
*---------------------------------------------------------------------------------------------------------
                    .org      0x00000010

cmxTable:           DC.L      cmxInitDrives
                    DC.L      cmxGetDriveStatus
                    DC.L      cmxReadDriveBlock
                    DC.L      cmxWriteDriveBlock
                    DC.L      cmxInitConsole
                    DC.L      cmxOutChar
                    DC.L      cmxInChar

*---------------------------------------------------------------------------------------------------------
* Entry point
*---------------------------------------------------------------------------------------------------------
_start:             BSR       initDataSegs                            | initialise data segments

                    BSR       setVectors                              | Setup the interupt vectors

                    BSR       newLine                                 | Output an * to the default console to show that we are alive
                    PUTCH     #'*'
                    BSR       newLine

                    BSR       ioInit                                  | Initialise the IO subsystem and select the console device

warmBoot:           PUTS      strId1                                  | Identification string
                    PUTS      strId2

                    BSR       initialiseDiskSys                       | Initialise the disk subsystem
                    BSR       initDrives                              | List the available drives
                    BSR       selectDriveA                            | Default to drive A

5:                  BSR       cmdLoop                                 | Into the endless command loop


*---------------------------------------------------------------------------------------------------------
* Initialise the initialised & uninitialised data segments
*---------------------------------------------------------------------------------------------------------
initDataSegs:       MOVEA.L   #__bss_start__, %A0                     | Zero bss section
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

4:                  RTS

*---------------------------------------------------------------------------------------------------------
                    .section  .rodata.strings
                    .align(2)
                    .global   strId1, strId2
          .ifdef              IS_68000
strId1:             .asciz    "S100 68000 Boot Monitor V0.3.0.R1\n\r"
          .endif

          .ifdef              IS_68030
strId1:             .asciz    "S100 68030 Boot Monitor V0.3.0.R1\n\r"
          .endif
strId2:             .asciz    "Damian Wildie, 26/1/2021\r\n\r\n"

*---------------------------------------------------------------------------------------------------------
                    .data
                    .align(2)


          .end


