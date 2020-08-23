                    .include  "include/macros.i"
                    .include  "include/ide.i"

lineBufferLen       =         60
maxTokens           =         4
                    .global   memDumpCmd,memNextCmd,memPrevCmd,s,irqMaskCmd
*---------------------------------------------------------------------------------------------------------
                    .bss
                    .align(2)

lineBuffer:         ds.b      lineBufferLen
tokens:             ds.l      maxTokens
dumpAddr:           ds.l      1

*---------------------------------------------------------------------------------------------------------
* Create the command table.  Each entry has three pointers:
*    0: Address of the name
*    1: Address of the cmd
*    2: Address of the description
*---------------------------------------------------------------------------------------------------------

                    .section  .rodata.cmdTable
                    .align(16)

cmdTable:                                                             | Array of command entries
                    CMD_TABLE_ENTRY "a", "a", driveACmd, "a                  : Select drive A", 0
                    CMD_TABLE_ENTRY "b", "b", driveBCmd, "b                  : Select drive B", 0
                    CMD_TABLE_ENTRY "boot", "boot", bootCmd, "boot <file>        : Load S-Record <file> into memory and execute", 0
                    CMD_TABLE_ENTRY "dir", "ls", directoryCmd, "dir                : Display directory of current drive", 0
                    CMD_TABLE_ENTRY "def", "def", diskDefCmd, "def                : Display the CPM disk definition", 0
                    CMD_TABLE_ENTRY "error", "error", errorCmd, "error              : Read the error register of the current drive", 0
                    CMD_TABLE_ENTRY "fdisk", "fdisk", fdiskCmd, "fdisk              : Display the current drive's MBR partition table", 0
                    CMD_TABLE_ENTRY "help", "h", helpCmd, "help               : Display the list of commands", 0
                    CMD_TABLE_ENTRY "id", "id", idCmd, "id                 : Display the drive's id info", 0
                    CMD_TABLE_ENTRY "init", "init", initIdeDriveCmd, "init               : Initialise the current IDE drive", 0
                    CMD_TABLE_ENTRY "key", "key", keyCmd, "key                : Display key strokes as ASCII, terminated by new line", 0
                    CMD_TABLE_ENTRY "lba", "lba", lbaCmd, "lba <val>          : Set selected drive's LBA value", 0
                    CMD_TABLE_ENTRY "mbr", "mbr", mbrCmd, "mbr                : Read the current drive's MBR partition table", 0
                    CMD_TABLE_ENTRY "mem", "mem", memDumpCmd, "mem <addr> <len>   : Display <len> bytes starting at <addr>", 0
                    CMD_TABLE_ENTRY "u", "u", memNextCmd, "u                  : Read the next memory block", 0
                    CMD_TABLE_ENTRY "i", "i", memPrevCmd, "i                  : Read the next memory block", 0
                    CMD_TABLE_ENTRY "irq", "q", irqMaskCmd, "irq                : Display or set the IRQ mask", 0
                    CMD_TABLE_ENTRY "part", "p", partitionCmd, "part <partId>      : Select partition <partId>", 0
                    CMD_TABLE_ENTRY "read", "r", readCmd, "read <lba>         : Read and display the drive sector at <lba>", 0
                    CMD_TABLE_ENTRY "readNext", ">", readNextCmd, ">                  : Increment LBA, read and display the drive sector", 0
                    CMD_TABLE_ENTRY "readPrev", "<", readPrevCmd, "<                  : Decrement LBA, read and display the drive sector", 0
                    CMD_TABLE_ENTRY "regs", "rg", regsCmd, "regs               : Display the registers", 0
                    CMD_TABLE_ENTRY "ssp", "ssp", sspCmd, "ssp <addr>         : Set the stack pointer to <addr> and restart", 0
                    CMD_TABLE_ENTRY "stack", "s", stackCmd, "stack              : Test the stack", 0
                    CMD_TABLE_ENTRY "status", "status", statusCmd, "status             : Read the status register of the current drive", 0
                    CMD_TABLE_ENTRY "testb", "tb", testByteCmd, "testb <addr> <len> : Memory test <len> bytes starting at <addr>", 0
                    CMD_TABLE_ENTRY "testd", "td", testDWordCmd, "testd <addr> <len> : Memory test <len> double words starting at <addr>", 0
                    CMD_TABLE_ENTRY "w0", "w0", ideWait0Cmd, "w0                 : Set the IDE wait 0 parameter", 1
                    CMD_TABLE_ENTRY "w1", "w1", ideWait1Cmd, "w1                 : Set the IDE wait 1 parameter", 1
                    CMD_TABLE_ENTRY "w2", "w2", ideWait2Cmd, "w2                 : Set the IDE wait 2 parameter", 1
                    CMD_TABLE_ENTRY "w3", "w3", ideWait3Cmd, "w3                 : Set the IDE wait 3 parameter", 1

