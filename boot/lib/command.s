                    .include  "include/macros.i"
                    .include  "include/ide.i"
                    .include  "include/io-device.i"
                    .include  "include/file-sys.i"

lineBufferLen       =         80
maxTokens           =         10
                    .global   cmdLoop
                    .global   bootOS9Cmd
                    .global   cmdTokens
                    .global   cmdTokenCount
                    
*---------------------------------------------------------------------------------------------------------
                    .bss
                    .align(2)

lineBuffer:         ds.b      lineBufferLen
cmdTokens:          ds.l      maxTokens
cmdTokenCount:      ds.w      1
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
                    CMD_TABLE_ENTRY "a", "a:", driveACmd, "a                   : Select drive A", 0
                    CMD_TABLE_ENTRY "b", "b:", driveBCmd, "b                   : Select drive B", 0
          .ifdef              IS_68030
                    CMD_TABLE_ENTRY "cas", "cas", showCacheCmd, "cas                 : Show the cache control register", 0
                    CMD_TABLE_ENTRY "cai", "cai", enableAddressCacheCmd, "cai                 : Enable the address cache", 0
                    CMD_TABLE_ENTRY "cdi", "cdi", enableDataCacheCmd, "cdi                 : Enable the data cache", 0
          .endif
                    CMD_TABLE_ENTRY "console", "con", setConsoleCmd, "console <[A|B|P|U]> : Set the console device", 0
                    CMD_TABLE_ENTRY "cpm", "cpm", bootCpmCmd, "cpm                 : Boot CP/M-68K from the current drive", 0
          .ifdef              IS_68030
                    CMD_TABLE_ENTRY "cromix", "cmx", bootCromixCmd, "cromix <file>       : Load cromix.sys S-Record <file> into memory and execute", 0
          .endif
                    CMD_TABLE_ENTRY "dir", "ls", directoryCmd, "dir                 : Display directory of current drive", 0
                    CMD_TABLE_ENTRY "def", "def", diskDefCmd, "def                 : Display the CPM disk definition", 0
                    CMD_TABLE_ENTRY "error", "error", errorCmd, "error               : Read the error register of the current drive", 0
                    CMD_TABLE_ENTRY "fdisk", "fdisk", fdiskCmd, "fdisk               : Display the current drive's MBR partition table", 0
                    CMD_TABLE_ENTRY "help", "h", helpCmd, "help                : Display the list of commands", 0
                    CMD_TABLE_ENTRY "id", "id", idCmd, "id                  : Display the drive's id info", 0
                    CMD_TABLE_ENTRY "init", "init", initIdeDriveCmd, "init                : Initialise the current IDE drive", 0
                    CMD_TABLE_ENTRY "irqm", "qm", irqMaskCmd, "irqm                : Display or set the IRQ mask", 0
                    CMD_TABLE_ENTRY "irqc", "qc", showIrqCountsCmd, "irqc                : Display the IRQ counts", 0
                    CMD_TABLE_ENTRY "irqz", "qz", zeroIrqCountsCmd, "irqz                : Zero the IRQ counts", 0
                    CMD_TABLE_ENTRY "key", "key", keyCmd, "key                 : Display key strokes as ASCII, terminated by new line", 0
                    CMD_TABLE_ENTRY "lba", "lba", lbaCmd, "lba <val>           : Set selected drive's LBA value", 0
                    CMD_TABLE_ENTRY "mbr", "mbr", mbrCmd, "mbr                 : Read the current drive's MBR partition table", 0
                    CMD_TABLE_ENTRY "mem", "mem", memDumpCmd, "mem <addr> <len>    : Display <len> bytes starting at <addr>", 0
                    CMD_TABLE_ENTRY "u", "u", memNextCmd, "u                   : Read the next memory block", 0
                    CMD_TABLE_ENTRY "i", "i", memPrevCmd, "i                   : Read the previous memory block", 0
                    CMD_TABLE_ENTRY "os9", "os9", bootOS9Cmd, "os9 <addr>          : Boot OS9 at address <addr>", 0
                    CMD_TABLE_ENTRY "part", "p", partitionCmd, "part <partId>       : Select partition <partId>", 0
                    CMD_TABLE_ENTRY "ottmr", "or", ottmrCmd, "ottmr <addr>        : Read 32 bit value from <addr>", 0
                    CMD_TABLE_ENTRY "ottmw", "ow", ottmwCmd, "ottmw <addr> <value>: Write 32 bit <value> to <addr>", 0
                    CMD_TABLE_ENTRY "ottms", "os", ottmsCmd, "ottms <bank>        : Set 16 32 bit values to <bank>", 0
                    CMD_TABLE_ENTRY "ottmd", "od", ottmdCmd, "ottmd <bank>        : Display 16 32 bit values from <bank>", 0
                    CMD_TABLE_ENTRY "ottmt", "ot", ottmtCmd, "ottmt <bank>        : Test <bank>", 0
                    CMD_TABLE_ENTRY "pin", "pi", readPortCmd, "pin <port>          : Read from portNo", 0
                    CMD_TABLE_ENTRY "pout", "po", writePortCmd, "pout <port> <byte>  : Write byte to portNo", 0
                    CMD_TABLE_ENTRY "restart", "restart", restartCmd, "restart             : Restart the monitor", 0
                    CMD_TABLE_ENTRY "read", "r", readCmd, "read <lba>          : Read and display the drive sector at <lba>", 0
                    CMD_TABLE_ENTRY "readNext", ">", readNextCmd, ">                   : Increment LBA, read and display the drive sector", 0
                    CMD_TABLE_ENTRY "readPrev", "<", readPrevCmd, "<                   : Decrement LBA, read and display the drive sector", 0
                    CMD_TABLE_ENTRY "regs", "rg", regsCmd, "regs                : Display registers ", 0
                    CMD_TABLE_ENTRY "rtcr", "rr", rtcReadCmd, "rtcr <addr>         : Read RTC address", 0
                    CMD_TABLE_ENTRY "rtcw", "rw", rtcWriteCmd, "rtcw <addr> <value> : Write RTC address", 0
                    CMD_TABLE_ENTRY "rtcd", "rd", rtcDisplayCmd, "rtcd                : Display RTC time", 0
                    CMD_TABLE_ENTRY "rtcs", "rs", rtcSetCmd, "rtcs <date> <time>  : Set RTC date 'YYYY MM DD' and time 'hh mm ss'", 0
                    CMD_TABLE_ENTRY "run", "ru", runCmd, "run <file>          : Load S-Record <file> into memory and run", 0
                    CMD_TABLE_ENTRY "scmd", "sc", serialCmdCmd, "scmd <[A|B]> Reg Val: Send Val to register Reg for port A, B", 0
                    CMD_TABLE_ENTRY "sin", "sn", serialInCmd, "sin <[A|B|U]>       : Input from Serial port A, B or USB to console", 0
                    CMD_TABLE_ENTRY "sinit", "si", serialInitCmd, "sinit <[A|B]>       : Initialise serial port A or B", 0
                    CMD_TABLE_ENTRY "sloop", "sl", serialLoopCmd, "sloop <[A|B|U]>     : Loopback serial port A, B or USB", 0
                    CMD_TABLE_ENTRY "sout", "so", serialOutCmd, "sout <[A|B|U]>      : Console out to serial port A, B or USB", 0
                    CMD_TABLE_ENTRY "sstat", "ss", serialStatusCmd, "sstat <[A|B|U]>     : Get the status of serial port A, B or USB", 0
                    CMD_TABLE_ENTRY "sreset", "sr", serialResetCmd, "sreset              : Reset both serial ports", 0
                    CMD_TABLE_ENTRY "ssp", "ssp", sspCmd, "ssp <addr>          : Set the stack pointer to <addr> and restart", 0
          .ifdef              IS_68030
                    CMD_TABLE_ENTRY "stack", "s", stackCmd, "stack               : Test the stack", 0
                    CMD_TABLE_ENTRY "status", "status", statusCmd, "status              : Read the status register of the current drive", 0
                    CMD_TABLE_ENTRY "testb", "tb", testByteCmd, "testb <addr> <len>  : Memory test <len> bytes starting at <addr>", 0
                    CMD_TABLE_ENTRY "testd", "td", testDWordCmd, "testd <addr> <len>  : Memory test <len> double words starting at <addr>", 0
                    CMD_TABLE_ENTRY "testf", "tf", testDWordFCmd, "testf <addr> <len>  : Memory fast test <len> double words starting at <addr>", 0
          .endif
                    CMD_TABLE_ENTRY "ts", "ts", tuartStatusCmd, "ts <A|B>            : Display TU-ART port A or B status", 0
                    CMD_TABLE_ENTRY "ti", "ti", tuartInitCmd, "ti                  : Initialise TU-ART ports", 0
                    CMD_TABLE_ENTRY "unix", "u", bootUnixCmd, "unix                : Load unix100 COFF file into memory and execute", 0
                    CMD_TABLE_ENTRY "ummu", "um", initUnixMMU, "ummu                : Initialise the MMU for Unix", 0
                    CMD_TABLE_ENTRY "w0", "w0", ideWait0Cmd, "w0                  : Set the IDE wait 0 parameter", 1
                    CMD_TABLE_ENTRY "w1", "w1", ideWait1Cmd, "w1                  : Set the IDE wait 1 parameter", 1
                    CMD_TABLE_ENTRY "w2", "w2", ideWait2Cmd, "w2                  : Set the IDE wait 2 parameter", 1
                    CMD_TABLE_ENTRY "w3", "w3", ideWait3Cmd, "w3                  : Set the IDE wait 3 parameter", 1
                    CMD_TABLE_ENTRY "exec", "x", execCmd, "exec <file> <params>: Execute COFF/ELF <file>", 0

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

