*---------------------------------------------------------------------------------------------------------
                    .text
                    .global   strInit

                    .even

          .ifne               _GNU_
strInit:            .ascii    "CP/M-68K 16MB S100 BIOS V0.1.1.R3 [GNU]"
          .endif

          .ifne               _CPM_
strInit:            .ascii    "CP/M-68K 16MB S100 BIOS V0.1.1.R3 [CPM]"
          .endif

                    DC.B      0
                    
*-----------------------------------------------------------------------------------------------------
                    .data
                    .global   dma,selTrack,selSector,selDrive,memTable
                    .global   dpHdr0,dpBlock
                    
                    .even
dma:                .long     0
selTrack:           .word     0                                       | track requested by setTrack
selSector:          .word     0
selDrive:           .byte     0xff                                    | drive requested by selDisk

                    .even
memTable:           .word     1                                       | 1 memory region - TPA only
tpaStart:           .long     0x100000                                | Default: Start of the Transient Program Area
tpaSize:            .long     0xEB0000                                | Default: Size of the Transient Program Area

