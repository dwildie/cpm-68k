                    .include  "include/bios.i"

                    .text

                    .global   _init                                   | bios initialization entry point
                    .global   handler
                    .global   write,read                              | *** DEBUG
                    .global   _end                                    | End of CPM
                    .global   _ccp

*--------------------------------------------------------------------------------
* Function 0: Initialisation
*--------------------------------------------------------------------------------
_init:
          .ifne               _GNU_

                    MOVEA.L   #__bss_start__,%A0                      | Zero bss section
                    MOVEA.L   #__bss_end__,%A1
in_1:               CMPA.L    %A0,%A1                                 | Initialise each BSS byte to 0x00
                    BEQ       in_2
                    MOVE.B    #0x00,(%A0)+
                    BRA       in_1
          .endif

in_2:               LEA       handler,%A0
                    MOVE.L    %A0,TRAP_3                              | set up trap #3 handler
                    BSR       initBuffers                             | Initialise the disk buffers

                    MOVE.W    #0x0D,%D1
                    BSR       conOut
                    MOVE.W    #0x0A,%D1
                    BSR       conOut

                    LEA       strInit,%A0                             | Display initialisation string
                    BSR       puts

                    MOVE.W    #0x0D,%D1
                    BSR       conOut
                    MOVE.W    #0x0A,%D1
                    BSR       conOut

                    MOVE.W    #MON_INIT,%D0                           | Function 0, initialise
                    TRAP      #MON_TRAP

                    CLR.L     %D0                                     | log on disk A, user 0

                    RTS

*--------------------------------------------------------------------------------
* Trap handler
*--------------------------------------------------------------------------------
handler:            CMPI.W    #funcCount,%D0
                    BCC       h1
                    EXT.L     %D0
                    LSL.L     #2,%D0                                  | multiply bios function by 4
                    LEA       fTable,%A0                              | Get offset into table
                    MOVE.L    (%A0,%D0.W),%A1                         | get handler address
                    JSR       (%A1)                                   | call handler
h1:                 RTE

*--------------------------------------------------------------------------------
* Function table
*--------------------------------------------------------------------------------
                    .even
fTable:             .long     _init                                   | Function 0,  0x00
                    .long     warmBoot                                | Function 1,  0x01
                    .long     conStatus                               | Function 2,  0x02
                    .long     conIn                                   | Function 3,  0x03
                    .long     conOut                                  | Function 4,  0x04
                    .long     listOut                                 | Function 5,  0x05
                    .long     auxOut                                  | Function 6,  0x06
                    .long     auxIn                                   | Function 7,  0x07
                    .long     diskHome                                | Function 8,  0x08
                    .long     selDisk                                 | Function 9,  0x09
                    .long     setTrack                                | Function 10, 0x0A
                    .long     setSector                               | Function 11, 0x0B
                    .long     setDMA                                  | Function 12, 0x0C
                    .long     read                                    | Function 13, 0x0D
                    .long     write                                   | Function 14, 0x0E
                    .long     listStatus                              | Function 15, 0x0F
                    .long     secTranslate                            | Function 16, 0x10
                    .long     setDMA                                  | Function 17, 0x11
                    .long     getMemTable                             | Function 18, 0x12
                    .long     getIOBye                                | Function 19, 0x13
                    .long     setIOByte                               | Function 20, 0x14
                    .long     flush                                   | Function 21, 0x15
                    .long     setHandlers                             | Function 22, 0x16

*funcCount       =         (. - fTable) / 4
funcCount           =         23

*--------------------------------------------------------------------------------
* Function 1: Warm boot.
*--------------------------------------------------------------------------------
warmBoot:           JMP       _ccp

*--------------------------------------------------------------------------------
* Function 2: Console status.
* Is character available? Yes %D0 = 1, No %D0 = 0
*--------------------------------------------------------------------------------
conStatus:          MOVE.W    #MON_CSTAT,%D0                          | Function 2
                    TRAP      #MON_TRAP
                    RTS

*--------------------------------------------------------------------------------
* Function 3: Read console character
* Wait until a character is available, return in %D0
*--------------------------------------------------------------------------------
conIn:              MOVE.W    #MON_CIN,%D0                            | Function 3
                    TRAP      #MON_TRAP
                    RTS

