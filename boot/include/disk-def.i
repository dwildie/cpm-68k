*-----------------------------------------------------------------------------------------------------
* CPM/68K Disk definition
*-----------------------------------------------------------------------------------------------------

* Default CPM disk definition - cpmtools "4mb-hd"
DEF_DD_SEC_SIZE     =         128                                     | Sector size, CPM/68K uses 128 byte sectors
DEF_DD_TRACKS       =         1024                                    | Total number of tracks
DEF_DD_SEC_TRK      =         32                                      | Number of sectors per track
DEF_DD_BLOCK_SIZE   =         2048                                    | Block size
DEF_DD_MAX_DIRS     =         256                                     | Maximum number of directory entries
DEF_DD_DIR_ENTRY    =         32                                      | Size of ech directory entry
DEF_DD_SKEW         =         1                                       | Skew, 1 = no skew
DEF_DD_BOOT_TRACKS  =         2                                       | Number of boot/system tracks before directory
DEF_DD_OFFSET_TRACKS =        1024                                    | Number of tracks each partition is offset from the previous

DEF_DD_SEC_TOTAL    =         DEF_DD_TRACKS*DEF_DD_SEC_TRK            | Total number of sectors, includes boot sectors & directory
DEF_DD_DIR_START    =         DEF_DD_BOOT_TRACKS * DEF_DD_SEC_TRK     | Start of directory (sectors)
DEF_DD_DIR_SECS     =         (DEF_DD_DIR_ENTRY * DEF_DD_MAX_DIRS) / DEF_DD_SEC_SIZE | Number of sectors in directory

DEF_BLOCK_512_SHIFT =         2                                       | Left shift 2 = multiply * 4 = block size / HDD sector size
DEF_BLOCK_128_SHIFT =         4                                       | Left shift 4 = multiply by 16 = block size / CPM sector size

SECT_HDD_CPM_SHIFT  =         2                                       | Shift by 2 to convert from hdd to cpm sectors