*---------------------------------------------------------------------------------------------------------
* Command loop: display prompt, read input, find command entry, execute
*---------------------------------------------------------------------------------------------------------
cmdLoop:            BSR       newLine
                    BSR       writeDrive
                    PUTCH     #':'
                    BSR       writePartition
                    PUTS      strPrompt

                    MOVE.B    #lineBufferLen,%D0                      | Get a command line
                    LEA       lineBuffer,%A0
                    BSR       readLn

                    CMPI.B    #0,%D0                                  | Check for empty line
                    BEQ       cmdLoop                                 | Try again

                    LEA       cmdTokens,%A1
                    MOVE.B    #maxTokens,%D1
                    BSR       split
                    MOVE.W    %D0,cmdTokenCount                       | Returns token count

                    TST.B     %D0                                     | Check for a blank string
                    BEQ       cmdLoop

                    LEA       cmdTokens,%A1
                    MOVE.L    (%A1),%A0                               | Look for a command that matches the first token
rc1:                BSR       getCmd
                    BEQ       1f

                    BSR       unknownCmd                              | Unknown command, display error
                    BRA       cmdLoop                                 | and continue

1:                  MOVE.L    cmdEntrySubroutine(%A0),%A2             | Get the address of the command
                    MOVE.W    cmdTokenCount,%D0                       | %D0 will contain the number of command line tokens
                    LEA       cmdTokens,%A0                           | %A0 will contain the token array
                    JSR       (%A2)                                   | Jump to the command's subroutine

                    BRA       cmdLoop                                 | and repeat ...

*---------------------------------------------------------------------------------------------------------
* Search the command table for the command pointed to by %A0, return a pointer to the command entry in %A0
*---------------------------------------------------------------------------------------------------------
getCmd:             MOVE.L    #0,%D1
                    LEA       cmdTable,%A2

1:                  MOVE.L    cmdEntryName(%A2),%A1                   | Get the address of the commands name
                    BSR       stringcmp                               | Compare 
                    BEQ       3f

                    MOVE.L    cmdEntryCmd(%A2),%A1                    | Get the address of the commands cmd
                    BSR       stringcmp                               | Compare 
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
                    PUTS      strId1                                  | Identification string
                    PUTS      strId2
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
driveACmd:          MOVEM.L   %A0/%D0,-(%SP)                          | Save the command pointer, and arg count
                    BSR       selectDriveA                            | Select drive A
                    MOVEM.L   (%SP)+,%A0/%D0                          | Restore the command pointer, and arg count
                    CMPI.B    #2,%D0                                  | Check if a partition has been specified
                    BLT       1f                                      | No, so exit
                    BRA       pCmd                                    | Yes, select the parition
1:                  RTS

*---------------------------------------------------------------------------------------------------------
* Select drive B
*---------------------------------------------------------------------------------------------------------
driveBCmd:          MOVEM.L   %A0/%D0,-(%SP)                          | Save the command pointer, and arg count     
                    BSR       selectDriveB                            | Select drive B
                    MOVEM.L   (%SP)+,%A0/%D0                          | Restore the command pointer, and arg count
                    CMPI.B    #2,%D0                                  | Check if a partition has been specified
                    BLT       1f                                      | No, so exit
                    BRA       pCmd                                    | Yes, select the parition
