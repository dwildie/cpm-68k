
BUFF_COUNT          =         0x04                                    | The number of buffers of each of size BUFF_SECS
BUFF_SECS           =         0x08                                    | The number of HDD sectors in each buffer, Max is 0x20 (32)

H_SEC_SZ            =         0x200                                   | Size of a HDD sector
H_SEC_MS            =         9                                       | The number of places to left shift to multiply by H_SEC_SZ
C_SEC_SZ            =         0x80                                    | The size of a CPM sector
C_SEC_MS            =         7                                       | The number of places to left shift to multiply by C_SEC_SZ

BUFF_SSZ            =         BUFF_SECS*H_SEC_SZ                      | Size of a buffer
BUFF_TSZ            =         BUFF_COUNT*BUFF_SSZ                     | Size of all buffers

*-----------------------------------------------------------------------------------------------------
* Disk buffer table
*-----------------------------------------------------------------------------------------------------
T_ENTRY_LENGTH      =         0x14                                    | The size of an entry in the buffer table
T_FDLBA             =         0x00                                    | The D+LBA of the first sector in the buffer
T_LDLBA             =         0x04                                    | The D+LBA of the last sector in the buffer
T_DIRTY_BITS        =         0x08                                    | Bit map of the dirty sectors in the buffer, limits max buffer to 32 sectors
T_LRU_SEQ           =         0x0c                                    | LRU value of the buffer, incremented each time it is accessed
T_ADDRESS           =         0x10                                    | Address of the buffer
T_SIZE              =         BUFF_COUNT*T_ENTRY_LENGTH               | Size of the table

*-----------------------------------------------------------------------------------------------------
* CP/M write type values
*-----------------------------------------------------------------------------------------------------
WR_NORMAL           =         0
WR_DIRECTORY        =         1
WR_NEW_BLOCK        =         2


