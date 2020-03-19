
MON_TRAP            =         15                                      | Trap no. to call the monitor
MON_INIT            =         0x0                                     | Function 0: initialise
MON_CSTAT           =         0x2                                     | Function 2: console status
MON_CIN             =         0x3                                     | Function 3: consile in
MON_COUT            =         0x4                                     | Function 4 console out
MON_READ            =         0x5                                     | Function 5: disk read
MON_WRITE           =         0x6                                     | Function 6: disk write

DISK_COUNT          =         10                                      | this BIOS currently supports 10 drives

DPH_LEN             =         26                                      | length of disk parameter header

TRAP_3              =         0x8C                                    | Trap 3

MEM_END             =         $FCFFFF                                 | End of memory, the monitor starts after this

          .ifne               _GNU_
_ccp                =         0x4BC                                   | From CPM400.MAP
          .endif