1:                  RTS

*---------------------------------------------------------------------------------------------------------
* Select the partition
*---------------------------------------------------------------------------------------------------------
partitionCmd:       CMPI.B    #2,%D0                                  | Needs at least two args
                    BLT       wrongArgs

pCmd:               MOVE.L    %A0,%A1                                 | Use %A1 as the arg base pointer

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

          .ifdef              IS_68030
*---------------------------------------------------------------------------------------------------------
* Read the status register of the current drive
*---------------------------------------------------------------------------------------------------------
statusCmd:          BSR       readStatus
                    PUTCH     #' '
                    BSR       writeBitByte
                    BSR       newLine
                    RTS
          .endif

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
* Boot unix
*---------------------------------------------------------------------------------------------------------
unixArgs:			.long	strUnix100

bootUnixCmd:        CMPI.B    #1,%D0                                  | Needs one arg
                    BLT       wrongArgs

                    LINK      %FP,#-8
                    ADDQ.L    #4,%A0
                    MOVE.L    %A0,-4(%FP)                             | Save argv
                    SUBQ.L    #1,%D0
                    MOVE.L    %D0,-8(%FP)                             | Save argc

                    BSR       newLine

                    PUTS      strSerialInit
                    BSR       serInitA
                    BSR       serInitB
                    BSR       newLine
                    
					BSR		  initUnixMMU
					
					MOVE.L    #fatTable,-(%SP)                        | fatTable address
					MOVE.L    #biosTable,-(%SP) 	  			      | biosTable address
					LEA		  unixArgs,%A0
					MOVE.L	  %A0,-(%SP)                              | argv
                    MOVE.L    #1,-(%SP)                               | argc
                    BSR       fatInit
                    BNE       1f                                      | Failed

                    BSR       executeCE
                    ADD.L     #12,%SP

                    BSR       fatExit

1:                  UNLK      %FP
					RTS
					
*---------------------------------------------------------------------------------------------------------
* Boot cromix
*---------------------------------------------------------------------------------------------------------
bootCromixCmd:
                    CMPI.B    #2,%D0                                  | Needs one or two args
                    BGT       wrongArgs
                    MOVE.B    %D0,%D7                                 | Stash the arg count in D7

*                    BEQ       1f
*
*                    BSR       cromixBootLoader
*                    BRA       10f


1:                  MOVE.W    currentDrive,-(%SP)                     | Get current drive
                    BSR       getFileSysType
                    ADD.L     #2,%SP

                    CMPI.W    #FS_FAT,%D0
                    BEQ       2f

                    CMPI.W    #FS_CROMIX,%D0
                    BEQ       3f

                    PUTS      strUnsupportedType                      | Unsupported partition
                    BRA       11f

2:                  MOVE.L    4(%A0),-(%SP)                           | Argument specifies the SRecord file
                    BSR       loadRecordFile                          | Will return start address in %D0
                    ADDQ.L    #4,%SP
                    BRA       10f

3:                  MOVE.L    #0,-(%SP)                               | Write to offset 0
                    CMPI.B    #2,%D7                                  | Check the argument count to see if a sys file has been specified
                    BEQ       4f                                      | Sys file has been specified
                    MOVE.L    #strCromixSys, -(%SP)                   | Sys file has not been specified, assume cromix.sys
                    BRA       5f
4:                  MOVE.L    4(%A0),-(%SP)                           | Argument specifies the cromix.sys file

5:                  MOVE.W    currentDrive,-(%SP)                     | driveId
                    BSR       getPartitionId                          | Get the drive's current partition
                    ADD       #2,%SP

                    EXT.L     %D0
                    MOVE.L    %D0,-(%SP)
                    MOVE.W    currentDrive,%D0                        | driveId
                    EXT.L     %D0
                    MOVE.L    %D0,-(%SP)
                    BSR       getPartitionStart                       | Get the offset (in sectors) to the start of the partition
                    ADD       #8,%SP

                    MOVE.L    %D0,-(%SP)                              | partitionStart
                    MOVE.W    currentDrive,%D0
                    EXT.L     %D0
                    MOVE.L    %D0,-(%SP)                              | driveId

                    BSR       readCromixFile
                    ADD       #0x10,%SP
                    CMP.L     #0,%D0
                    BNE       10f                                     | file has been loaded, boot it

                    PUTS      strNoFile
                    BRA       11f

10:                 PUTS      strBootingCromix

                    MOVE.L    0x0,%SP                                 | Load the stack pointer
                    MOVE.L    0x04,%A0                                | Get the start address
                    JMP       (%A0)                                   | Start cromix

11:                 RTS

*---------------------------------------------------------------------------------------------------------
* Jump to address
*---------------------------------------------------------------------------------------------------------
bootOS9Cmd:         
*                   CMPI.B    #2,%D0                                  | Needs at least two args
*                   BLT       wrongArgs
                    
                    BSR       newLine
                    
*1:                  MOVE.L    %A0,%A1                                 | Use A1
*                    MOVE.L    4(%A1),%A0                              | arg[1], memory address
*                    BSR       asciiToLong
                    
                    MOVE.L    #0xF00000,%A0
                    
                    MOVE.L    0(%A0),%SP
                    MOVE.L    4(%A0),%A0
                    JMP       (%A0)
	 
*---------------------------------------------------------------------------------------------------------
* Execute the arg[1] COFF/ELF file
*---------------------------------------------------------------------------------------------------------
execCmd:            CMPI.B    #2,%D0                                  | Needs at least two args
                    BLT       wrongArgs

                    LINK      %FP,#-8
                    ADDQ.L    #4,%A0
                    MOVE.L    %A0,-4(%FP)                             | Save argv
                    SUBQ.L    #1,%D0
                    MOVE.L    %D0,-8(%FP)                             | Save argc

                    BSR       newLine

					MOVE.L    #fatTable,-(%SP)                        | fatTable address
					MOVE.L    #biosTable,-(%SP) 	  			      | biosTable address
                    MOVE.L    -4(%FP),-(%SP)                          | argv
                    MOVE.L    -8(%FP),-(%SP)                          | argc
                    BSR       fatInit
                    BNE       1f                                      | Failed

                    BSR       executeCE
                    ADD.L     #12,%SP

                    BSR       fatExit

