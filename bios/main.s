                    .include  "include/bios.i"

                    .text

                    .global   _init                         | bios initialization entry point
                    .global   handler
                    .global   write,read                    | *** DEBUG

*--------------------------------------------------------------------------------
* Function 0: Initialisation
*--------------------------------------------------------------------------------
_init:
                    MOVEA.L   #__bss_start__,%A0            | Zero bss section
                    MOVEA.L   #__bss_end__,%A1
1:                  CMPA.L    %A0,%A1                       | Initialise each BSS byte to 0x00
                    BEQ       2f
                    MOVE.B    #0x00,(%A0)+
                    BRA       1b

2:                  MOVE.L    #handler,0x8c                 | set up trap #3 handler
                    BSR       initBuffers                   | Initialise the disk buffers
                    CLR.L     %D0                           | log on disk A, user 0
                    RTS

*--------------------------------------------------------------------------------
* Trap handler
*--------------------------------------------------------------------------------
handler:            CMPI      #functionCount,%D0
                    BCC       1f
                    LSL       #2,%D0                        | multiply bios function by 4
                    LEA       functionTable,%A0             | Get offset into table
                    MOVE.L    (%A0,%D0.W),%A1               | get handler address
                    JSR       (%A1)                         | call handler
1:                  RTE

functionTable:
                    .long     _init                         | Function 0,  0x00
                    .long     warmBoot                      | Function 1,  0x01
                    .long     consoleStatus                 | Function 2,  0x02
                    .long     consoleIn                     | Function 3,  0x03
                    .long     consoleOut                    | Function 4,  0x04
                    .long     listOut                       | Function 5,  0x05
                    .long     auxOut                        | Function 6,  0x06
                    .long     auxIn                         | Function 7,  0x07
                    .long     diskHome                      | Function 8,  0x08
                    .long     selectDisk                    | Function 9,  0x09
                    .long     setTrack                      | Function 10, 0x0A
                    .long     setSector                     | Function 11, 0x0B
                    .long     setDMA                        | Function 12, 0x0C
                    .long     read                          | Function 13, 0x0D
                    .long     write                         | Function 14, 0x0E
                    .long     listStatus                    | Function 15, 0x0F
                    .long     sectorTranslate               | Function 16, 0x10
                    .long     setDMA                        | Function 17, 0x11
                    .long     getMemoryTable                | Function 18, 0x12
                    .long     getIOBye                      | Function 19, 0x13
                    .long     setIOByte                     | Function 20, 0x14
                    .long     flush                         | Function 21, 0x15
                    .long     setHandlers                   | Function 22, 0x16

functionCount       =         (. - functionTable) / 4

*--------------------------------------------------------------------------------
* Function 1: Warm boot.
*--------------------------------------------------------------------------------
warmBoot:           JMP       _CCP

*--------------------------------------------------------------------------------
* Function 2: Console status.
* Is character available? Yes %D0 = 1, No %D0 = 0
*--------------------------------------------------------------------------------
consoleStatus:      MOVE.W    #0x2,%D0                      | Function 2
                    TRAP      #MONITOR_TRAP
                    RTS

*--------------------------------------------------------------------------------
* Function 3: Read console character
* Wait until a character is available, return in %D0
*--------------------------------------------------------------------------------
consoleIn:          MOVE.W    #0x3,%D0                      | Function 3
                    TRAP      #MONITOR_TRAP
                    RTS

*--------------------------------------------------------------------------------
* Function 4: Write console character
* Write the character in %D1 to the console
*--------------------------------------------------------------------------------
consoleOut:         MOVE.W    #0x4,%D0                      | Function 4
                    TRAP      #MONITOR_TRAP
                    RTS

*--------------------------------------------------------------------------------
* Function 5: List character output - Not implemented
*--------------------------------------------------------------------------------
listOut:            RTS

*--------------------------------------------------------------------------------
* Function 6: Auxillary output - Not implemented
*--------------------------------------------------------------------------------
auxOut:             RTS

