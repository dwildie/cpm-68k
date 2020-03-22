                    .include  "include/buffer.i"
                    .include  "include/bios.i"

*---------------------------------------------------------------------------------------------------------
                    .text

                    .global   lruSequence,buffTbl,buffers,buffend     | ****** DEBUG

lruSequence:        ds.l      1

                    .even
buffTbl:            ds.b      T_SIZE

                    .even
buffers:            ds.b      BUFF_TSZ

buffend:            ds.l      1

*---------------------------------------------------------------------------------------------------------
                    .text
                    .global   initBuffers
                    .global   buffRead
                    .global   buffWrite
                    .global   flushAll

*---------------------------------------------------------------------------------------------------------
* Initialise the buffers
*---------------------------------------------------------------------------------------------------------
initBuffers:        CLR.L     %D0
                    CLR.L     %D1
                    LEA.L     buffTbl,%A0                             | Was LEA.L

ib1:                MOVE.L    #0xFFFFFFFF,T_FDLBA(%A0,%D1.W)
                    MOVE.L    #0xFFFFFFFF,T_LDLBA(%A0,%D1.W)
                    CLR.L     T_DIRTY_BITS(%A0,%D1.W)
                    CLR.L     T_LRU_SEQ(%A0,%D1.W)

                    LEA.L     buffers,%A1                             | Was LEA.L
                    MOVE.W    %D0,%D2
                    MULU.W    #BUFF_SSZ,%D2
                    ADD.L     %D2,%A1
                    MOVE.L    %A1,T_ADDRESS(%A0,%D1.W)

                    ADDQ.B    #1,%D0
                    ADD.W     #T_ENTRY_LENGTH,%D1
                    CMPI.B    #BUFF_COUNT,%D0
                    BNE       ib1

                    MOVE.L    #0,lruSequence                          | Zero the master lru sequence

                    RTS

*---------------------------------------------------------------------------------------------------------
* Read a sector
* buffRead(long D+LBA, long* destination,  int cpmSectorIndex)
* return %D0: 0 = success, otherwise error
*---------------------------------------------------------------------------------------------------------
buffRead:           LINK      %A6,#0
                    MOVE.L    %D0,-(%SP)

                    MOVE.L    0x08(%A6),-(%SP)                        | Pass our first param, D+LBA
                    BSR       findBuffer                              | Find the buffer which contains the D+LBA sector
                    ADD.L     #4,%SP

                    CMP.L     #0,%A1                                  | %A1 will be non zero if found
                    BNE       br2                                     | Yes

                    CMP.L     #0,%A2                                  | Have we got a buffer we can use
                    BNE       br1                                     | Yes, do a disk read

                    BSR       findLruBuffer                           | Find the least recently used buffer, will be dirty
                    MOVE.L    %A2,%A1
                    BSR       flush                                   | Flush it before reusing it

br1:                MOVE.L    %A2,%A1                                 | Read a full buffer from the HDD
                    MOVE.L    T_ADDRESS(%A1),-(%SP)                   | Push the buffer start address
                    MOVE.L    0x08(%A6),-(%SP)                        | Push D+LBA
                    BSR       readHDDSectors                          | Read the HDD sectors into the buffer
                    ADD.L     #8,%SP

                    MOVE.L    0x08(%A6),T_FDLBA(%A1)                  | Set the buffer's first DLBA
                    MOVE.L    0x08(%A6),T_LDLBA(%A1)                  | Set the buffer's last DLBA
                    ADD.L     #BUFF_SECS,T_LDLBA(%A1)
                    SUBQ.L    #1,T_LDLBA(%A1)