1:                  UNLK      %FP
                    RTS

*
*---------------------------------------------------------------------------------------------------------
* Load the arg[1] file into memory and execute
*---------------------------------------------------------------------------------------------------------
runCmd:             CMPI.B    #2,%D0                                  | Needs at least two args
                    BLT       wrongArgs

                    LINK      %FP,#-8
                    MOVE.L    %A0,-4(%FP)                             | Save argv
                    MOVE.L    %D0,-8(%FP)                             | Save argc

                    BSR       newLine

                    MOVE.L    4(%A0),-(%SP)
                    BSR       loadRecordFile                          | Will return start address in %D0
                    ADDQ.L    #4,%SP

                    TST.L     %D0
                    BEQ       2f                                      | Error already displayed
                    CMPI.L    #1,%D0
                    BEQ       1f

                    MOVE.L    %D0,%A0                                 | Start execution address

                    MOVE.L    -4(%FP),%A1
                    ADDQ.L    #4,%A1
                    MOVE.L    %A1,-(%SP)                              | argv

                    MOVE.L    -8(%FP),%D0
                    SUBQ.L    #1,%D0
                    MOVE.L    %D0,-(%SP)                              | argc

                    JSR       (%A0)                                   | Execute
                    ADDQ.L    #8,%SP
                    BRA       2f

1:                  PUTS      strFileNotFound
2:                  UNLK      %FP
                    RTS

*---------------------------------------------------------------------------------------------------------
* Boot CP/M from the current drive
*---------------------------------------------------------------------------------------------------------
bootCpmCmd:         BSR       newLine
                    BSR       cpmBootLoader                           | Call the CP/M boot loader
                    PUTS      strBootLoaderError                      | Should never return
                    RTS

          .ifdef              IS_68030
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
* Memory double word fast test command: %D0 contains the number of entered command args, %A0 the start of the arg array
*---------------------------------------------------------------------------------------------------------
testDWordFCmd:      CMPI.B    #3,%D0                                  | Needs three args
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
                    BSR       memDWordFast

                    RTS
          .endif

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
* OTT memory read command: %D0 contains the number of entered command args, %A0 the start of the arg array
*---------------------------------------------------------------------------------------------------------
ottmrCmd:           CMPI.B    #2,%D0                                  | Needs one or two args
                    BEQ       1f

                    CMPI.B    #1,%D0                                  | Needs one arg to read at default address
                    BNE       wrongArgs

                    MOVE.L    #0x10000000,%D0
                    BRA       2f

1:                  MOVE.L    %A0,%A1                                 | Use A1
                    MOVE.L    4(%A1),%A0                              | arg[1], memory address
                    BSR       asciiToLong

2:                  PUTS      strReadAddr
                    BSR       writeHexLong
                    PUTS      strEqualsHex

                    MOVE.L    %D0,%A0
                    MOVE.L    (%A0),%D0

                    BSR       writeHexLong
                    BSR       newLine
2:                  RTS

*---------------------------------------------------------------------------------------------------------
* OTT memory write command: %D0 contains the number of entered command args, %A0 the start of the arg array
*---------------------------------------------------------------------------------------------------------
ottmwCmd:           MOVE.L    %A0,%A1                                 | Use A1

                    CMPI.B    #3,%D0                                  | Needs two or three args
                    BEQ       1f

                    CMPI.B    #2,%D0                                  | Needs one arg to read at default address
                    BNE       wrongArgs

                    MOVE.L    #0x10000000,%D0
                    BRA       2f

1:                  MOVE.L    4(%A1),%A0                              | arg[1], memory address
                    BSR       asciiToLong

2:                  PUTS      strWriteAddr
                    BSR       writeHexLong
                    PUTS      strEqualsHex

                    MOVE.L    %D0,%A2

                    MOVE.L    8(%A1),%A0                              | arg[2], value to write
                    BSR       asciiToLong
                    BSR       writeHexLong
                    BSR       newLine

                    MOVE.L    %D0,(%A2)

2:                  RTS

*---------------------------------------------------------------------------------------------------------
* OTT memory test command: %D0 contains the number of entered command args, %A0 the start of the arg array
*---------------------------------------------------------------------------------------------------------
ottmtCmd:           MOVE.L    %A0,%A1                                 | Use A1

                    CMPI.B    #2,%D0                                  | Needs one or two args
                    BEQ       1f

                    CMPI.B    #1,%D0                                  | Needs one arg to write at default address
                    BNE       wrongArgs

                    MOVE.L    #0,%D0
                    BRA       2f

1:                  MOVE.L    4(%A1),%A0                              | arg[1], memory address
                    BSR       asciiToLong

2:                  CMPI.B    #0,%D0
                    BNE       3f
                    MOVE.L    #0x10000000,%A2
                    BRA       7f

3:                  CMPI.B    #1,%D0
                    BNE       4f
                    MOVE.L    #0x14000000,%A2
                    BRA       7f

4:                  CMPI.B    #2,%D0
                    BNE       5f
                    MOVE.L    #0x18000000,%A2
                    BRA       7f

5:                  CMPI.B    #3,%D0
                    BNE       6f
                    MOVE.L    #0x1c000000,%A2
                    BRA       7f

6:                  BRA       wrongArgs

7:                  PUTS      strTestAddr
                    MOVE.L    %A2,%D0
                    BSR       writeHexLong
                    BSR       newLine

                    MOVE.L    #0,%D6
                    MOVE.L    #0,%D5
                    MOVE.L    #0,%D4

8:                  MOVE.L    %D4,%D0
*                    MOVE.B    %D4,%D0                                 | Copy test byte to each of the four bytes
*                    ROL.W     #8,%D0
*                    MOVE.B    %D4,%D0
*                    SWAP      %D0
*                    MOVE.B    %D4,%D0
*                    ROL.W     #8,%D0
*                    MOVE.B    %D4,%D0

                    MOVE.L    %D0,(%A2)                               | Write to address
                    MOVE.L    (%A2),%D1                               | Read from address
                    CMP.L     %D0,%D1
                    BEQ       9f
                                                                      | Failed
                    MOVE.L    0xFCFC0000,%D2                          | FPGA analyser trigger
                    MOVE.L    (%A2),%D2                               | Read again

                    ADDI.L    #1,%D5                                  | Increment error count
                    BRA       11f