*--------------------------------------------------------------------------------
* Function 7: Auxillary input - Not implemented
*--------------------------------------------------------------------------------
auxIn:              RTS

*--------------------------------------------------------------------------------
* Function 8: Home disk
*--------------------------------------------------------------------------------
diskHome:           CLR.W     selectedTrack
                    CLR.W     selectedSector
                    RTS

*--------------------------------------------------------------------------------
* Function 9: Select disk given by register %D1.B
*--------------------------------------------------------------------------------
selectDisk:         MOVEQ     #0,%D0
                    CMP.B     #DISK_COUNT,%D1               | valid drive number?
                    BPL       1f                            | if no, return 0 in %D0
                    MOVE.B    %D1,selectedDrive             | else, save drive number
                    MOVE.B    selectedDrive,%D0
                    MULU      #DISK_PARAM_HDR_LEN,%D0
                    ADD.L     #diskParamHeader0,%D0         | point %D0 at correct dph
1:                  RTS

*--------------------------------------------------------------------------------
* Function 10: Set track
*--------------------------------------------------------------------------------
setTrack:           MOVE.W    %D1,selectedTrack
                    RTS

*--------------------------------------------------------------------------------
* Function 11: Set sector
*--------------------------------------------------------------------------------
setSector:          MOVE.W    %D1,selectedSector
                    RTS

*--------------------------------------------------------------------------------
* Function 12: Set DMA address
*--------------------------------------------------------------------------------
setDMA:             MOVE.L    %D1,dma
                    RTS

*--------------------------------------------------------------------------------
* Function 13: Read sector
* Read one sector from requested disk, track, sector to dma address
* Return in %D0 00 if ok, else non-zero
*--------------------------------------------------------------------------------
read:               BSR       selectedLBADrive              | Get required D+LBA
                    BSR       getSectorIndex                | Calculate the index for the CPM sector into the HDD sector

                    MOVE.W    %D1,-(%SP)                    | CPM Sector index
                    MOVE.L    dma,-(%SP)                    | Destination addres
                    MOVE.L    %D0,-(%SP)                    | D+LBA
                    BSR       bufferedRead
                    ADD.L     #0x0A,%SP

                    MOVE.L    #0,%D0                        | ** TODO Add some error handling ****
                    RTS


*--------------------------------------------------------------------------------
* Function 14: Write sector
* Write one sector to requested disk, track, sector from dma address
* %D1.W: 0 = Normal write
*        1 = write to a directory sector
*        2 = write to first sector of new block
* Return 0 in %D0 if ok, else non-zero
*--------------------------------------------------------------------------------
write:              MOVE.W    %D1,%D3
                    BSR       selectedLBADrive              | Get required D+LBA
                    BSR       getSectorIndex                | Calculate the index for the CPM sector into the HDD sector

                    MOVE.W    %D1,-(%SP)                    | CPM Sector index
                    MOVE.L    dma,-(%SP)                    | Source addres
                    MOVE.W    %D3,-(%SP)                    | Write type
                    MOVE.L    %D0,-(%SP)                    | D+LBA
                    BSR       bufferedWrite
                    ADD.L     #0x0C,%SP

                    MOVE.L    #0,%D0                        | ** TODO Add some error handling ****
                    RTS

*--------------------------------------------------------------------------------
* Get the selected LBA and drive
* return in %D0, upper 8bits=drive, lower 24bits = lba
*--------------------------------------------------------------------------------
selectedLBADrive:   MOVEM.L   %D1-%D2,-(%SP)
                    CLR.L     %D0                           | Move the selected drive to the upper 8 bits
                    MOVE.B    selectedDrive,%D0
                    LSL.W     #8,%D0
                    SWAP      %D0

                    CLR.L     %D1                           | LBA into the lower 24 bits
                    MOVE.W    selectedTrack,%D1             | Selected track * sectors/track
                    LEA       diskParamBlock,%A0
                    MULU.W    (%A0),%D1

                    CLR.L     %D2
                    MOVE.W    selectedSector,%D2            | Plus selected sector
                    ADD.L     %D2,%D1

                    LSR.L     #2,%D1                        | Convert to HDD sectors

                    OR.L      %D1,%D0                       | Combine drive & LBA

                    MOVEM.L   (%SP)+,%D1-%D2
                    RTS

