*---------------------------------------------------------------------------------------------------------
* Master boot record offsets & sizes
*---------------------------------------------------------------------------------------------------------
MBR_CODE            =         0                                       | 0x0   Byte[440] 
MBR_DISK_SIG        =         440                                     | 0x1B8 Long 
MBR_RESERVED        =         444                                     | 0x1BC Word
MBR_PRT_TBL         =         446                                     | 0x1BE Byte[0x40]
MBR_PRT_TBL_0       =         MBR_PRT_TBL                             | 0x1BE Byte[0x10]
MBR_PRT_TBL_1       =         MBR_PRT_TBL_0 + PRT_ENTRY_SIZE          | 0x1CE Byte[0x10]
MBR_PRT_TBL_2       =         MBR_PRT_TBL_1 + PRT_ENTRY_SIZE          | 0x1DE Byte[0x10]
MBR_PRT_TBL_3       =         MBR_PRT_TBL_2 + PRT_ENTRY_SIZE          | 0x1EE Byte[0x10]

PRT_STATUS          =         0x00                                    | Byte
PRT_START_HEAD      =         0x01                                    | Byte
PRT_START_CYL_SEC   =         0x02                                    | WORD
PRT_TYPE            =         0x04                                    | Byte
PRT_END_HEAD        =         0x05                                    | Byte
PRT_END_CYL_SEC     =         0x06                                    | Word
PRT_START_LBA       =         0x08                                    | Long
PRT_SEC_COUNT       =         0x0C                                    | Long

PRT_ENTRIES         =         4
PRT_ENTRY_SIZE      =         0x10
PRT_TABLE_SIZE      =         PRT_ENTRY_SIZE * PRT_ENTRIES

*---------------------------------------------------------------------------------------------------------
* Our simplified table
*---------------------------------------------------------------------------------------------------------
PE_START            =         0x00
PE_SECTORS          =         0x04
PE_TYPE             =         0x08
PE_VALID            =         0x09

PE_SIZE             =         0x0A

PT_VALID            =         0x00
PT_CURRENT          =         0x02
PT_SECTORS          =         0x04
PT_ENTRIES          =         0x08
PT_SIZE             =         PT_ENTRIES + PE_SIZE * PRT_ENTRIES

*---------------------------------------------------------------------------------------------------------
* Recognised partition type IDs
*---------------------------------------------------------------------------------------------------------
PID_FAT12           =         0x01
PID_FAT16           =         0x04
PID_FAT16B          =         0x06
PID_FAT32           =         0x0C
PID_CPM80           =         0x52
PID_CPM86           =         0xD8
PID_CDOS            =         0xDB