9:                  ADDI.L    #1,%D6                                  | Increment correct count
10:                 ADDI.L    #1,%D4                                  | Increment iteration count
                    CMPI.L    #0,%D4                                  | If back to zero -> exit
                    BNE       8b                                      | Continue

11:                 MOVE.L    %D0,%D3                                 | Display expected value
                    PUTS      strWrite
                    MOVE.L    %D3,%D0
                    BSR       writeHexLong

                    PUTS      strRead1                                | Display first read value
                    MOVE.L    %D1,%D0
                    BSR       writeHexLong

                    PUTS      strRead2                                | Display second read value
                    MOVE.L    %D2,%D0
                    BSR       writeHexLong
                    BSR       newLine

                    PUTS      strCorrect                              | Display correct count
                    MOVE.L    %D6,%D0
                    BSR       writeHexLong

                    PUTS      strFails                                | Display error count
                    MOVE.L    %D5,%D0
                    BSR       writeHexLong
                    BSR       newLine

                    CMPI.L    #0x20,%D5                               | If max errors -> exit
                    BNE       10b

                    BSR       newLine
                    RTS

*---------------------------------------------------------------------------------------------------------
* OTT memory set command: %D0 contains the number of entered command args, %A0 the start of the arg array
*---------------------------------------------------------------------------------------------------------
ottmsCmd:           CMPI.B    #2,%D0                                  | Needs one or two args
                    BEQ       1f

                    CMPI.B    #1,%D0                                  | Needs one arg to write at default address
                    BNE       wrongArgs

                    MOVE.L    #0,%D0
                    BRA       2f

1:                  MOVE.L    %A0,%A1                                 | Use A1
                    MOVE.L    4(%A1),%A0                              | arg[1], memory address
                    BSR       asciiToLong

2:                  CMPI.B    #0,%D0
                    BNE       3f
                    MOVE.L    #0x10000000,%A2
                    BRA       7f

3:                  CMPI.B    #1,%D0
                    BNE       4f
                    MOVE.L    #0x14000000,%A2
                    BRA       7f

4:                  CMPI.B    #2,%D0
                    BNE       5f
                    MOVE.L    #0x18000000,%A2
                    BRA       7f

5:                  CMPI.B    #3,%D0
                    BNE       6f
                    MOVE.L    #0x1c000000,%A2
                    BRA       7f

6:                  BRA       wrongArgs

7:                  PUTS      strWriteAddr
                    MOVE.L    %A2,%D0
                    BSR       writeHexLong

                    MOVE.L    #0x33221100,(%A2)
                    ADD.L     #4,%A2
                    MOVE.L    #0x44332211,(%A2)
                    ADD.L     #4,%A2
                    MOVE.L    #0x55443322,(%A2)
                    ADD.L     #4,%A2
                    MOVE.L    #0x66554433,(%A2)
                    ADD.L     #4,%A2
                    MOVE.L    #0x77665544,(%A2)
                    ADD.L     #4,%A2
                    MOVE.L    #0x88776655,(%A2)
                    ADD.L     #4,%A2
                    MOVE.L    #0x99887766,(%A2)
                    ADD.L     #4,%A2
                    MOVE.L    #0xAA998877,(%A2)
                    ADD.L     #4,%A2
                    MOVE.L    #0xBBAA9988,(%A2)
                    ADD.L     #4,%A2
                    MOVE.L    #0xCCBBAA99,(%A2)
                    ADD.L     #4,%A2
                    MOVE.L    #0xDDCCBBAA,(%A2)
                    ADD.L     #4,%A2
                    MOVE.L    #0xEEDDCCBB,(%A2)
                    ADD.L     #4,%A2
                    MOVE.L    #0xFFEEDDCC,(%A2)
                    ADD.L     #4,%A2
                    MOVE.L    #0x00FFEEDD,(%A2)
                    ADD.L     #4,%A2
                    MOVE.L    #0x1100FFEE,(%A2)
                    ADD.L     #4,%A2
                    MOVE.L    #0x221100FF,(%A2)

                    BSR       newLine

                    RTS

*---------------------------------------------------------------------------------------------------------
* OTT memory display command: %D0 contains the number of entered command args, %A0 the start of the arg array
*---------------------------------------------------------------------------------------------------------
ottmdCmd:           CMPI.B    #2,%D0                                  | Needs two or three args
                    BEQ       1f

                    CMPI.B    #1,%D0                                  | Needs one arg to read at default address
                    BNE       wrongArgs

                    MOVE.L    #0x10000000,%D0
                    BRA       5f

1:                  MOVE.L    %A0,%A1                                 | Use A1
                    MOVE.L    4(%A1),%A0                              | arg[1], memory address
                    BSR       asciiToLong

                    CMPI.B    #0,%D0
                    BNE       2f
                    MOVE.L    #0x10000000,%D0
                    BRA       5f

2:                  CMPI.B    #1,%D0
                    BNE       2f
                    MOVE.L    #0x14000000,%D0
                    BRA       5f

2:                  CMPI.B    #2,%D0
                    BNE       3f
                    MOVE.L    #0x18000000,%D0
                    BRA       5f

3:                  CMPI.B    #3,%D0
                    BNE       4f
                    MOVE.L    #0x1c000000,%D0
                    BRA       5f

4:                  BRA       wrongArgs

5:                  MOVE.L    %D0,%A2
                    MOVE.L    #0,%D1

6:                  PUTS      strReadAddr
                    BSR       writeHexLong
                    PUTS      strEqualsHex
                    MOVE.L    (%A2),%D0
                    BSR       writeHexLong

                    ADD.L     #4,%A2
                    MOVE.L    %A2,%D0
                    ADDI.L    #4,%D1
                    CMP.L     #0x40,%D1
                    BLT       6b

                    BSR       newLine

                    RTS

*---------------------------------------------------------------------------------------------------------
* Display or set the IRQ mask
*---------------------------------------------------------------------------------------------------------
irqMaskCmd:         CMPI.B    #2,%D0                                  | Needs two args to set mask
                    BEQ       1f

                    CMPI.B    #1,%D0                                  | Needs one arg to show mask
                    BNE       wrongArgs

                    PUTS      strEqualsHex
                    BSR       getIrqMask
                    BSR       writeHexDigit
                    BSR       newLine
                    BRA       2f

1:                  MOVE.L    4(%A0),%A0                              | arg[1], irq mask
                    BSR       asciiToLong
                    BSR       setIrqMask

2:                  RTS