*--------------------------------------------------------------------------------
* Function 4: Write console character
* Write the character in %D1 to the console
*--------------------------------------------------------------------------------
conOut:             MOVE.W    #MON_COUT,%D0                           | Function 4
                    TRAP      #MON_TRAP
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
diskHome:           CLR.W     selTrack
                    CLR.W     selSector
                    RTS

*--------------------------------------------------------------------------------
* Function 9: Select disk given by register %D1.B
*--------------------------------------------------------------------------------
selDisk:            MOVEQ     #0,%D0
                    CMP.B     #DISK_COUNT,%D1                         | valid drive number?
                    BPL       sd1                                     | if no, return 0 in %D0
                    MOVE.B    %D1,selDrive                            | else, save drive number
                    MOVE.B    selDrive,%D0
                    MULU      #DPH_LEN,%D0
                    ADD.L     #dpHdr0,%D0                             | point %D0 at correct dph
sd1:                RTS

*--------------------------------------------------------------------------------
* Function 10: Set track
*--------------------------------------------------------------------------------
setTrack:           MOVE.W    %D1,selTrack
                    RTS

*--------------------------------------------------------------------------------
* Function 11: Set sector
*--------------------------------------------------------------------------------
setSector:          MOVE.W    %D1,selSector
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
read:               BSR       selectedLBADrive                        | Get required D+LBA
                    BSR       getSectorIndex                          | Calculate the index for the CPM sector into the HDD sector

                    MOVE.W    %D1,-(%SP)                              | CPM Sector index
                    MOVE.L    dma,-(%SP)                              | Destination addres
                    MOVE.L    %D0,-(%SP)                              | D+LBA
                    BSR       buffRead
                    ADD.L     #0x0A,%SP

                    MOVE.L    #0,%D0                                  | ** TODO Add some error handling ****
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
                    BSR       selectedLBADrive                        | Get required D+LBA
                    BSR       getSectorIndex                          | Calculate the index for the CPM sector into the HDD sector

                    MOVE.W    %D1,-(%SP)                              | CPM Sector index
                    MOVE.L    dma,-(%SP)                              | Source addres
                    MOVE.W    %D3,-(%SP)                              | Write type
                    MOVE.L    %D0,-(%SP)                              | D+LBA
                    BSR       buffWrite
                    ADD.L     #0x0C,%SP

                    MOVE.L    #0,%D0                                  | ** TODO Add some error handling ****
                    RTS

*--------------------------------------------------------------------------------
* Get the selected LBA and drive
* return in %D0, upper 8bits=drive, lower 24bits = lba
*--------------------------------------------------------------------------------
selectedLBADrive:   MOVEM.L   %D1-%D2,-(%SP)
                    CLR.L     %D0                                     | Move the selected drive to the upper 8 bits
                    MOVE.B    selDrive,%D0
                    LSL.W     #8,%D0
                    SWAP      %D0

                    CLR.L     %D1                                     | LBA into the lower 24 bits
                    MOVE.W    selTrack,%D1                            | Selected track * sectors/track
                    LEA       dpBlock,%A0
                    MULU.W    (%A0),%D1

                    CLR.L     %D2
                    MOVE.W    selSector,%D2                           | Plus selected sector
                    ADD.L     %D2,%D1

                    LSR.L     #2,%D1                                  | Convert to HDD sectors

                    OR.L      %D1,%D0                                 | Combine drive & LBA

                    MOVEM.L   (%SP)+,%D1-%D2
                    RTS

*--------------------------------------------------------------------------------
* Calculate the index for the CPM sector into the HDD sector
*--------------------------------------------------------------------------------
getSectorIndex:     CLR.L     %D1
                    MOVE.W    selSector,%D1
                    ANDI.L    #03,%D1                                 | Assuming 4 CPM sectors per HDD sector
                    RTS

*--------------------------------------------------------------------------------
* Function 15: List status
*--------------------------------------------------------------------------------
listStatus:         MOVE.B    #0xff,%D0
                    RTS