cmdTableLength      =         . - cmdTable
cmdEntryLength      =         0x12
cmdTableEntries     =         cmdTableLength / cmdEntryLength

* Offsets into a command table entry
cmdEntryName        =         0x0                                     | Offset to the address of the name
cmdEntryCmd         =         0x4                                     | Offset to the address of the name
cmdEntrySubroutine  =         0x8                                     | Offset to the address of the subroutine
cmdEntryDescription =         0xc                                     | Offset to the address of description
cmdEntryHidden      =         0x10                                    | Offset to the hidden flag

*---------------------------------------------------------------------------------------------------------

                    .text
                    .global   cmdLoop
                    .global   partitionCmd                            | **** DEBUG

*---------------------------------------------------------------------------------------------------------
* Command loop: display prompt, read input, find command entry, execute
*---------------------------------------------------------------------------------------------------------
cmdLoop:            BSR       newLine
                    BSR       writeDrive
                    PUTS      strPrompt

                    MOVE.B    #lineBufferLen,%D0                      | Get a command line
                    LEA       lineBuffer,%A0
                    BSR       readLn

                    CMPI.B    #0,%D0                                  | Check for empty line
                    BEQ       cmdLoop                                 | Try again

                    LEA       tokens,%A1
                    MOVE.B    #maxTokens,%D1
                    BSR       split
                    MOVE.B    %D0,%D3                                 | Returns token count

                    TST.B     %D3                                     | Check for a blank string
                    BEQ       cmdLoop

                    LEA       tokens,%A1
                    MOVE.L    (%A1),%A0                               | Look for a command that matches the first token
rc1:                BSR       getCmd
                    BEQ       1f

                    BSR       unknownCmd                              | Unknown command, display error
                    BRA       cmdLoop                                 | and continue

1:                  MOVE.L    cmdEntrySubroutine(%A0),%A2             | Get the address of the command
                    MOVE.B    %D3,%D0                                 | %D0 will contain the number of command line tokens
                    LEA       tokens,%A0                              | %A0 will contain the token array
                    JSR       (%A2)                                   | Jump to the command's subroutine

                    BRA       cmdLoop                                 | and repeat ...

*---------------------------------------------------------------------------------------------------------
* Search the command table for the command pointed to by %A0, return a pointer to the command entry in %A0
*---------------------------------------------------------------------------------------------------------
getCmd:             MOVE.L    #0,%D1
                    LEA       cmdTable,%A2

1:                  MOVE.L    cmdEntryName(%A2),%A1                   | Get the address of the commands name
                    BSR       strcmp                                  | Compare 
                    BEQ       3f

                    MOVE.L    cmdEntryCmd(%A2),%A1                    | Get the address of the commands cmd
                    BSR       strcmp                                  | Compare 
                    BNE       4f

3:                  MOVE.L    %A2,%A0                                 | Matches, return address of command entry in %A0 
                    CLR.W     %D0                                     | return %D0 = 0, Z is set
                    RTS

4:                  ADD.L     #cmdEntryLength,%A2
                    ADDQ.B    #1,%D1                                  | Next entry
                    CMP.B     #cmdTableEntries,%D1
                    BNE       1b

                    MOVE.W    #1,%D0                                  | No matches, return %D0 = 1, Z is clear
                    RTS

*---------------------------------------------------------------------------------------------------------
* Display the list of command descriptions
*---------------------------------------------------------------------------------------------------------
helpCmd:            BSR       newLine
                    PUTS      strID                                   | Identification string
                    PUTS      strHelpHeader
                    MOVE.B    #0,%D0
                    LEA       cmdTable,%A1

1:                  TST       cmdEntryHidden(%A1)                     | Don't display if hidden
                    BNE       2f

                    MOVE.L    cmdEntryDescription(%A1),%A2            | Pointer to the description
                    BSR       writeStr
                    BSR       newLine

