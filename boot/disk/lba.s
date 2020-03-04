                    .include  "include/macros.i"
                    .include  "include/ide.i"
                    .include  "include/disk-def.i"

*-----------------------------------------------------------------------------------------------------
                    .data
LBA_VALUE:          .long     0                             | Current LBA value for the physical disk

*-----------------------------------------------------------------------------------------------------
                    .text
                    .global   initLBA
                    .global   setLBA
                    .global   incrementLBA
                    .global   decrementLBA

*-----------------------------------------------------------------------------------------------------
initLBA:            CLR.L     LBA_VALUE
                    RTS

*-----------------------------------------------------------------------------------------------------
* Set the current drives lba to %D0.L
*-----------------------------------------------------------------------------------------------------
setLBA:             MOVE.L    %D0,LBA_VALUE
                    BSR       setIdeLba
                    RTS

incrementLBA:       ADDQ.L    #1,LBA_VALUE
                    MOVE.L    LBA_VALUE,%D0
                    BSR       setIdeLba
                    RTS

decrementLBA:       TST.L     LBA_VALUE
                    BEQ       1f                            | Don't decrement beyond zero
                    SUBQ.L    #1,LBA_VALUE
                    MOVE.L    LBA_VALUE,%D0
                    BSR       setIdeLba
1:                  RTS