*--------------------------------------------------------------------------------
* Calculate the index for the CPM sector into the HDD sector
*--------------------------------------------------------------------------------
getSectorIndex:     CLR.L     %D1
                    MOVE.W    selectedSector,%D1
                    ANDI.L    #03,%D1                       | Assuming 4 CPM sectors per HDD sector
                    RTS

*--------------------------------------------------------------------------------
* Function 15: List status
*--------------------------------------------------------------------------------
listStatus:         MOVE.B    #0xff,%D0
                    RTS

*--------------------------------------------------------------------------------
* Function 16: Sector translate
*--------------------------------------------------------------------------------
sectorTranslate:    MOVE.L    %D1,%D0
                    RTS

*--------------------------------------------------------------------------------
* Function 18: Get address of memory regions table
*--------------------------------------------------------------------------------
getMemoryTable:     MOVE.L    #memoryTable,%D0              | return address of mem region table
                    RTS

*--------------------------------------------------------------------------------
* Function 19: Get IO byte
*--------------------------------------------------------------------------------
getIOBye:           RTS

*--------------------------------------------------------------------------------
* Function 20: Set IO byte
*--------------------------------------------------------------------------------
setIOByte:          RTS

*--------------------------------------------------------------------------------
* Function 21: Flush buffers
*--------------------------------------------------------------------------------
flush:              BSR       flushBuffers
                    CLR.L     %D0                           | return successful
                    RTS

*--------------------------------------------------------------------------------
* Function 22: Set exception handlers
*--------------------------------------------------------------------------------
setHandlers:        ANDI.L    #0xff,%D1                     | do only for exceptions 0 - 255
                    CMPI      #47,%D1
                    BEQ       1f                            | this BIOS doesn't set Trap 15
                    CMPI      #9,%D1                        | or Trace
                    BEQ       1f
                    LSL       #2,%D1                        | multiply exception nmbr by 4
                    MOVEA.L   %D1,%A0
                    MOVE.L    (%A0),%D0                     | return old vector value
                    MOVE.L    %D2,(%A0)                     | insert new vector
1:                  RTS


*-----------------------------------------------------------------------------------------------------
                    .data

currentLBADrive:    .long     -1                            | LBA & drive of current loaded sector, lower 24bits = LBA, upper 8 = drive
dma:                .long     0
selectedTrack:      .word     0                             | track requested by setTrack
selectedSector:     .word     0
selectedDrive:      .byte     0xff                          | drive requested by selectDisk

                    .align(2)
memoryTable:        .word     1                             | 1 memory region
                    .long     __memory_region_start__       | starts at 800 hex
                    .long     __memory_region_length__      | goes until 18000 hex


*-----------------------------------------------------------------------------------------------------
* disk parameter headers
*-----------------------------------------------------------------------------------------------------
diskParamHeader0:   .long     0                             | No translation
                    .word     0                             | scratchpad 1
                    .word     0                             | scratchpad 2
                    .word     0                             | scratchpad 3
                    .long     directoryBuffer               | ptr to directory buffer
                    .long     diskParamBlock                | ptr to disk parameter block
                    .long     0                             | ptr to check vector
                    .long     allocVector0                  | ptr to allocation vector

diskParamHeader1:   .long     0                             | No translation
                    .word     0                             | scratchpad 1
                    .word     0                             | scratchpad 2
                    .word     0                             | scratchpad 3
                    .long     directoryBuffer               | ptr to directory buffer
                    .long     diskParamBlock                | ptr to disk parameter block
                    .long     0                             | ptr to check vector
                    .long     allocVector1                  | ptr to allocation vector

diskParamHeader2:   .long     0                             | No translation
                    .word     0                             | scratchpad 1
                    .word     0                             | scratchpad 2
                    .word     0                             | scratchpad 3
                    .long     directoryBuffer               | ptr to directory buffer
                    .long     diskParamBlock                | ptr to disk parameter block
                    .long     0                             | ptr to check vector
                    .long     allocVector2                  | ptr to allocation vector