br2:                MOVE.L    0x08(%A6),%D0                           | Required sector
                    SUB.L     T_FDLBA(%A1),%D0                        | Less the buffers start sector 
                    MOVE.L    #H_SEC_MS,%D1
                    LSL.L     %D1,%D0                                 | Byte offset into the buffer
                    MOVE.W    0x10(%A6),%D1                           | CPM offset into HDD sector
                    LSL.L     #C_SEC_MS,%D1                           | Byte offset into hdd sector
                    ADD.L     %D1,%D0                                 | Byte offset into buffer
                    MOVE.L    T_ADDRESS(%A1),%A0                      | Start of buffer
                    ADD.L     %D0,%A0                                 | Address of source CPM sector

                    MOVE.L    0x0C(%A6),%A2                           | Destination Address
                    CLR.W     %D0

br3:                MOVE.B    (%A0)+,(%A2)+                           | Copy the CPM sector from the buffer to the destination
                    ADDI.W    #1,%D0
                    CMP.W     #C_SEC_SZ,%D0
                    BNE       br3

                    ADDI.L    #1,lruSequence                          | Update the lru sequences
                    MOVE.L    lruSequence,T_LRU_SEQ(%A1)

                    MOVE.L    (%SP)+,%D0
                    UNLK      %A6
                    RTS

*---------------------------------------------------------------------------------------------------------
* Write a CPM sector, %D0 = D+LBA, %D1: 0 = Normal write, Anything else = write + flush, %A0 = source address, %D2 = index into HDD sector
* buffWrite(long D+LBA, int type, long* source,  int cpmSectorIndex)
*---------------------------------------------------------------------------------------------------------
buffWrite:          LINK      %A6,#0
                    MOVEM.L   %D0-%D3/%A1-%A3,-(%SP)

                    MOVE.L    0x08(%A6),%D0                           | D+LBA ******* DEBUG *****
                    MOVE.W    0x12(%A6),%D1                           | CPM sector index *** DEBUG
                    MOVE.W    0x0C(%A6),%D2                           | Type ***** DEBUG

                    MOVE.L    8(%A6),-(%SP)                           | Pass our first param, D+LBA
                    BSR       findBuffer                              | Find the buffer which contains the D+LBA sector
                    ADD.L     #4,%SP

                    CMP.L     #0,%A1                                  | %A1 will be non zero if found
                    BNE       bw2                                     | Yes

                    CMP.L     #0,%A2                                  | Have we got a buffer we can use
                    BNE       bw1                                     | Yes, do a disk read

                    BSR       findLruBuffer                           | Find the least recently used buffer, will be dirty
                    MOVE.L    %A2,%A1
                    BSR       flush                                   | Flush it before reusing it

bw1:                MOVE.L    %A2,%A1                                 | Read a full buffer from the HDD
                    MOVE.L    T_ADDRESS(%A1),-(%SP)                   | Push the buffer start address
                    MOVE.L    0x08(%A6),-(%SP)                        | Push D+LBA
                    BSR       readHDDSectors                          | Read the HDD sectors into the buffer
                    ADD.L     #8,%SP

                    MOVE.L    0x08(%A6),T_FDLBA(%A1)                  | Set the buffer's first DLBA
                    MOVE.L    0x08(%A6),T_LDLBA(%A1)                  | Set the buffer's last DLBA
                    ADD.L     #BUFF_SECS,T_LDLBA(%A1)
                    SUBQ.L    #1,T_LDLBA(%A1)

bw2:                MOVE.L    T_ADDRESS(%A1),%A0                      | Address of buffer start
                    MOVE.L    0x08(%A6),%D0                           | Required sector
                    SUB.L     T_FDLBA(%A1),%D0                        | Get the sector index into the %A1 buffer 
                    MOVE.L    #H_SEC_MS,%D1
                    LSL.L     %D1,%D0                                 | Byte offset into the buffer
                    ADD.L     %D0,%A0                                 | Address of HDD sector in the buffer

                    MOVE.W    0x12(%A6),%D0                           | CPM offset into HDD sector
                    LSL.L     #C_SEC_MS,%D0                           | Byte offset of CPM sector into HDD sector
                    ADD.L     %D0,%A0                                 | Address of CPM sector in buffer

                    MOVE.L    0x0E(%A6),%A2                           | Destination Address

                    CLR.W     %D0
