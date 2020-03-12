                    .include  "include/macros.i"

                    .text

                    .global   biosHandler
                    .global   readSector
                    .global   writeSector

*-----------------------------------------------------------------------------------------------------
* Trap 15 - Handle calls from the bios
*-----------------------------------------------------------------------------------------------------
biosHandler:        CMPI      #functionCount,%D0
                    BCC       ret
                    LSL       #2,%D0                        | multiply bios function by 4
                    LEA       functionTable,%A5
                    MOVE.L    (%A5,%D0.W),%A5               | get handler address
                    JSR       (%A5)                         | call handler
ret:                RTE


*-----------------------------------------------------------------------------------------------------
* Dummy function
*-----------------------------------------------------------------------------------------------------
unused:             PUTS      strUnused
                    BSR       writeHexByte
                    BSR       newLine
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
* %D1.L = LBA, %D2.B low = count, %D2.B high = disk, %A0 destination address
*-----------------------------------------------------------------------------------------------------
readSector:         CLR.L     %D0
                    SWAP      %D2
                    MOVE.B    %D2,%D0                       | Selected drive
                    MULU.W    #0x2000,%D0                   | Calculate offset 1024 tracks * 32 sectors/track * 512 /128
                    ADD.L     %D1,%D0                       | Add the requested LBA value
                    BSR       setLBA

                    CLR.L     %D0                           | 
                    SWAP      %D2
                    MOVE.B    %D2,%D0                       | Convert to sectors
                    MOVE.L    %A0,%A2                       | Buffer address
                    BSR       readSectors                   | Read the sectors

                    RTS

*-----------------------------------------------------------------------------------------------------
* write sector
* %D1.L = LBA, %D2.B low = count, %D2.B high = disk, %A0 source address
*-----------------------------------------------------------------------------------------------------
writeSector:        CLR.L     %D0
                    SWAP      %D2
                    MOVE.B    %D2,%D0                       | Selected drive
                    MULU.W    #0x2000,%D0                   | Calculate offset 1024 tracks * 32 sectors/track * 512 /128
                    ADD.L     %D1,%D0                       | Add the requested LBA value
                    BSR       setLBA

                    CLR.L     %D0
                    SWAP      %D2
                    MOVE.B    %D2,%D0                       | Sectors to read
                    MOVE.L    %A0,%A2                       | Buffer address

                    BSR       writeSectors                  | Write the sectors

                    RTS

*-----------------------------------------------------------------------------------------------------
* The function table
*-----------------------------------------------------------------------------------------------------
                    .section  .rodata.cmdTable
                    .align(2)

functionTable:
                    .long     unused                        | Function 0
                    .long     unused                        | Function 1
                    .long     consoleStatus                 | Function 2
                    .long     consoleIn                     | Function 3
                    .long     consoleOut                    | Function 4
                    .long     readSector                    | Function 5
                    .long     writeSector                   | Function 5

functionCount       =         (. - functionTable) / 4

*---------------------------------------------------------------------------------------------------------
                    .section  .rodata.strings
                    .align(2)

strUnused:          .asciz    "\r\nUnused function 0x"