2:                  ADD.L     #cmdEntryLength,%A1                     | next entry
                    ADDQ.B    #1,%D0
                    CMP.B     #cmdTableEntries,%D0
                    BNE       1b

                    RTS

*---------------------------------------------------------------------------------------------------------
*
*---------------------------------------------------------------------------------------------------------
unknownCmd:         PUTS      strUnknownCommand
                    RTS

*---------------------------------------------------------------------------------------------------------
* Select drive A
*---------------------------------------------------------------------------------------------------------
driveACmd:          BSR       selectDriveA
                    RTS

*---------------------------------------------------------------------------------------------------------
* Select drive B
*---------------------------------------------------------------------------------------------------------
driveBCmd:          BSR       selectDriveB
                    RTS

*---------------------------------------------------------------------------------------------------------
* Select the partition
*---------------------------------------------------------------------------------------------------------
partitionCmd:       CMPI.B    #2,%D0                                  | Needs at least two args
                    BLT       wrongArgs

                    MOVE.L    %A0,%A1                                 | Use %A1 as the arg base pointer

                    MOVE.L    4(%A1),%A0                              | arg[1], partitionId value
                    MOVE.B    (%A0),%D0
                    SUBI.B    #'0',%D0

                    CMPI      #0,%D0                                  | partitionId must be >=0 and < 4
                    BLT       invalidArg
                    CMPI      #4,%D0
                    BGE       invalidArg

                    EXT.W     %D0
                    MOVE.W    %D0,-(%SP)                              | specified partitionId
                    MOVE.W    currentDrive,-(%SP)                     | current driveId
                    BSR       setPartitionId
                    ADD.L     #4,%SP

                    RTS

*---------------------------------------------------------------------------------------------------------
* Display the current drive's partition table
*---------------------------------------------------------------------------------------------------------
fdiskCmd:           BSR       getDriveStatus
                    BNE       1f

                    PUTS      strDriveNotInitialised                  | Drive not initialised, show error
                    BRA       2f

1:                  BSR       newLine

                    MOVE.W    currentDrive,-(%SP)
                    BSR       showPartitions
                    ADD.L     #2,%SP

2:                  RTS

*---------------------------------------------------------------------------------------------------------
* Read the MBR partition table for the current drive
*---------------------------------------------------------------------------------------------------------
mbrCmd:             BSR       newLine
                    MOVE.W    #0,-(%SP)                               | Display errors
                    MOVE.W    currentDrive,-(%SP)                     | Read the partition table, if present, from the master boot record
                    BSR       readMBR
                    ADD       #4,%SP
                    RTS

*---------------------------------------------------------------------------------------------------------
* Initialise the current drive
*---------------------------------------------------------------------------------------------------------
initIdeDriveCmd:    BSR       newLine
                    BSR       initDrive
                    TST.W     %D0
                    BNE       1f
                    PUTS      strSuccess
1:                  RTS

*---------------------------------------------------------------------------------------------------------
* Display the drive's identify drive data
*---------------------------------------------------------------------------------------------------------
idCmd:              BSR       getDriveStatus
                    BNE       1f

                    PUTS      strDriveNotInitialised                  | Drive not initialised, show error
                    BRA       2f

1:                  BSR       newLine
                    BSR       showDriveIdent                          | Show the drive's indent information

2:                  RTS

*---------------------------------------------------------------------------------------------------------
* Key - ASCII command
*---------------------------------------------------------------------------------------------------------
keyCmd:             BSR       newLine

1:                  BSR       readCh                                  | read the next character from the keyboard into %D0
                    BSR       writeHexByte                            | Output as hex
                    PUTCH     #' '

                    CMPI.B    #0x0d,%D0                               | If not CR, repeat
                    BNE       1b

                    RTS

