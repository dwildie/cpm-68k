                    .include  "include/buffer.i"
                    .include  "include/bios.i"

*---------------------------------------------------------------------------------------------------------
                    .bss

lruSequence:        ds.l      1

                    .align(0x10)
bufferTable:        ds.b      BUFFER_COUNT * TBL_ENTRY_LENGTH

                    .align(0x10)
buffers:            ds.b      BUFFER_COUNT * BUFFER_SECTORS * HDD_SECTOR_SIZE

*---------------------------------------------------------------------------------------------------------
                    .text
                    .global   initBuffers
                    .global   bufferedRead
                    .global   bufferedWrite
                    .global   flushBuffers

                    .global   bufferTable,readHDDSectors,br1,bw1,bw2,bw3,writeHDDSector | *** DEBUG

*---------------------------------------------------------------------------------------------------------
* Initialise the buffers
*---------------------------------------------------------------------------------------------------------
initBuffers:        CLR.L     %D0
                    CLR.L     %D1
                    LEA       bufferTable,%A0

1:                  MOVE.L    #0xFFFFFFFF,TBL_DLBA_FIRST(%A0,%D1.W)
                    MOVE.L    #0xFFFFFFFF,TBL_DLBA_LAST(%A0,%D1.W)
                    CLR.L     TBL_DIRTY_BITS(%A0,%D1.W)
                    CLR.L     TBL_LRU_SEQ(%A0,%D1.W)

                    LEA       buffers,%A1
                    MOVE.W    %D0,%D2
                    MULU.W    #BUFFER_SECTOR_SIZE,%D2
                    ADD.L     %D2,%A1
                    MOVE.L    %A1,TBL_ADDRESS(%A0,%D1.W)

                    ADDQ.B    #1,%D0
                    ADD.W     #TBL_ENTRY_LENGTH,%D1
                    CMPI.B    #BUFFER_COUNT,%D0
                    BNE       1b

                    MOVE.L    #0,lruSequence                | Zero the master lru sequence

                    RTS

*---------------------------------------------------------------------------------------------------------
* Read a sector
* bufferedRead(long D+LBA, long* destination,  int cpmSectorIndex)
* return %D0: 0 = success, otherwise error
*---------------------------------------------------------------------------------------------------------
bufferedRead:       LINK      %FP,#0
                    MOVE.L    %D0,-(%SP)

                    MOVE.L    0x08(%FP),%D0                 | ******* DEBUG *****

br1:                MOVE.L    0x08(%FP),-(%SP)              | Pass our first param, D+LBA
                    BSR       findBuffer                    | Find the buffer which contains the D+LBA sector
                    ADD.L     #4,%SP

                    CMP.L     #0,%A1                        | %A1 will be non zero if found
                    BNE       2f                            | Yes

                    CMP.L     #0,%A2                        | Have we got a buffer we can use
                    BNE       1f                            | Yes, do a disk read

                    BSR       findLruBuffer                 | Find the least recently used buffer, will be dirty
                    LEA       TBL_ADDRESS(%A2),%A0
                    BSR       flushBuffer                   | Flush it before reusing it

1:                  MOVE.L    %A2,%A1                       | Read a full buffer from the HDD
                    MOVE.L    TBL_ADDRESS(%A1),-(%SP)       | Push the buffer start address
                    MOVE.L    0x08(%FP),-(%SP)              | Push D+LBA
                    BSR       readHDDSectors                | Read the HDD sectors into the buffer
                    ADD.L     #8,%SP

                    MOVE.L    0x08(%FP),TBL_DLBA_FIRST(%A1) | Set the buffer's first DLBA
                    MOVE.L    0x08(%FP),TBL_DLBA_LAST(%A1)  | Set the buffer's last DLBA
                    ADD.L     #BUFFER_SECTORS,TBL_DLBA_LAST(%A1)
                    SUBQ.L    #1,TBL_DLBA_LAST(%A1)