*--------------------------------------------------------------------------------
* Function 16: Sector translate
*--------------------------------------------------------------------------------
secTranslate:       MOVE.L    %D1,%D0
                    RTS

*--------------------------------------------------------------------------------
* Function 18: Get address of memory regions table
*--------------------------------------------------------------------------------
getMemTable:        MOVE.L    #memTable,%D0                           | return address of mem region table
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
flush:              BSR       flushAll
                    CLR.L     %D0                                     | return successful
                    RTS

*--------------------------------------------------------------------------------
* Function 22: Set exception handlers
*--------------------------------------------------------------------------------
setHandlers:        ANDI.L    #0xff,%D1                               | do only for exceptions 0 - 255
                    CMPI      #47,%D1
                    BEQ       sh1                                     | this BIOS doesn't set Trap 15
                    CMPI      #9,%D1                                  | or Trace
                    BEQ       sh1
                    LSL       #2,%D1                                  | multiply exception nmbr by 4
                    MOVEA.L   %D1,%A0
                    MOVE.L    (%A0),%D0                               | return old vector value
                    MOVE.L    %D2,(%A0)                               | insert new vector
sh1:                RTS

*--------------------------------------------------------------------------------
* Display the string pointed to by %A0
*--------------------------------------------------------------------------------
puts:               MOVE.B    (%A0)+,%D1
                    CMPI.B    #0,%D1
                    BEQ       p1
                    BSR       conOut
                    BRA       puts
p1:                 RTS

*-----------------------------------------------------------------------------------------------------
                    .data

dma:                .long     0
selTrack:           .word     0                                       | track requested by setTrack
selSector:          .word     0
selDrive:           .byte     0xff                                    | drive requested by selDisk

                    .even
memTable:           .word     1                                       | 1 memory region - TPA only
tpaStart:           .long     0x100000                                | Default: Start of the Transient Program Area
tpaSize:            .long     0xEB7FFF                                | Default: Size of the Transient Program Area

*-----------------------------------------------------------------------------------------------------
* disk parameter headers
*-----------------------------------------------------------------------------------------------------
dpHdr0:             .long     0                                       | No translation
                    .word     0                                       | scratchpad 1
                    .word     0                                       | scratchpad 2
                    .word     0                                       | scratchpad 3
                    .long     dirBuffer                               | ptr to directory buffer
                    .long     bpBlock                                 | ptr to the boot disk parameter block
                    .long     0                                       | ptr to check vector
                    .long     allocV0                                 | ptr to allocation vector

dpHdr1:             .long     0                                       | No translation
                    .word     0                                       | scratchpad 1
                    .word     0                                       | scratchpad 2
                    .word     0                                       | scratchpad 3
                    .long     dirBuffer                               | ptr to directory buffer
                    .long     dpBlock                                 | ptr to disk parameter block
                    .long     0                                       | ptr to check vector
                    .long     allocV1                                 | ptr to allocation vector

dpHdr2:             .long     0                                       | No translation
                    .word     0                                       | scratchpad 1
                    .word     0                                       | scratchpad 2
                    .word     0                                       | scratchpad 3
                    .long     dirBuffer                               | ptr to directory buffer
                    .long     dpBlock                                 | ptr to disk parameter block
                    .long     0                                       | ptr to check vector
                    .long     allocV2                                 | ptr to allocation vector

dpHdr3:             .long     0                                       | No translation
                    .word     0                                       | scratchpad 1
                    .word     0                                       | scratchpad 2
                    .word     0                                       | scratchpad 3
                    .long     dirBuffer                               | ptr to directory buffer
                    .long     dpBlock                                 | ptr to disk parameter block
                    .long     0                                       | ptr to check vector
                    .long     allocV3                                 | ptr to allocation vector

dpHdr4:             .long     0                                       | No translation
                    .word     0                                       | scratchpad 1
                    .word     0                                       | scratchpad 2
                    .word     0                                       | scratchpad 3
                    .long     dirBuffer                               | ptr to directory buffer
                    .long     dpBlock                                 | ptr to disk parameter block
                    .long     0                                       | ptr to check vector
                    .long     allocV4                                 | ptr to allocation vector

