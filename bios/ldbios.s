                    .include  "include/bios.i"
                    .include  "include/buffer.i"

                    .text

                    .global   _bios                                   | bios initialization entry point

                    .even
*--------------------------------------------------------------------------------
* Function table
*--------------------------------------------------------------------------------
fTable:             .long     initialise                              | Function 0,  0x00
                    .long     notImpl                                 | Function 1,  0x01
                    .long     notImpl                                 | Function 2,  0x02
                    .long     notImpl                                 | Function 3,  0x03
                    .long     consoleOut                              | Function 4,  0x04
                    .long     notImpl                                 | Function 5,  0x05
                    .long     notImpl                                 | Function 6,  0x06
                    .long     notImpl                                 | Function 7,  0x07
                    .long     notImpl                                 | Function 8,  0x08
                    .long     selectDisk                              | Function 9,  0x09
                    .long     setTrack                                | Function 10, 0x0A
                    .long     setSector                               | Function 11, 0x0B
                    .long     setDMA                                  | Function 12, 0x0C
                    .long     read                                    | Function 13, 0x0D
                    .long     notImpl                                 | Function 14, 0x0E
                    .long     notImpl                                 | Function 15, 0x0F
                    .long     secTranslate                            | Function 16, 0x10
                    .long     notImpl                                 | Function 17, 0x11
                    .long     getMemTable                             | Function 18, 0x12
                    .long     notImpl                                 | Function 19, 0x13
                    .long     notImpl                                 | Function 20, 0x14
                    .long     notImpl                                 | Function 21, 0x15
                    .long     setHandlers                             | Function 22, 0x16

*fCount       =         (. - fTable) / 4
fCount              =         23

*--------------------------------------------------------------------------------
* Entry point / Functon handler
*--------------------------------------------------------------------------------
_bios:              CMPI.W    #fCount,%D0
                    BCC       h1
                    EXT.L     %D0
                    LSL.L     #2,%D0                                  | multiply bios function by 4
                    LEA       fTable,%A0                              | Get offset into table
                    MOVE.L    (%A0,%D0.W),%A1                         | get handler address
                    JSR       (%A1)                                   | call handler
h1:                 RTS

*--------------------------------------------------------------------------------
* Function 0: Initialisation
*--------------------------------------------------------------------------------
initialise:         MOVE.W    #0x0D,%D1
                    BSR       consoleOut
                    MOVE.W    #0x0A,%D1
                    BSR       consoleOut

                    LEA       strInit,%A0                             | Display initialisation string
                    BSR       puts

                    MOVE.W    #0x0D,%D1
                    BSR       consoleOut
                    MOVE.W    #0x0A,%D1
                    BSR       consoleOut

                    MOVE.W    #MON_INIT,%D0                           | Function 0, initialise
                    TRAP      #MON_TRAP

                    CLR.L     %D0                                     | log on disk A, user 0
                    RTS

*--------------------------------------------------------------------------------
* Dummy function
*--------------------------------------------------------------------------------
notImpl:            MOVE.L    #0,%D0
                    RTS

*--------------------------------------------------------------------------------
* Function 4: Write console character
* Write the character in %D1 to the console
*--------------------------------------------------------------------------------
consoleOut:         MOVE.W    #MON_COUT,%D0                           | Function 4
                    TRAP      #MON_TRAP
                    RTS

*--------------------------------------------------------------------------------
* Function 9: Select disk given by register %D1.B
*--------------------------------------------------------------------------------
selectDisk:         MOVEQ     #0,%D0
                    CMPI.B    #DISK_COUNT,%D1                         | valid drive number?
                    BPL       sd1                                     | if no, return 0 in %D0
                    MOVE.B    %D1,selDrive                            | else, save drive number
                    MOVE.L    #dpHdr0,%D0                             | point %D0 at correct dph
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
* Return in %D0, 0 if ok, else non-zero
*--------------------------------------------------------------------------------
read:               BSR       selLBADrive                             | Get required D+LBA
                    CMP.L     curLBADrive,%D0                         | Check if we already have it
                    BEQ       read1                                   | Yes

                    MOVE.L    %D0,-(%SP)                              | Save the D+LBA value

                    MOVE.L    #secBuffer,-(%SP)                       | No, need to read the HDD sector
                    MOVE.L    %D0,-(%SP)                              | D+LBA
                    BSR       readHDDSector
                    ADDA.L    #0x08,%SP

                    MOVE.L    (%SP)+,%D0                              | Restore D+LBA
                    MOVE.L    %D0,curLBADrive