bw3:                MOVE.B    (%A2)+,(%A0)+                           | Copy from the source into the buffer
                    ADDQ.W    #1,%D0
                    CMP.W     #C_SEC_SZ,%D0
                    BNE       bw3

                    MOVE.L    0x08(%A6),%D0                           | Required sector
                    SUB.L     T_FDLBA(%A1),%D0                        | Get the sector index into the %A1 buffer 
                    MOVE.L    T_DIRTY_BITS(%A1),%D1
                    BSET.L    %D0,%D1                                 | Set the dirty bit whilst %D0 contains the sector index
                    MOVE.L    %D1,T_DIRTY_BITS(%A1)

                    MOVE.W    0x0C(%A6),%D0                           | Check the type flag
                    CMP.W     #WR_DIRECTORY,%D0
                    BNE       bw4                                     | Normal, return now

                    MOVE.L    %A1,%A0                                 | Flush the entire buffer
                    BSR       flush

bw4:                MOVEM.L   (%SP)+,%D0-%D3/%A1-%A3
                    UNLK      %A6
                    RTS

*---------------------------------------------------------------------------------------------------------
* Flush all dirty sectors to disk
*---------------------------------------------------------------------------------------------------------
flushAll:           LINK      %A6,#0
                    CLR.B     %D1
                    LEA.L     buffTbl,%A1                             | Was LEA.L

fbs1:               TST.L     T_DIRTY_BITS(%A1)                       | Is it dirty
                    BEQ       fbs2                                    | No, check next buffer

                    BSR       flush                                   | Yes write any dirty sectors to disk

fbs2:               ADDQ.B    #1,%D1
                    ADD.L     #T_ENTRY_LENGTH,%A1
                    CMPI.B    #BUFF_COUNT,%D1
                    BNE       fbs1

                    UNLK      %A6
                    RTS

*---------------------------------------------------------------------------------------------------------
* Write any dirty sectors in the %A1 buffer to disk
*---------------------------------------------------------------------------------------------------------
flush:              MOVEM.L   %D0-%D7/%A0-%A5,-(%SP)

                    CLR.L     %D4
                    MOVE.L    T_DIRTY_BITS(%A1),%D3                   | Test each dirty bit

fb1:                BTST      %D4,%D3
                    BEQ       fb2                                     | No, test the next bit

                    MOVE.L    T_ADDRESS(%A1),%A0                      | Start of buffer
                    MOVE.L    %D4,%D0
                    MOVE.L    #H_SEC_MS,%D1
                    LSL       %D1,%D0                                 | Byte offset into buffer
                    ADD.L     %D0,%A0                                 | Address of segment

                    MOVE.L    T_FDLBA(%A1),%D0                        | Base D+LBA
                    ADD.L     %D4,%D0                                 | Plus index of dity sector

                    BSR       writeHDDSector                          | %A0 already points to sector

fb2:                ADDQ.B    #1,%D4
                    CMPI.B    #BUFF_SECS,%D4
                    BNE       fb1

                    MOVE.L    #0,T_DIRTY_BITS(%A1)                    | Clear all the dirty bits

                    MOVEM.L   (%SP)+,%D0-%D7/%A0-%A5
                    RTS

*---------------------------------------------------------------------------------------------------------
* Find the least recently used buffer doesn't matter if it is dirty, return least recently used in %A2
*---------------------------------------------------------------------------------------------------------
findLruBuffer:      LINK      %A6,#0
                    CLR.B     %D1
                    LEA.L     buffTbl,%A1                             | Was LEA.L

                    MOVE.L    %A1,%A2                                 | First buffer is first LRU
                    BRA       flb4

flb1:               MOVE.L    T_LRU_SEQ(%A1),%D2
                    CMP.L     T_LRU_SEQ(%A2),%D2                      | See if this buffer's lru is less
                    BGE       flb4

                    MOVE.L    %A1,%A2                                 | This buffer is now lru