*---------------------------------------------------------------------------------------------------------
* Display the current IRQ count values
*---------------------------------------------------------------------------------------------------------
showIrqCountsCmd:   BSR       showIrqCounts
                    RTS

*---------------------------------------------------------------------------------------------------------
* Zero the IRQ count values
*---------------------------------------------------------------------------------------------------------
zeroIrqCountsCmd:   BSR       zeroIrqCounts
                    RTS

          .ifdef              IS_68030
*---------------------------------------------------------------------------------------------------------
* Display the registers
*---------------------------------------------------------------------------------------------------------
regsCmd:            BSR       writeRegs
                    RTS
          .endif

*---------------------------------------------------------------------------------------------------------
* Restart the monitor
*---------------------------------------------------------------------------------------------------------
restartCmd:			BSR       newLine
                    JMP       warmBoot                                | Restart

*---------------------------------------------------------------------------------------------------------
* Set stack pointer command: %D0 contains the number of entered command args, %A0 the start of the arg array
*---------------------------------------------------------------------------------------------------------
sspCmd:             CMPI.B    #2,%D0                                  | Needs two args to set SP
                    BEQ       1f

                    CMPI.B    #1,%D0                                  | Needs one arge to show SP
                    BNE       wrongArgs

                    PUTS      strEqualsHex
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

          .ifdef              IS_68030
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
          .endif

          .ifdef              IS_68030
*---------------------------------------------------------------------------------------------------------
* Display the cache register
*---------------------------------------------------------------------------------------------------------
showCacheCmd:       PUTS      strCacheRegister
                    MOVEC     #0x002,%D0
                    BSR       writeHexLong
                    BSR       newLine
                    RTS

enableAddressCacheCmd:
                    MOVEC     #0x002,%D0
                    OR.L      #0x1,%D0
                    MOVEC     %D0,#0x002
                    BRA       showCacheCmd

enableDataCacheCmd:
                    MOVEC     #0x002,%D0
                    OR.L      #0x100,%D0
                    MOVEC     %D0,#0x002
                    BRA       showCacheCmd
                    RTS
          .endif

          .ifdef              IS_68030
*---------------------------------------------------------------------------------------------------------
* Initialise a serial port
*---------------------------------------------------------------------------------------------------------
setConsoleCmd:      CMPI.B    #2,%D0                                  | Needs two args for this command
                    BEQ       1f
                    BRA       wrongArgs

1:                  MOVE.L    4(%A0),%A0                              | arg[1], console device A, B, P, or U
                    MOVE.B    (%A0),%D1                               | Get first character
                    BSR       toUpperChar

                    CMPI.B    #DEV_SER_A,%D1
                    BEQ       2f
                    CMPI.B    #DEV_SER_B,%D1
                    BEQ       2f
                    CMPI.B    #DEV_PROP,%D1
                    BEQ       2f
                    CMPI.B    #DEV_USB,%D1
                    BEQ       2f

                    BRA       wrongArgs

2:                  MOVE.B    %D1,%D0
                    BSR       setIODevice
                    RTS
          .endif

          .ifdef              IS_68030
*---------------------------------------------------------------------------------------------------------
* Initialise a serial port
*---------------------------------------------------------------------------------------------------------
serialInitCmd:      CMPI.B    #2,%D0                                  | Needs two args to initialise a serial port
                    BEQ       1f
                    BRA       wrongArgs

1:                  MOVE.L    4(%A0),%A0                              | arg[1], serial port A or B
                    MOVE.B    (%A0),%D1                               | Get first character
                    BSR       toUpperChar

                    CMPI.B    #DEV_SER_A,%D1
                    BNE       2f

                    PUTS      strSerialInit
                    PUTCH     #DEV_SER_A
                    BSR       serInitA
                    BRA       3f

2:                  CMPI.B    #DEV_SER_B,%D1
                    BNE       wrongArgs

                    PUTS      strSerialInit
                    PUTCH     #DEV_SER_B
                    BSR       serInitB

3:                  RTS

*---------------------------------------------------------------------------------------------------------
* Reset both serial ports
*---------------------------------------------------------------------------------------------------------
serialResetCmd:     BSR       serReset
                    RTS

*---------------------------------------------------------------------------------------------------------
* Display the status of the TU-ART port a
*---------------------------------------------------------------------------------------------------------
tuartStatusCmd:     CMPI.B    #2,%D0                                  | Needs two args
                    BNE       wrongArgs

1:                  MOVE.L    4(%A0),%A0                              | arg[1], serial port A or B
                    MOVE.B    (%A0),%D1                               | Get first character
                    BSR       toUpperChar

                    CMPI.B    #DEV_SER_A,%D1
                    BNE       2f
                    BSR       newLine
                    BSR       tuart_a_status
                    BRA       3f

2:                  CMPI.B    #DEV_SER_B,%D1
                    BNE       wrongArgs
                    BSR       newLine
                    BSR       tuart_b_status

3:                  RTS

*---------------------------------------------------------------------------------------------------------
* Initialise TU-ART ports
*---------------------------------------------------------------------------------------------------------
tuartInitCmd:       BSR       newLine
                    BSR       tuart_init
                    RTS

*---------------------------------------------------------------------------------------------------------
* Display the status of the serial port
*---------------------------------------------------------------------------------------------------------
serialStatusCmd:    CMPI.B    #2,%D0                                  | Needs two args 
                    BEQ       1f
                    BRA       wrongArgs

1:                  MOVE.L    4(%A0),%A0                              | arg[1], serial port A, B or U
                    MOVE.B    (%A0),%D1                               | Get first character
                    BSR       toUpperChar

                    CMPI.B    #DEV_SER_A,%D1
                    BNE       2f

                    PUTS      strSerialStatus
                    PUTCH     #DEV_SER_A
                    BSR       serStatusA

                    BRA       4f

2:                  CMPI.B    #DEV_SER_B,%D1
                    BNE       3f

                    PUTS      strSerialStatus
                    PUTCH     #DEV_SER_B
                    BSR       serStatusB

                    BRA       4f

3:                  CMPI.B    #DEV_USB,%D1
                    BNE       wrongArgs

                    PUTS      strSerialStatus
                    PUTCH     #DEV_USB
                    BSR       serStatusUSB

4:                  BSR       newLine
                    RTS

*---------------------------------------------------------------------------------------------------------
* Set or get the control register value for a serial port
*---------------------------------------------------------------------------------------------------------
serialCmdCmd:       MOVE.L    %A0,%A1

                    CMPI.B    #4,%D0                                  | Needs four args to set a register value
                    BEQ       serialCmdSet

                    CMPI.B    #3,%D0                                  | Needs three args to get a register value
                    BEQ       serialCmdGet

                    BRA       wrongArgs