2:                  MOVE.L    0x08(%FP),%D0                 | Required sector
                    SUB.L     TBL_DLBA_FIRST(%A1),%D0       | Less the buffers start sector 
                    MOVE.L    #HDD_SECT_MULU_SHIFT,%D1
                    LSL.L     %D1,%D0                       | Byte offset into the buffer
                    MOVE.W    0x10(%FP),%D1                 | CPM offset into HDD sector
                    LSL.L     #CPM_SECT_MULU_SHIFT,%D1      | Byte offset into hdd sector
                    ADD.L     %D1,%D0                       | Byte offset into buffer
                    MOVE.L    TBL_ADDRESS(%A1),%A0          | Start of buffer
                    ADD.L     %D0,%A0                       | Address of source CPM sector

                    MOVE.L    0x0C(%FP),%A2                 | Destination Address
                    CLR.W     %D0

3:                  MOVE.B    (%A0)+,(%A2)+                 | Copy the CPM sector from the buffer to the destination
                    ADDI.W    #1,%D0
                    CMP.W     #CPM_SECTOR_SIZE,%D0
                    BNE       3b

                    ADDI.L    #1,lruSequence                | Update the lru sequences
                    MOVE.L    lruSequence,TBL_LRU_SEQ(%A1)

                    MOVE.L    (%SP)+,%D0
                    UNLK      %FP
                    RTS

*---------------------------------------------------------------------------------------------------------
* Write a CPM sector, %D0 = D+LBA, %D1: 0 = Normal write, Anything else = write + flush, %A0 = source address, %D2 = index into HDD sector
* bufferedWrite(long D+LBA, int type, long* source,  int cpmSectorIndex)
*---------------------------------------------------------------------------------------------------------
bufferedWrite:      LINK      %FP,#0
                    MOVEM.L   %D0-%D3/%A1-%A3,-(%SP)

                    MOVE.L    0x08(%FP),%D0                 | D+LBA ******* DEBUG *****
                    MOVE.W    0x12(%FP),%D1                 | CPM sector index *** DEBUG
                    MOVE.W    0x0C(%FP),%D2                 | Type ***** DEBUG

bw1:                MOVE.L    8(%FP),-(%SP)                 | Pass our first param, D+LBA
                    BSR       findBuffer                    | Find the buffer which contains the D+LBA sector
                    ADD.L     #4,%SP

                    CMP.L     #0,%A1                        | %A1 will be non zero if found
                    BNE       2f                            | Yes

                    CMP.L     #0,%A2                        | Have we got a buffer we can use
                    BNE       1f                            | Yes, do a disk read

                    BSR       findLruBuffer                 | Find the least recently used buffer, will be dirty
                    LEA       TBL_ADDRESS(%A2),%A0
                    BSR       flushBuffer                   | Flush it before reusing it

1:                  MOVE.L    %A2,%A1                       | Read a full buffer from the HDD
                    MOVE.L    TBL_ADDRESS(%A1),-(%SP)       | Push the buffer start address
                    MOVE.L    0x08(%FP),-(%SP)              | Push D+LBA
                    BSR       readHDDSectors                | Read the HDD sectors into the buffer
                    ADD.L     #8,%SP

                    MOVE.L    0x08(%FP),TBL_DLBA_FIRST(%A1) | Set the buffer's first DLBA
                    MOVE.L    0x08(%FP),TBL_DLBA_LAST(%A1)  | Set the buffer's last DLBA
                    ADD.L     #BUFFER_SECTORS,TBL_DLBA_LAST(%A1)
                    SUBQ.L    #1,TBL_DLBA_LAST(%A1)

2:                  MOVE.L    TBL_ADDRESS(%A1),%A0          | Address of buffer start
                    MOVE.L    0x08(%FP),%D0                 | Required sector
                    SUB.L     TBL_DLBA_FIRST(%A1),%D0       | Get the sector index into the %A1 buffer 
                    MOVE.L    #HDD_SECT_MULU_SHIFT,%D1
                    LSL.L     %D1,%D0                       | Byte offset into the buffer
                    ADD.L     %D0,%A0                       | Address of HDD sector in the buffer

                    MOVE.W    0x12(%FP),%D0                 | CPM offset into HDD sector
                    LSL.L     #CPM_SECT_MULU_SHIFT,%D0      | Byte offset of CPM sector into HDD sector
                    ADD.L     %D0,%A0                       | Address of CPM sector in buffer

                    MOVE.L    0x0E(%FP),%A2                 | Destination Address

                    CLR.W     %D0
