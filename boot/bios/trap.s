                    .include  "include/macros.i"

                    .text

                    .global   biosHandler

*-----------------------------------------------------------------------------------------------------
* Trap 15 - Handle calls from the bios
*-----------------------------------------------------------------------------------------------------
biosHandler:        CMPI      #functionCount,%D0
                    BCC       1f
                    LSL       #2,%D0                                  | multiply bios function by 4
                    LEA       functionTable,%A5
                    MOVE.L    (%A5,%D0.W),%A5                         | get handler address
                    JSR       (%A5)                                   | call handler
1:                  RTE


*-----------------------------------------------------------------------------------------------------
* Dummy function
*-----------------------------------------------------------------------------------------------------
unused:             PUTS      strUnused
                    BSR       writeHexByte
                    BSR       newLine
                    RTS

*-----------------------------------------------------------------------------------------------------
* Initialise
*-----------------------------------------------------------------------------------------------------
init:               BSR       initDisks
*                   PUTS      strInit
                    CLR.L     %D0
                    RTS

*-----------------------------------------------------------------------------------------------------
* Console status
*-----------------------------------------------------------------------------------------------------
consoleStatus:      BSR       keystat
                    BEQ       1f
                    MOVE.W    #0xFF,%D0
1:                  RTS

*-----------------------------------------------------------------------------------------------------
* Console in
*-----------------------------------------------------------------------------------------------------
consoleIn:          BSR       readCh
                    RTS

*-----------------------------------------------------------------------------------------------------
* Console out
*-----------------------------------------------------------------------------------------------------
consoleOut:         MOVE.B    %D1,%D0
                    BSR       writeCh
                    RTS

*-----------------------------------------------------------------------------------------------------
* Read sector
* %D1.L = LBA, %D2.W low = count, %D2.W high = disk, %A0 destination address
*-----------------------------------------------------------------------------------------------------
readSector:         MOVE.L    %A0,-(%SP)                              | Param - destination buffer address
                    MOVE.W    %D2,-(%SP)                              | Param - count
                    SWAP      %D2
                    MOVE.W    %D2,-(%SP)                              | Param - drive
                    MOVE.L    %D1,-(%SP)                              | Param - LBA
                    BSR       readDiskSector
                    ADD       #0x0c,%SP
                    RTS

*-----------------------------------------------------------------------------------------------------
* write sector
* %D1.L = LBA, %D2.W low = count, %D2.W high = disk, %A0 source address
*-----------------------------------------------------------------------------------------------------
writeSector:        MOVE.L    %A0,-(%SP)                              | Param - destination buffer address
                    MOVE.W    %D2,-(%SP)                              | Param - count
                    SWAP      %D2
                    MOVE.W    %D2,-(%SP)                              | Param - drive
                    MOVE.L    %D1,-(%SP)                              | Param - LBA
                    BSR       writeDiskSector
                    ADD       #0x0c,%SP
                    RTS

*-----------------------------------------------------------------------------------------------------
* The function table
*-----------------------------------------------------------------------------------------------------
                    .section  .rodata.cmdTable
                    .align(2)

functionTable:
                    .long     init                                    | Function 0
                    .long     unused                                  | Function 1
                    .long     consoleStatus                           | Function 2
                    .long     consoleIn                               | Function 3
                    .long     consoleOut                              | Function 4
                    .long     readSector                              | Function 5
                    .long     writeSector                             | Function 5

functionCount       =         (. - functionTable) / 4

*---------------------------------------------------------------------------------------------------------
                    .section  .rodata.strings
                    .align(2)

strUnused:          .asciz    "\r\nUnused function 0x"
strInit:            .asciz    "CP/M-68K S100 Virtual Disk Initialised\r\n"
