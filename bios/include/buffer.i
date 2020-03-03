
BUFFER_COUNT        =         0x08                          | The number of buffers of each of size BUFFER_SECTORS
BUFFER_SECTORS      =         0x20                          | The number of HDD sectors in each buffer, Max is 0x20

HDD_SECTOR_SIZE     =         0x200                         | Size of a HDD sector
HDD_SECT_MULU_SHIFT =         9                             | The number of places to left shift to multiply by HDD_SECTOR_SIZE
CPM_SECTOR_SIZE     =         0x80                          | The size of a CPM sector
CPM_SECT_MULU_SHIFT =         7                             | The number of places to left shift to multiply by CPM_SECTOR_SIZE

BUFFER_SECTOR_SIZE  =         BUFFER_SECTORS * HDD_SECTOR_SIZE

*-----------------------------------------------------------------------------------------------------
* Disk buffer table
*-----------------------------------------------------------------------------------------------------
TBL_ENTRY_LENGTH    =         0x14                          | The size of an entry in the buffer table
TBL_DLBA_FIRST      =         0x00                          | The D+LBA of the first sector in the buffer
TBL_DLBA_LAST       =         0x04                          | The D+LBA of the last sector in the buffer
TBL_DIRTY_BITS      =         0x08                          | Bit map of the dirty sectors in the buffer, limits max buffer to 32 sectors
TBL_LRU_SEQ         =         0x0c                          | LRU value of the buffer, incremented each time it is accessed
TBL_ADDRESS         =         0x10                          | Address of the buffer

*-----------------------------------------------------------------------------------------------------
* CP/M write type values
*-----------------------------------------------------------------------------------------------------
WRITE_NORMAL        =         0                           
WRITE_DIRECTORY     =         1
WRITE_NEW_BLOCK     =         2