read1:              BSR       getSectorIndex                          | Calculate the index for the CPM sector into the HDD sector
                    LSL.L     #C_SEC_MS,%D1                           | Convert to bytes

                    LEA       secBuffer,%A0
                    ADD.L     %D1,%A0                                 | Copy from address
                    MOVE.L    dma,%A1                                 | Copy to address
                    MOVE.W    #C_SEC_SZ,%D0                           | Copy size
                    BRA       read3                                   | Enter loop at end

read2:              MOVE.B    (%A0)+,(%A1)+                           | Copy the sector
read3:              DBRA      %D0,read2

                    MOVE.L    #0,%D0                                  | ** TODO Add some error handling ****
                    RTS

*--------------------------------------------------------------------------------
* Get the selected LBA and drive
* return in %D0, upper 8bits=drive, lower 24bits = lba
*--------------------------------------------------------------------------------
selLBADrive:        MOVEM.L   %D1-%D2,-(%SP)
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
* Read a HDD sectors
* readHDDSector(long D+LBA, *destination)
*--------------------------------------------------------------------------------
readHDDSector:      LINK      %A6,#0
                    MOVEM.L   %D0-%D2/%A0-%A2,-(%SP)

                    MOVE.L    0x08(%A6),%D1                           | D+LBA
                    ANDI.L    #0x00FFFFFF,%D1                         | Remove the drive value

                    MOVE.L    0x08(%A6),%D2                           | Drive
                    ANDI.L    #0xFF000000,%D2                         | Remove LBA
                    LSR.L     #8,%D2                                  | Drive into lower byte of upper word
                    MOVE.W    #1,%D2                                  | Sectors to read in lower word

                    MOVE.L    0x0C(%A6),%A0                           | Destination address

                    MOVE.W    #MON_READ,%D0                            | Call function 5
                    TRAP      #MON_TRAP

                    MOVEM.L   (%SP)+,%D0-%D2/%A0-%A2
                    UNLK      %A6
                    RTS

*--------------------------------------------------------------------------------
* Function 16: Sector translate
*--------------------------------------------------------------------------------
secTranslate:       MOVE.L    %D1,%D0
                    RTS

*--------------------------------------------------------------------------------
* Function 18: Not implemented yet
*--------------------------------------------------------------------------------
getMemTable:        MOVE.L    #0,%D0
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
                    BSR       consoleOut
                    BRA       puts
p1:                 RTS

*-----------------------------------------------------------------------------------------------------
                    .data

curLBADrive:        .long     -1                                      | LBA & drive of current loaded sector, lower 24bits = LBA, upper 8 = drive
dma:                .long     0
selTrack:           .word     0                                       | track requested by setTrack
selSector:          .word     0
selDrive:           .byte     0xff                                    | drive requested by selectDisk

*-----------------------------------------------------------------------------------------------------
* disk parameter headers
*-----------------------------------------------------------------------------------------------------
dpHdr0:             .long     0                                       | No translation
                    .word     0                                       | scratchpad 1
                    .word     0                                       | scratchpad 2
                    .word     0                                       | scratchpad 3
                    .long     dirBuffer                               | ptr to directory buffer
                    .long     dpBlock                                 | ptr to disk parameter block
                    .long     0                                       | ptr to check vector
                    .long     0                                       | ptr to allocation vector

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
                    .word     2                                       | track offset

*-----------------------------------------------------------------------------------------------------
                    .bss
                    .even

dirBuffer:          DS.B      128                                     | directory buffer

secBuffer:          DS.B      512                                     | Buffer to hold read HDD sector

*---------------------------------------------------------------------------------------------------------
                    .text
                    .even

strInit:            .ascii    "CP/M-68K S100 Boot Loader V0.1.0"

                    DC.B      0
          .end