3:                  MOVE.B    (%A2)+,(%A0)+                 | Copy from the source into the buffer
                    ADDQ.W    #1,%D0
                    CMP.W     #CPM_SECTOR_SIZE,%D0
                    BNE       3b

bw3:                MOVE.L    0x08(%FP),%D0                 | Required sector
                    SUB.L     TBL_DLBA_FIRST(%A1),%D0       | Get the sector index into the %A1 buffer 
                    MOVE.L    TBL_DIRTY_BITS(%A1),%D1
                    BSET.L    %D0,%D1                       | Set the dirty bit whilst %D0 contains the sector index
                    MOVE.L    %D1,TBL_DIRTY_BITS(%A1)

                    MOVE.W    0x0C(%FP),%D0                 | Check the type flag
                    CMP.W     #WRITE_DIRECTORY,%D0
                    BNE       4f                            | Normal, return now

                    MOVE.L    %A1,%A0                       | Flush the entire buffer
                    BSR       flushBuffer

4:                  MOVEM.L   (%SP)+,%D0-%D3/%A1-%A3
                    UNLK      %FP
                    RTS

*---------------------------------------------------------------------------------------------------------
* Flush all dirty sectors to disk
*---------------------------------------------------------------------------------------------------------
flushBuffers:       LINK      %FP,#0
                    CLR.B     %D1
                    LEA       bufferTable,%A1

1:                  TST.L     TBL_DIRTY_BITS(%A1)           | Is it dirty
                    BEQ       2f                            | No, check next buffer

                    MOVE.L    %A1,%A0                       | Yes write any dirty sectors to disk
                    BSR       flushBuffer

2:                  ADDQ.B    #1,%D1
                    ADD.L     #TBL_ENTRY_LENGTH,%A1
                    CMPI.B    #BUFFER_COUNT,%D1
                    BNE       1b

                    UNLK      %FP
                    RTS

*---------------------------------------------------------------------------------------------------------
* Write any dirty sectors in the %A0 buffer to disk
*---------------------------------------------------------------------------------------------------------
flushBuffer:        MOVEM.L   %D0-%D7/%A0-%A5,-(%SP)

                    CLR.L     %D4
                    MOVE.L    TBL_DIRTY_BITS(%A0),%D3       | Test each dirty bit

1:                  BTST      %D4,%D3
                    BEQ       2f                            | No, test the next bit

                    MOVE.L    TBL_ADDRESS(%A1),%A0          | Start of buffer
                    MOVE.L    %D4,%D0
                    MULU      #HDD_SECTOR_SIZE,%D0          | Byte offset into buffer
                    ADD.L     %D0,%A0                       | Address of segment

                    MOVE.L    TBL_DLBA_FIRST(%A1),%D0       | Base D+LBA
                    ADD.L     %D4,%D0                       | Plus index of dity sector

                    BSR       writeHDDSector                | %A0 already points to sector

2:                  ADDQ.B    #1,%D4
                    CMPI.B    #BUFFER_SECTORS,%D4
                    BNE       1b

                    MOVE.L    #0,TBL_DIRTY_BITS(%A1)        | Clear all the dirty bits

                    MOVEM.L   (%SP)+,%D0-%D7/%A0-%A5
                    RTS

*---------------------------------------------------------------------------------------------------------
* Find the least recently used buffer doesn't matter if it is dirty, return least recently used in %A2
*---------------------------------------------------------------------------------------------------------
findLruBuffer:      LINK      %FP,#0
                    CLR.B     %D1
                    LEA       bufferTable,%A1

                    MOVE.L    %A1,%A2                       | First buffer is first LRU
                    BRA       4f

1:                  MOVE.L    TBL_LRU_SEQ(%A1),%D2
                    CMP.L     TBL_LRU_SEQ(%A2),%D2          | See if this buffer's lru is less
                    BGE       4f

                    MOVE      %A1,%A2                       | This buffer is now lru
