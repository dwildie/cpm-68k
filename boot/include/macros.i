          .macro              TO_BIG_END reg
                    ROL.W     #8,\reg                                 | Convert to big endian
                    SWAP      \reg
                    ROL.W     #8,\reg
          .endm

          .macro              PRT_ERR strMsg
                    PUTS      strPartition
                    BSR       writeHexDigit
                    PUTS      \strMsg
                    MOVE.W    #1,%D0
          .endm

          .macro              PUTSP count
                    MOVEM.L   %D0-%D1,-(%SP)
                    MOVE.W    \count,%D1
                    MOVE.B    #' ',%D0
                    BRA       99f
98:                 BSR       writeCh
99:                 DBRA      %D1,98b
                    MOVEM.L   (%SP)+,%D0-%D1
          .endm

          .macro              PUTCH char
                    MOVE.L    %D0,-(%SP)
                    MOVE.B    \char,%D0
                    BSR       writeCh
                    MOVE.L    (%SP)+,%D0
          .endm

          .macro              PUTCH2 char1,char2
                    MOVE.L    %D0,-(%SP)
                    MOVE.B    \char1,%D0
                    BSR       writeCh
                    MOVE.B    \char2,%D0
                    BSR       writeCh
                    MOVE.B    #' ',%D0
                    BSR       writeCh
                    MOVE.L    (%SP)+,%D0
          .endm

          .macro              PUTS str
                    MOVEM.L   %D0/%A2,-(%SP)
                    LEA       \str,%A2
                    BSR       writeStr
                    MOVEM.L   (%SP)+,%D0/%A2
          .endm

          .macro              STEP char
                    PUTCH     #\char
                    PUTCH     #'?'
                    BSR       readCh
                    BSR       CRLF
          .endm

          .macro              SHOW.W txt,wrd
                    PUTS      \txt
                    MOVE.W    \wrd,%D0
                    BSR       writeHexWord
          .endm
          .macro              SHOW.B txt,byt
                    PUTS      \txt
                    MOVE.B    \byt,%D0
                    BSR       writeHexByte
          .endm

          .macro              SHOW.L txt,lng
                    PUTS      \txt
                    MOVE.L    \lng,%D0
                    BSR       writeHexLong
          .endm

          .macro              PUTN1
                    MOVE.L    %D0,-(%SP)
                    ADDI.B    #'0',%D0
                    BSR       writeCh
                    MOVE.L    (%SP)+,%D0
          .endm

          .macro              CMD_TABLE_ENTRY name,address,description
                    .section  .rodata.strings
cmd_name_\name:     .asciz    "\name"
cmd_desc_\name:     .asciz    "\description"
                    .section  .rodata.cmdTable
                    .global   cmd_\name
cmd_\name:          .long     cmd_name_\name
                    .long     \address
                    .long     cmd_desc_\name
          .endm