flb4:               ADDQ.B    #1,%D1
                    ADD.L     #T_ENTRY_LENGTH,%A1
                    CMPI.B    #BUFF_COUNT,%D1
                    BNE       flb1

                    UNLK      %A6
                    RTS

*---------------------------------------------------------------------------------------------------------
* Find the buffer containing the D+LBA sector
* findBuffer(long D+LBA)
* Return address of buffer entry in %A1 or least recently used in %A2
*---------------------------------------------------------------------------------------------------------
findBuffer:         LINK      %A6,#0

                    CLR.B     %D1
                    MOVE.L    #0,%A2
                    LEA.L     buffTbl,%A1                             | Was LEA.L

                    MOVE.L    8(%A6),%D0                              | First param, D+LBA
fib1:               CMP.L     T_FDLBA(%A1),%D0
                    BLT       fib2                                    | No
                    CMP.L     T_LDLBA(%A1),%D0
                    BLE       fib5                                    | Yes, is in this buffer, return

fib2:               TST.L     T_DIRTY_BITS(%A1)                       | Check if this buffer is dirty
                    BNE       fib4                                    | Yes, can't be LRU

                    CMP.L     #0,%A2
                    BEQ       fib3                                    | First buffer, set it as lru

                    MOVE.L    T_LRU_SEQ(%A1),%D2
                    CMP.L     T_LRU_SEQ(%A2),%D2                      | See if this buffer's lru is less
                    BGE       fib4                                    | No

fib3:               MOVE.L    %A1,%A2                                 | This buffer is now lru

fib4:               ADDQ.B    #1,%D1
                    ADD.L     #T_ENTRY_LENGTH,%A1
                    CMPI.B    #BUFF_COUNT,%D1
                    BNE       fib1

                    MOVE.L    #0,%A1                                  | Didn't match

fib5:               MOVEM.L   (%SP)+,%D0-%D2
                    UNLK      %A6
                    RTS

*--------------------------------------------------------------------------------
* Read a buffer of HDD sectors
* readHDDSector(long D+LBA, *destination)
* %D0 specifies the LBA & Drive, %A0 destination
*--------------------------------------------------------------------------------
readHDDSectors:     LINK      %A6,#0
                    MOVEM.L   %D0-%D2/%A0-%A2,-(%SP)

                    MOVE.L    0x08(%A6),%D1                           | D+LBA
                    ANDI.L    #0x00FFFFFF,%D1                         | Remove the drive value

                    MOVE.L    0x08(%A6),%D2                           | Drive
                    ANDI.L    #0xFF000000,%D2                         | Remove LBA
                    LSR.L     #8,%D2                                  | Drive into lower byte of upper word
                    MOVE.W    #BUFF_SECS,%D2                          | Sectors to read in lower word

                    MOVE.L    0x0C(%A6),%A0                           | Destination address

                    MOVE.W    #MON_READ,%D0                           | Call function 5
                    TRAP      #MON_TRAP

                    MOVEM.L   (%SP)+,%D0-%D2/%A0-%A2
                    UNLK      %A6
                    RTS

*--------------------------------------------------------------------------------
* Write a HDD sector
* %D0 specifies the D+LBA, %A0 source
*--------------------------------------------------------------------------------
writeHDDSector:     MOVEM.L   %D0-%D4/%A0-%A2,-(%SP)
                    MOVE.L    %D0,%D1                                 | Sector LBA
                    ANDI.L    #0x00FFFFFF,%D1                         | Remove the drive value

                    MOVE.L    %D0,%D2                                 | Drive
                    ANDI.L    #0xFF000000,%D2                         | Remove LBA
                    LSR.L     #8,%D2                                  | Drive into lower byte of upper word
                    MOVE.W    #1,%D2                                  | Sectors to write in lower word

                    MOVE.W    #MON_WRITE,%D0                          | Call function 6
                    TRAP      #MON_TRAP

                    MOVEM.L   (%SP)+,%D0-%D4/%A0-%A2
                    RTS