dpHdr5:             .long     0                                       | No translation
                    .word     0                                       | scratchpad 1
                    .word     0                                       | scratchpad 2
                    .word     0                                       | scratchpad 3
                    .long     dirBuffer                               | ptr to directory buffer
                    .long     dpBlock                                 | ptr to disk parameter block
                    .long     0                                       | ptr to check vector
                    .long     allocV5                                 | ptr to allocation vector

dpHdr6:             .long     0                                       | No translation
                    .word     0                                       | scratchpad 1
                    .word     0                                       | scratchpad 2
                    .word     0                                       | scratchpad 3
                    .long     dirBuffer                               | ptr to directory buffer
                    .long     dpBlock                                 | ptr to disk parameter block
                    .long     0                                       | ptr to check vector
                    .long     allocV6                                 | ptr to allocation vector

dpHdr7:             .long     0                                       | No translation
                    .word     0                                       | scratchpad 1
                    .word     0                                       | scratchpad 2
                    .word     0                                       | scratchpad 3
                    .long     dirBuffer                               | ptr to directory buffer
                    .long     dpBlock                                 | ptr to disk parameter block
                    .long     0                                       | ptr to check vector
                    .long     allocV7                                 | ptr to allocation vector

dpHdr8:             .long     0                                       | No translation
                    .word     0                                       | scratchpad 1
                    .word     0                                       | scratchpad 2
                    .word     0                                       | scratchpad 3
                    .long     dirBuffer                               | ptr to directory buffer
                    .long     dpBlock                                 | ptr to disk parameter block
                    .long     0                                       | ptr to check vector
                    .long     allocV8                                 | ptr to allocation vector

dpHdr9:             .long     0                                       | No translation
                    .word     0                                       | scratchpad 1
                    .word     0                                       | scratchpad 2
                    .word     0                                       | scratchpad 3
                    .long     dirBuffer                               | ptr to directory buffer
                    .long     dpBlock                                 | ptr to disk parameter block
                    .long     0                                       | ptr to check vector
                    .long     allocV9                                 | ptr to allocation vector

*-----------------------------------------------------------------------------------------------------
* Boot disk parameter block
*-----------------------------------------------------------------------------------------------------
bpBlock:            .word     32                                      | sectors per track
                    .byte     4                                       | block shift
                    .byte     15                                      | block mask
                    .byte     0                                       | extent mask
                    .byte     0                                       | dummy fill
                    .word     2047                                    | disk size
                    .word     255                                     | 64 directory entries
                    .word     0                                       | directory mask
                    .word     0                                       | directory check size
                    .word     2                                       | track offset

*-----------------------------------------------------------------------------------------------------
* Disk parameter block
*-----------------------------------------------------------------------------------------------------
dpBlock:            .word     32                                      | sectors per track
                    .byte     4                                       | block shift
                    .byte     15                                      | block mask
                    .byte     0                                       | extent mask
                    .byte     0                                       | dummy fill
                    .word     2047                                    | disk size
                    .word     255                                     | 64 directory entries
                    .word     0                                       | directory mask
                    .word     0                                       | directory check size
                    .word     0                                       | track offset

*-----------------------------------------------------------------------------------------------------
                    .bss
                    .even

dirBuffer:          DS.B      128                                     | directory buffer

allocV0:            DS.B      2048                                    | allocation vector
allocV1:            DS.B      2048
allocV2:            DS.B      2048
allocV3:            DS.B      2048
allocV4:            DS.B      2048
allocV5:            DS.B      2048
allocV6:            DS.B      2048
allocV7:            DS.B      2048
allocV8:            DS.B      2048
allocV9:            DS.B      2048

*---------------------------------------------------------------------------------------------------------
                    .text
                    .even

          .ifne               _GNU_
strInit:            .ascii    "CP/M-68K S100 BIOS V0.1.0 [GNU]"
          .endif

          .ifne               _CPM_
strInit:            .ascii    "CP/M-68K S100 BIOS V0.1.0 [CPM]"
          .endif

                    DC.B      0
          .end