4:                  ADDQ.B    #1,%D1
                    ADD.L     #TBL_ENTRY_LENGTH,%A1
                    CMPI.B    #BUFFER_COUNT,%D1
                    BNE       1b

                    UNLK      %FP
                    RTS

*---------------------------------------------------------------------------------------------------------
* Find the buffer containing the D+LBA sector
* findBuffer(long D+LBA)
* Return address of buffer entry in %A1 or least recently used in %A2
*---------------------------------------------------------------------------------------------------------
findBuffer:         LINK      %FP,#0
                    MOVEM.L   %D0-%D2,-(%SP)

                    CLR.B     %D1
                    MOVE.L    #0,%A2
                    LEA       bufferTable,%A1

                    MOVE.L    8(%FP),%D0                    | First param, D+LBA
1:                  CMP.L     TBL_DLBA_FIRST(%A1),%D0
                    BLT       2f                            | No
                    CMP.L     TBL_DLBA_LAST(%A1),%D0
                    BLE       5f                            | Yes, is in this buffer, return

2:                  TST.L     TBL_DIRTY_BITS(%A1)           | Check if this buffer is dirty
                    BNE       4f                            | Yes, can't be LRU

                    CMP.L     #0,%A2
                    BEQ       3f                            | First buffer, set it as lru

                    MOVE.L    TBL_LRU_SEQ(%A1),%D2
                    CMP.L     TBL_LRU_SEQ(%A2),%D2          | See if this buffer's lru is less
                    BGE       4f                            | No

3:                  MOVE.L    %A1,%A2                       | This buffer is now lru

4:                  ADDQ.B    #1,%D1
                    ADD.L     #TBL_ENTRY_LENGTH,%A1
                    CMPI.B    #BUFFER_COUNT,%D1
                    BNE       1b

                    MOVE.L    #0,%A1                        | Didn't match

5:                  MOVEM.L   (%SP)+,%D0-%D2
                    UNLK      %FP
                    RTS

*--------------------------------------------------------------------------------
* Read a buffer of HDD sectors
* readHDDSector(long D+LBA, *destination)
* %D0 specifies the LBA & Drive, %A0 destination
*--------------------------------------------------------------------------------
readHDDSectors:     LINK      %FP,#0
                    MOVEM.L   %D0-%D2/%A0-%A2,-(%SP)

                    MOVE.L    0x08(%FP),%D1                 | D+LBA
                    ANDI.L    #0x00FFFFFF,%D1               | Remove the drive value

                    MOVE.L    0x08(%FP),%D2                 | Drive
                    ANDI.L    #0xFF000000,%D2               | Remove LBA
                    LSR.L     #8,%D2                        | Drive into lower byte of upper word
                    MOVE.W    #BUFFER_SECTORS,%D2           | Sectors to read in lower word

                    MOVE.L    0x0C(%FP),%A0                 | Destination address

                    MOVE.W    #0x5,%D0                      | Call function 5
                    TRAP      #MONITOR_TRAP

                    MOVEM.L   (%SP)+,%D0-%D2/%A0-%A2
                    UNLK      %FP
                    RTS

*--------------------------------------------------------------------------------
* Write a HDD sector
* %D0 specifies the D+LBA, %A0 source
*--------------------------------------------------------------------------------
writeHDDSector:     MOVEM.L   %D0-%D4/%A0-%A2,-(%SP)
                    MOVE.L    %D0,%D1                       | Sector LBA
                    ANDI.L    #0x00FFFFFF,%D1               | Remove the drive value

                    MOVE.L    %D0,%D2                       | Drive
                    ANDI.L    #0xFF000000,%D2               | Remove LBA
                    LSR.L     #8,%D2                        | Drive into lower byte of upper word
                    MOVE.W    #1,%D2                        | Sectors to write in lower word

                    MOVE.W    #0x6,%D0                      | Call function 6
                    TRAP      #MONITOR_TRAP

                    MOVEM.L   (%SP)+,%D0-%D4/%A0-%A2
                    RTS