*---------------------------------------------------------------------------------------------------------
* Read the disk sector at the specified lba
*---------------------------------------------------------------------------------------------------------
readCmd:            CMPI.B    #2,%D0                                  | Needs at least two args
                    BLT       wrongArgs
                    MOVE.L    %A0,%A1                                 | Use %A1 as the arg base pointer

                    MOVE.L    4(%A1),%A0                              | arg[1], lba value
                    BSR       asciiToLong
                    TST.L     %D0
                    BLT       invalidArg                              | Invalid

                    BSR       setLBA

                    MOVE.L    #0x10,%D0                               | One sector
                    LEA       __free_ram_start__,%A2                  | Use the free ram as a buffer
                    BSR       readSectors

                    LEA       __free_ram_start__,%A0                  | Dump the buffer
                    MOVE.L    #0x00, %A1                              | Display as address 0
                    MOVE.L    #IDE_SEC_SIZE,%D0
                    BSR       memDump

                    RTS

*---------------------------------------------------------------------------------------------------------
* Read the next disk sector
*---------------------------------------------------------------------------------------------------------
readNextCmd:        BSR       incrementLBA

                    MOVE.L    #0x10,%D0                               | One sector
                    LEA       __free_ram_start__,%A2                  | Use the free ram as a buffer
                    BSR       readSectors

                    LEA       __free_ram_start__,%A0                  | Dump the buffer
                    MOVE.L    #0x00, %A1                              | Display as address 0
                    MOVE.L    #IDE_SEC_SIZE,%D0
                    BSR       memDump

                    RTS

*---------------------------------------------------------------------------------------------------------
* Read the previous disk sector
*---------------------------------------------------------------------------------------------------------
readPrevCmd:        BSR       decrementLBA

                    MOVE.L    #0x10,%D0                               | One sector
                    LEA       __free_ram_start__,%A2                  | Use the free ram as a buffer
                    BSR       readSectors

                    LEA       __free_ram_start__,%A0                  | Dump the buffer
                    MOVE.L    #0x00, %A1                              | Display as address 0
                    MOVE.L    #IDE_SEC_SIZE,%D0
                    BSR       memDump

                    RTS

*---------------------------------------------------------------------------------------------------------
* Read the status register of the current drive
*---------------------------------------------------------------------------------------------------------
statusCmd:          BSR       readStatus
                    PUTCH     #' '
                    BSR       writeBitByte
                    BSR       newLine
                    RTS

*---------------------------------------------------------------------------------------------------------
* Read the error register of the current drive
*---------------------------------------------------------------------------------------------------------
errorCmd:           BSR       readError
                    PUTCH     #' '
                    BSR       writeBitByte
                    BSR       newLine
                    RTS

*---------------------------------------------------------------------------------------------------------
* Display the current drive's directory
*---------------------------------------------------------------------------------------------------------
directoryCmd:       BSR       getDriveStatus
                    BNE       1f

                    PUTS      strDriveNotInitialised                  | Drive not initialised, show error
                    BRA       2f

1:                  BSR       listDirectory                           | Do the directory listing

2:                  RTS

*---------------------------------------------------------------------------------------------------------
* Set the LBA value
*---------------------------------------------------------------------------------------------------------
lbaCmd:             CMPI.B    #2,%D0                                  | Needs at least two args
                    BLT       wrongArgs

                    MOVE.L    %A0,%A1                                 | Use %A1 as the arg base pointer

                    MOVE.L    4(%A1),%A0                              | arg[1], lba value
                    BSR       asciiToLong
                    TST.L     %D0
                    BLT       invalidArg                              | Invalid

                    BSR       setLBA
                    RTS

*---------------------------------------------------------------------------------------------------------
* Display the CPM current disk definition
*---------------------------------------------------------------------------------------------------------
diskDefCmd:         BSR       showDiskDef
                    RTS

*---------------------------------------------------------------------------------------------------------
* Load the arg[1] file into memory and execute
*---------------------------------------------------------------------------------------------------------
bootCmd:            BSR       newLine

                    CMPI.B    #2,%D0                                  | Is there a file specified
                    BLT       loader                                  | No, try and read the boot loader from the system tracks

                    MOVE.L    4(%A0),-(%SP)
                    BSR       loadRecordFile                          | Will return start address in %D0
                    ADDQ.L    #4,%SP

                    TST.B     %D0
                    BEQ       1f

                    CMPI.B    #1,%D0
                    BNE       1f                                      | Error already displayed

                    PUTS      strFileNotFound
                    BRA       1f

loader:             BSR       loadBootLoader                          | Call the boot loader

                    PUTS      strBootLoaderError                      | Should never return
1:                  RTS