diskParamHeader3:   .long     0                             | No translation
                    .word     0                             | scratchpad 1
                    .word     0                             | scratchpad 2
                    .word     0                             | scratchpad 3
                    .long     directoryBuffer               | ptr to directory buffer
                    .long     diskParamBlock                | ptr to disk parameter block
                    .long     0                             | ptr to check vector
                    .long     allocVector3                  | ptr to allocation vector

diskParamHeader4:   .long     0                             | No translation
                    .word     0                             | scratchpad 1
                    .word     0                             | scratchpad 2
                    .word     0                             | scratchpad 3
                    .long     directoryBuffer               | ptr to directory buffer
                    .long     diskParamBlock                | ptr to disk parameter block
                    .long     0                             | ptr to check vector
                    .long     allocVector4                  | ptr to allocation vector

diskParamHeader5:   .long     0                             | No translation
                    .word     0                             | scratchpad 1
                    .word     0                             | scratchpad 2
                    .word     0                             | scratchpad 3
                    .long     directoryBuffer               | ptr to directory buffer
                    .long     diskParamBlock                | ptr to disk parameter block
                    .long     0                             | ptr to check vector
                    .long     allocVector5                  | ptr to allocation vector

diskParamHeader6:   .long     0                             | No translation
                    .word     0                             | scratchpad 1
                    .word     0                             | scratchpad 2
                    .word     0                             | scratchpad 3
                    .long     directoryBuffer               | ptr to directory buffer
                    .long     diskParamBlock                | ptr to disk parameter block
                    .long     0                             | ptr to check vector
                    .long     allocVector6                  | ptr to allocation vector

diskParamHeader7:   .long     0                             | No translation
                    .word     0                             | scratchpad 1
                    .word     0                             | scratchpad 2
                    .word     0                             | scratchpad 3
                    .long     directoryBuffer               | ptr to directory buffer
                    .long     diskParamBlock                | ptr to disk parameter block
                    .long     0                             | ptr to check vector
                    .long     allocVector7                  | ptr to allocation vector

diskParamHeader8:   .long     0                             | No translation
                    .word     0                             | scratchpad 1
                    .word     0                             | scratchpad 2
                    .word     0                             | scratchpad 3
                    .long     directoryBuffer               | ptr to directory buffer
                    .long     diskParamBlock                | ptr to disk parameter block
                    .long     0                             | ptr to check vector
                    .long     allocVector8                  | ptr to allocation vector

diskParamHeader9:   .long     0                             | No translation
                    .word     0                             | scratchpad 1
                    .word     0                             | scratchpad 2
                    .word     0                             | scratchpad 3
                    .long     directoryBuffer               | ptr to directory buffer
                    .long     diskParamBlock                | ptr to disk parameter block
                    .long     0                             | ptr to check vector
                    .long     allocVector9                  | ptr to allocation vector

*-----------------------------------------------------------------------------------------------------
* Disk parameter block
*-----------------------------------------------------------------------------------------------------
diskParamBlock:     .word     32                            | sectors per track
                    .byte     4                             | block shift
                    .byte     15                            | block mask
                    .byte     0                             | extent mask
                    .byte     0                             | dummy fill
                    .word     2047                          | disk size
                    .word     255                           | 64 directory entries
                    .word     0                             | directory mask
                    .word     0                             | directory check size
                    .word     0                             | track offset

*-----------------------------------------------------------------------------------------------------
                    .bss

directoryBuffer:    DS.B      128                           | directory buffer

allocVector0:       DS.B      2048                          | allocation vector
allocVector1:       DS.B      2048
allocVector2:       DS.B      2048
allocVector3:       DS.B      2048
allocVector4:       DS.B      2048
allocVector5:       DS.B      2048
allocVector6:       DS.B      2048
allocVector7:       DS.B      2048
allocVector8:       DS.B      2048
allocVector9:       DS.B      2048

          .end