*---------------------------------------------------------------------------------------------------------
* Set the control register value for a serial port
*---------------------------------------------------------------------------------------------------------
serialCmdSet:       MOVE.L    0x8(%A1),%A0                            | arg[2], register byte
                    BSR       asciiToLong                             | value returned in D0
                    MOVE.B    %D0,%D7

                    MOVE.L    0xC(%A1),%A0                            | arg[3], value byte
                    BSR       asciiToLong                             | value returned in D0
                    MOVE.B    %D0,%D6

                    MOVE.L    4(%A1),%A0                              | arg[1], serial port A or B
                    MOVE.B    (%A0),%D1                               | Get first character
                    BSR       toUpperChar

                    CMPI.B    #DEV_SER_A,%D1
                    BNE       1f

                    MOVE.B    %D6,%D0
                    MOVE.B    %D7,%D1
                    BRA       serCmdA

1:                  CMPI.B    #DEV_SER_B,%D1
                    BNE       2f

                    MOVE.B    %D6,%D0
                    MOVE.B    %D7,%D1
                    BRA       serCmdB

2:                  BRA       wrongArgs

*---------------------------------------------------------------------------------------------------------
* Get the control register value for a serial port
*---------------------------------------------------------------------------------------------------------
serialCmdGet:       MOVE.L    0x8(%A1),%A0                            | arg[2], register byte
                    BSR       asciiToLong                             | value returned in D0
                    MOVE.B    %D0,%D7

                    MOVE.L    4(%A1),%A0                              | arg[1], serial port A or B
                    MOVE.B    (%A0),%D1                               | Get first character
                    BSR       toUpperChar

                    CMPI.B    #DEV_SER_A,%D1
                    BNE       1f

                    MOVE.B    %D7,%D1
                    BSR       serValA
                    BRA       2f

1:                  CMPI.B    #DEV_SER_B,%D1
                    BNE       3f

                    MOVE.B    %D7,%D1
                    BSR       serValB

2:                  BSR       newLine
                    BSR       writeHexByte
                    BSR       newLine
                    RTS

3:                  BRA       wrongArgs

*---------------------------------------------------------------------------------------------------------
* Serial port input command
*---------------------------------------------------------------------------------------------------------
serialInCmd:        CMPI.B    #2,%D0                                  | Needs two args to loopback a serial port
                    BEQ       1f
                    BRA       wrongArgs

1:                  MOVE.L    4(%A0),%A0                              | arg[1], serial port A, B or U
                    MOVE.B    (%A0),%D1                               | Get first character
                    BSR       toUpperChar

                    CMPI.B    #DEV_SER_A,%D1
                    BNE       2f

                    PUTS      strSerialIn
                    PUTCH     #DEV_SER_A
                    BSR       newLine
                    BSR       serInA
                    BRA       5f

2:                  CMPI.B    #DEV_SER_B,%D1
                    BNE       3f

                    PUTS      strSerialIn
                    PUTCH     #DEV_SER_B
                    BSR       newLine
                    BSR       serInB
                    BRA       5f

3:                  CMPI.B    #DEV_USB,%D1
                    BNE       4f

                    PUTS      strSerialIn
                    PUTS      strUSB
                    BSR       newLine
                    BSR       serInUSB
                    BRA       5f

4:                  BRA       wrongArgs
5:                  RTS

*---------------------------------------------------------------------------------------------------------
* Serial port output command
*---------------------------------------------------------------------------------------------------------
serialOutCmd:       CMPI.B    #2,%D0                                  | Needs two args to loopback a serial port
                    BEQ       1f
                    BRA       wrongArgs

1:                  MOVE.L    4(%A0),%A0                              | arg[1], serial port A, B or U
                    MOVE.B    (%A0),%D1                               | Get first character
                    BSR       toUpperChar

                    CMPI.B    #DEV_SER_A,%D1
                    BNE       2f

                    PUTS      strSerialOut
                    PUTCH     #DEV_SER_A
                    BSR       newLine
                    BSR       serOutA
                    BRA       5f

2:                  CMPI.B    #DEV_SER_B,%D1
                    BNE       3f

                    PUTS      strSerialOut
                    PUTCH     #DEV_SER_B
                    BSR       newLine
                    BSR       serOutB
                    BRA       5f

3:                  CMPI.B    #DEV_USB,%D1
                    BNE       4f

                    PUTS      strSerialOut
                    PUTS      strUSB
                    BSR       newLine
                    BSR       serOutUSB
                    BRA       5f

4:                  BRA       wrongArgs
5:                  RTS
          .endif

          .ifdef              IS_68030
*---------------------------------------------------------------------------------------------------------
* Serial port loopback command
*---------------------------------------------------------------------------------------------------------
serialLoopCmd:      CMPI.B    #2,%D0                                  | Needs two args to loopback a serial port
                    BEQ       1f
                    BRA       wrongArgs

1:                  MOVE.L    4(%A0),%A0                              | arg[1], serial port A, B or U
                    MOVE.B    (%A0),%D1                               | Get first character
                    BSR       toUpperChar

                    CMPI.B    #DEV_SER_A,%D1
                    BNE       2f

                    PUTS      strSerialLoop
                    PUTCH     #DEV_SER_A
                    BSR       newLine
                    BSR       loopA
                    BRA       5f

2:                  CMPI.B    #DEV_SER_B,%D1
                    BNE       3f

                    PUTS      strSerialLoop
                    PUTCH     #DEV_SER_B
                    BSR       newLine
                    BSR       loopB
                    BRA       5f

3:                  CMPI.B    #DEV_USB,%D1
                    BNE       4f

                    PUTS      strSerialLoop
                    PUTS      strUSB
                    BSR       newLine
                    BSR       loopUSB
                    BRA       5f

4:                  BRA       wrongArgs
5:                  RTS
          .endif

          .ifdef              IS_68030
*---------------------------------------------------------------------------------------------------------
* Read port command
*---------------------------------------------------------------------------------------------------------
readPortCmd:        CMPI.B    #2,%D0                                  | Needs two args to read a port
                    BEQ       1f
                    BRA       wrongArgs