*---------------------------------------------------------------------------------------------------------
* Memory byte test command: %D0 contains the number of entered command args, %A0 the start of the arg array
*---------------------------------------------------------------------------------------------------------
testByteCmd:        CMPI.B    #3,%D0                                  | Needs three args
                    BLT       wrongArgs

                    MOVE.B    %D0,%D2                                 | Save arg count

                    MOVE.L    %A0,%A1                                 | Use A1

                    MOVE.L    4(%A1),%A0                              | arg[1], start address
                    BSR       asciiToLong
                    TST.L     %D0
                    BLT       invalidArg                              | Invalid

                    MOVE.L    %D0,-(%SP)                              | preserve the address

                    MOVE.L    8(%A1),%A0                              | arg[2], length
                    BSR       asciiToLong
                    TST.L     %D0
                    BLT       invalidArg                              | Invalid

1:                  MOVE.L    (%SP)+,%A0                              | Restore the start address to %A0, length is now in %D0
                    BSR       memByteTest

                    RTS

*---------------------------------------------------------------------------------------------------------
* Memory double word test command: %D0 contains the number of entered command args, %A0 the start of the arg array
*---------------------------------------------------------------------------------------------------------
testDWordCmd:       CMPI.B    #3,%D0                                  | Needs three args
                    BLT       wrongArgs

                    MOVE.B    %D0,%D2                                 | Save arg count

                    MOVE.L    %A0,%A1                                 | Use A1

                    MOVE.L    4(%A1),%A0                              | arg[1], start address
                    BSR       asciiToLong
                    TST.L     %D0
                    BLT       invalidArg                              | Invalid

                    MOVE.L    %D0,-(%SP)                              | preserve the address

                    MOVE.L    8(%A1),%A0                              | arg[2], length
                    BSR       asciiToLong
                    TST.L     %D0
                    BLT       invalidArg                              | Invalid

1:                  MOVE.L    (%SP)+,%A0                              | Restore the start address to %A0, length is now in %D0
                    BSR       memDWordTest

                    RTS

*---------------------------------------------------------------------------------------------------------
* Memory dump command: %D0 contains the number of entered command args, %A0 the start of the arg array
*---------------------------------------------------------------------------------------------------------
memDumpCmd:         CMPI.B    #2,%D0                                  | Needs at least two args
                    BLT       wrongArgs

                    MOVE.B    %D0,%D2                                 | Save arg count

                    MOVE.L    %A0,%A1                                 | Use A1

                    MOVE.L    4(%A1),%A0                              | arg[1], start address
                    BSR       asciiToLong
*                    TST.L     %D0
*                    BLT       invalidArg                              | Invalid

*                    CMPI.L    #0xFF0000,%D0                           | Upper memory limit???
*                    BGE       invalidArg

                    MOVE.L    %D0,-(%SP)                              | preserve the address

                    MOVE.L    %D0,dumpAddr                            | Save the address for next and prev commands 

                    MOVE.L    #0x200,%D0                              | Default length
                    CMPI.B    #3,%D2                                  | Has length been specified?
                    BLT       1f                                      | No, use default

                    MOVE.L    8(%A1),%A0                              | arg[2], length
                    BSR       asciiToLong
                    TST.L     %D0
                    BLT       invalidArg                              | Invalid

1:                  MOVE.L    (%SP)+,%A0                              | Restore the start address to %A0, length is now in %D0
                    MOVE.L    %A0,%A1                                 | Display the actual address
                    BSR       memDump
                    RTS

*---------------------------------------------------------------------------------------------------------
* Memory dump next command
*---------------------------------------------------------------------------------------------------------
memNextCmd:         MOVE.L    dumpAddr,%A0
                    ADD.L     #0x200,%A0
                    MOVE.L    %A0,%A1
                    MOVE.L    %A0,dumpAddr
                    MOVE.L    #0x200,%D0
                    BSR       memDump
                    RTS

*---------------------------------------------------------------------------------------------------------
* Memory dump prev command
*---------------------------------------------------------------------------------------------------------
memPrevCmd:         MOVE.L    dumpAddr,%A0
                    SUB.L     #0x200,%A0
                    MOVE.L    %A0,%A1
                    MOVE.L    %A0,dumpAddr
                    MOVE.L    #0x200,%D0
                    BSR       memDump
                    RTS

