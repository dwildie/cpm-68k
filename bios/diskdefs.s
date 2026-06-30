*-----------------------------------------------------------------------------------------------------
                    .data
                    .global   dpHdr0,dpBlock
                    
                    .even
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