1:                  PUTS      strReadPort

                    MOVE.L    4(%A0),%A0                              | arg[1], port number
                    BSR       asciiToLong                             | value returned in D0
                    ADD.L     #__ports_start__,%D0                    | Add port number to start of port range

                    BSR       writeHexLong
                    PUTS      strEqualsHex

                    MOVE.L    %D0,%A0                                 | Read from the port
                    MOVE.B    (%A0),%D0

                    BSR       writeHexByte
                    BSR       newLine

                    RTS

*---------------------------------------------------------------------------------------------------------
* Write port command
*---------------------------------------------------------------------------------------------------------
writePortCmd:       CMPI.B    #3,%D0                                  | Needs three args to write a port
                    BEQ       1f
                    BRA       wrongArgs

1:                  MOVE.L    %A0,%A1

                    PUTS      strWritePortA

                    MOVE.L    8(%A1),%A0                              | arg[2], data byte
                    BSR       asciiToLong                             | value returned in D0

                    BSR       writeHexByte
                    PUTS      strWritePortB

                    MOVE.B    %D0,%D1

                    MOVE.L    4(%A1),%A0                              | arg[1], address
                    BSR       asciiToLong                             | value returned in D0
                    
                    ADD.L     #__ports_start__,%D0                    | Add port number to start of port range

                    BSR       writeHexLong
                    BSR       newLine

                    MOVE.L    %D0,%A0                                 | Write the data byte to the port
                    MOVE.B    %D1,(%A0)

                    RTS

*---------------------------------------------------------------------------------------------------------
* Read RTC command
*---------------------------------------------------------------------------------------------------------
rtcReadCmd:         CMPI.B    #2,%D0                                  | Needs two args to read a RTC address
                    BEQ       1f
                    BRA       wrongArgs

1:                  PUTS      strReadRTC

                    MOVE.L    4(%A0),%A0                              | arg[1], address
                    BSR       asciiToLong                             | value returned in D0

                    BSR       writeHexLong
                    PUTS      strEqualsHex

                    MOVE.L    #0x70,%A1
                    ADD.L     #__ports_start__,%A1                    | Add port number to start of port range
                    MOVE.L    #0x71,%A2
                    ADD.L     #__ports_start__,%A2                    | Add port number to start of port range

                    MOVE.B    %D0,(%A1)                               | Write address to port 0x70
                    MOVE.B    (%A2),%D0                               | Read data from port 0x71

                    BSR       writeHexByte
                    BSR       newLine

                    RTS

*---------------------------------------------------------------------------------------------------------
* RTC display command
*---------------------------------------------------------------------------------------------------------
rtcDisplayCmd:
                    LINK      %FP,#-8
                    ADDQ.L    #4,%A0
                    MOVE.L    %A0,-(%SP)                             | Save argv
                    SUBQ.L    #1,%D0
                    MOVE.L    %D0,-(%SP)                             | Save argc

                    BSR       newLine

*                    MOVE.L    -4(%FP),-(%SP)                          | argv
*                    MOVE.L    -8(%FP),-(%SP)                          | argc

                    BSR       displayTime
                    ADD.L     #8,%SP

1:                  UNLK      %FP
                    RTS
                    
*---------------------------------------------------------------------------------------------------------
* RTC set command
*---------------------------------------------------------------------------------------------------------
rtcSetCmd:
                    LINK      %FP,#-8
                    MOVE.L    %A0,-(%SP)                             | Save argv
                    MOVE.L    %D0,-(%SP)                             | Save argc

                    BSR       newLine

                    BSR       setTime
                    ADD.L     #8,%SP

1:                  UNLK      %FP
                    RTS
                    
*---------------------------------------------------------------------------------------------------------
* Write RTC command
*---------------------------------------------------------------------------------------------------------
rtcWriteCmd:        CMPI.B    #3,%D0                                  | Needs three args to write a RTC address
                    BEQ       1f
                    BRA       wrongArgs

1:                  MOVE.L    %A0,%A1

                    PUTS      strWritePortA

                    MOVE.L    8(%A1),%A0                              | arg[2], data byte
                    BSR       asciiToLong                             | value returned in D0

                    BSR       writeHexByte
                    PUTS      strWriteRTCB

                    MOVE.B    %D0,%D1

                    MOVE.L    4(%A1),%A0                              | arg[1], address
                    BSR       asciiToLong                             | value returned in D0
                    
                    BSR       writeHexLong
                    BSR       newLine

                    MOVE.L    #0x70,%A2
                    ADD.L     #__ports_start__,%A2                    | Add port number to start of port range
                    MOVE.L    #0x71,%A3
                    ADD.L     #__ports_start__,%A3                    | Add port number to start of port range
                    
                    MOVE.B    %D0,(%A2)
                    MOVE.B    %D1,(%A3)
                    RTS
          .endif

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

strPrompt:          .asciz    "$ "
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
strEqualsHex:       .asciz    " = 0x"
strCromixSys:       .asciz    "cromix.sys"
strBootingCromix:   .asciz    "\r\nBooting cromix ...\r\n"
strNoFile:          .asciz    "\r\nFile not found\r\n"
strReadAddr:        .asciz    "\r\nRead from address 0x"
strWriteAddr:       .asciz    "\r\nWrite to address  0x"
strTestAddr:        .asciz    "\r\nTest at address  0x"
strCorrect:         .asciz    "Correct 0x"
strFails:           .asciz    ", failed 0x"
strWrite:           .asciz    "\r\nw 0x"
strRead1:           .asciz    " r1 0x"
strRead2:           .asciz    " r2 0x"

          .ifdef              IS_68030
strStackErr1:       .asciz    "Stack error, expected 0x"
strStackErr2:       .asciz    ", read 0x"
strReadPort:        .asciz    "\r\nRead from port 0x"
strWritePortA:      .asciz    "\r\nWrite 0x"
strWritePortB:      .asciz    " to port 0x"
strReadRTC:         .asciz    "\r\nRead from RTC Address 0x"
strWriteRTCB:       .asciz    " to RTC Address 0x"
strSerialInit:      .asciz    "\r\nInitialising serial port "
strSerialStatus:    .asciz    "\r\nStatus of serial port "
strSerialLoop:      .asciz    "\r\nLoopback serial port "
strSerialIn:        .asciz    "\r\nInput from serial port "
strSerialOut:       .asciz    "\r\nOutput to serial port "
strUSB:             .asciz    "USB\r\n"
strCacheRegister:   .asciz    "\r\nCache register: "
strUnix100:         .asciz    "unix100"
          .endif