*---------------------------------------------------------------------------------------------------------
* Display or set the IRQ mask
*---------------------------------------------------------------------------------------------------------
irqMaskCmd:         CMPI.B    #2,%D0                                  | Needs two args to set mask
                    BEQ       1f

                    CMPI.B    #1,%D0                                  | Needs one arg to show mask
                    BNE       wrongArgs

                    PUTS      strIrqMask
                    MOVE      %SR,%D0                                 | Show current IRQ Mask
                    LSR       #8,%D0
                    AND       #0x7,%D0
                    BSR       writeHexDigit
                    BSR       newLine
                    BRA       2f

1:                  MOVE.L    4(%A0),%A0                              | arg[1], irq mask
                    BSR       asciiToLong
                    AND       #0x7,%D0                                | 3 least significant bits
                    LSL       #8,%D0
                    MOVE      %SR,%D1
                    AND       #0xF800,%D1
                    OR        %D0,%D1
                    MOVE      %D1,%SR

2:                  RTS

*---------------------------------------------------------------------------------------------------------
* Display the registers
*---------------------------------------------------------------------------------------------------------
regsCmd:            BSR       writeRegs
                    RTS

*---------------------------------------------------------------------------------------------------------
* Set stack pointer command: %D0 contains the number of entered command args, %A0 the start of the arg array
*---------------------------------------------------------------------------------------------------------
sspCmd:             CMPI.B    #2,%D0                                  | Needs two args to set SP
                    BEQ       1f

                    CMPI.B    #1,%D0                                  | Needs one arge to show SP
                    BNE       wrongArgs

                    PUTS      strStackPtr
                    MOVE.L    %SP,%D0                                 | Show current SP
                    BSR       writeHexLong
                    BSR       newLine
                    BRA       2f

1:                  MOVE.L    %A0,%A1                                 | Use A1

                    MOVE.L    4(%A1),%A0                              | arg[1], stack address
                    BSR       asciiToLong
                    TST.L     %D0
                    BLT       invalidArg                              | Invalid

                    BSR       newLine

                    MOVE.L    %D0,%SP                                 | Set the stack point
                    JMP       warmBoot                                | Restart

2:                  RTS

*---------------------------------------------------------------------------------------------------------
* Test the stack
*---------------------------------------------------------------------------------------------------------
stackCmd:           MOVE.W    #0x1000,%D6

1:                  MOVE.L    #0x00000000,-(%SP)
                    MOVE.L    #0x55555555,-(%SP)
                    MOVE.L    #0xAAAAAAAA,-(%SP)
                    MOVE.L    #0xFFFFFFFF,-(%SP)

                    MOVE.L    (%SP)+,%D5
                    CMP.L     #0xFFFFFFFF,%D5
                    BEQ       2f

                    PUTS      strStackErr1
                    MOVE.L    #0xFFFFFFFF,%D0
                    BSR       writeHexLong
                    PUTS      strStackErr2
                    MOVE.L    %D5,%D0
                    BSR       writeHexLong
                    BSR       newLine

2:                  MOVE.L    (%SP)+,%D5
                    CMP.L     #0xAAAAAAAA,%D5
                    BEQ       3f

                    PUTS      strStackErr1
                    MOVE.L    #0xAAAAAAAA,%D0
                    BSR       writeHexLong
                    PUTS      strStackErr2
                    MOVE.L    %D5,%D0
                    BSR       writeHexLong
                    BSR       newLine

3:                  MOVE.L    (%SP)+,%D5
                    CMP.L     #0x55555555,%D5
                    BEQ       4f

                    PUTS      strStackErr1
                    MOVE.L    #0x55555555,%D0
                    BSR       writeHexLong
                    PUTS      strStackErr2
                    MOVE.L    %D5,%D0
                    BSR       writeHexLong
                    BSR       newLine

4:                  MOVE.L    (%SP)+,%D5
                    CMP.L     #0x00000000,%D5
                    BEQ       5f

                    PUTS      strStackErr1
                    MOVE.L    #0x00000000,%D0
                    BSR       writeHexLong
                    PUTS      strStackErr2
                    MOVE.L    %D5,%D0
                    BSR       writeHexLong
                    BSR       newLine

5:                  DBRA      %D6,1b

                    BSR       keystat
                    BNE       6f
*                    PUTCH     #'.'
                    BRA       stackCmd

6:                  RTS

