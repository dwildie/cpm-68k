                    .include  "include/macros.i"
                    .include  "include/disk-def.i"

                    .text
                    .global   showDiskDef

*-----------------------------------------------------------------------------------------------------
showDiskDef:        PUTS      title
                    SHOW.W    sectorLength,#DEF_DD_SEC_SIZE
                    SHOW.W    tracks,#DEF_DD_TRACKS
                    SHOW.W    sectorsPerTrack,#DEF_DD_SEC_TRK
                    SHOW.W    blockSize,#DEF_DD_BLOCK_SIZE
                    SHOW.B    skew,#DEF_DD_SKEW
                    SHOW.B    bootTracks,#DEF_DD_BOOT_TRACKS
                    SHOW.L    totalSectors,#DEF_DD_SEC_TOTAL
                    SHOW.W    directoryStart,#DEF_DD_DIR_START
                    SHOW.W    directorySize,#DEF_DD_DIR_SECS
                    BSR       newLine
                    RTS

*---------------------------------------------------------------------------------------------------------
                    .section  .rodata.strings
                    .align(2)

title:              .asciz    "\r\nCPM/68K Disk definition"
sectorLength:       .asciz    "\r\n  Sector length:         0x"
tracks:             .asciz    "\r\n  Tracks:                0x"
sectorsPerTrack:    .asciz    "\r\n  Sectors per track:     0x"
blockSize:          .asciz    "\r\n  Block size:            0x"
skew:               .asciz    "\r\n  Skew:                    0x"
bootTracks:         .asciz    "\r\n  Boot tracks:             0x"
totalSectors:       .asciz    "\r\n  Total sectors:     0x"
directoryStart:     .asciz    "\r\n  Directory start:       0x"
directorySize:      .asciz    "\r\n  Directory size:        0x"


