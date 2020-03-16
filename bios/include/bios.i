
MONITOR_TRAP        =         15                                      | Trap no. to call the monitor

DISK_COUNT          =         10                                      | this BIOS currently supports 10 drives

DISK_PARAM_HDR_LEN  =         26                                      | length of disk parameter header

TRAP_3              =         0x8C                                    | Trap 3

          .ifne               _GNU_
_ccp                =         0x4BC                                   | From CPM400.MAP
          .endif