*---------------------------------------------------------------------------------------------------------
* Set the IDE Wait 0 parameter
*---------------------------------------------------------------------------------------------------------
ideWait0Cmd:        PUTS      strCurrentWaitParameter                 | Display current value
                    MOVE.W    delayZero,%D0
                    BSR       writeHexWord

                    PUTS      strNewWaitParameter                     | Prompt for new value
                    BSR       readLong

                    TST.L     %D0
                    BNE       1f
                    PUTS      strInvalidValue
                    BRA       3f

1:                  CMPI.L    #0xFFFF,%D0
                    BLE       2f
                    PUTS      strInvalidValue
                    BRA       3f

2:                  MOVE.W    %D0,delayZero
3:                  RTS

*---------------------------------------------------------------------------------------------------------
* Set the IDE Wait 1 parameter
*---------------------------------------------------------------------------------------------------------
ideWait1Cmd:        PUTS      strCurrentWaitParameter                 | Display current value
                    MOVE.W    delayOne,%D0
                    BSR       writeHexWord

                    PUTS      strNewWaitParameter                     | Prompt for new value
                    BSR       readLong

                    TST.L     %D0
                    BNE       1f
                    PUTS      strInvalidValue
                    BRA       3f

1:                  CMPI.L    #0xFFFF,%D0
                    BLE       2f
                    PUTS      strInvalidValue
                    BRA       3f

2:                  MOVE.W    %D0,delayOne
3:                  RTS

*---------------------------------------------------------------------------------------------------------
* Set the IDE Wait 2 parameter
*---------------------------------------------------------------------------------------------------------
ideWait2Cmd:        PUTS      strCurrentWaitParameter                 | Display current value
                    MOVE.W    delayTwo,%D0
                    BSR       writeHexWord

                    PUTS      strNewWaitParameter                     | Prompt for new value
                    BSR       readLong

                    TST.L     %D0
                    BNE       1f
                    PUTS      strInvalidValue
                    BRA       3f

1:                  CMPI.L    #0xFFFF,%D0
                    BLE       2f
                    PUTS      strInvalidValue
                    BRA       3f

2:                  MOVE.W    %D0,delayTwo
3:                  RTS

*---------------------------------------------------------------------------------------------------------
* Set the IDE Wait 3 parameter
*---------------------------------------------------------------------------------------------------------
ideWait3Cmd:        PUTS      strCurrentWaitParameter                 | Display current value
                    MOVE.W    delayThree,%D0
                    BSR       writeHexWord

                    PUTS      strNewWaitParameter                     | Prompt for new value
                    BSR       readLong

                    TST.L     %D0
                    BNE       1f
                    PUTS      strInvalidValue
                    BRA       3f

1:                  CMPI.L    #0xFFFF,%D0
                    BLE       2f
                    PUTS      strInvalidValue
                    BRA       3f

2:                  MOVE.W    %D0,delayThree
3:                  RTS

*---------------------------------------------------------------------------------------------------------
wrongArgs:          PUTS      strWrongArgs
                    RTS

invalidArg:         PUTS      strInvalidArgs
                    RTS

*---------------------------------------------------------------------------------------------------------
                    .section  .rodata.strings
                    .align(2)

strPrompt:          .asciz    ":> "
strUnknownCommand:  .asciz    "\r\nunknown command"
strHelpHeader:      .asciz    "Available commands:\r\n"
strWrongArgs:       .asciz    "\r\nWrong arguments\r\n"
strInvalidArgs:     .asciz    "\r\nInvalid argument\r\n"
strFileNotFound:    .asciz    "\r\nFile not found\r\n"
strError:           .asciz    "\r\nError\r\n"
strSuccess:         .asciz    "Success\r\n"
strDriveNotInitialised: .asciz "\r\nDrive not initialised\r\n"
strBootLoaderError: .asciz    "Boot failed\r\n"
strCurrentWaitParameter: .asciz "\r\nCurrent wait parameter: 0x"
strNewWaitParameter: .asciz   "\r\nNew wait parameter:     0x"
strInvalidValue:    .asciz    "\r\nInvalid value\r\n"
strStackPtr:        .asciz    " = 0x"
strStackErr1:       .asciz    "Stack error, expected 0x"
strStackErr2:       .asciz    ", read 0x"
strIrqMask:         .asciz    " = 0x"

