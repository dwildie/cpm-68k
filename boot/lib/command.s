                    .include  "include/macros.i"
                    .include  "include/ide.i"

*---------------------------------------------------------------------------------------------------------
* Create the command table.  Each entry has three pointers:
*    0: Address of the name
*    1: Address of the cmd
*    2: Address of the description
*---------------------------------------------------------------------------------------------------------

                    .section  .rodata.cmdTable
                    .align(16)

cmdTable:                                                   | Array of command entries
                    CMD_TABLE_ENTRY "a", driveACmd, "a                  : Select drive A"
                    CMD_TABLE_ENTRY "b", driveBCmd, "b                  : Select drive B"
                    CMD_TABLE_ENTRY "boot" bootCmd, "boot <file>        : Load S-Record <file> into memory and execute"
                    CMD_TABLE_ENTRY "dir", directoryCmd, "dir                : display directory of current drive"
                    CMD_TABLE_ENTRY "def",diskDefCmd, "def                : Display the CPM disk definition"
                    CMD_TABLE_ENTRY "help", helpCmd, "help               : Display the list of commands"
                    CMD_TABLE_ENTRY "id", idCmd, "id                 : Display the drive's id info"
                    CMD_TABLE_ENTRY "init", initIdeDriveCmd, "init               : Initialise the current IDE drive"
                    CMD_TABLE_ENTRY "lba", lbaCmd, "lba <val>          : Set selected drive's LBA value"
                    CMD_TABLE_ENTRY "mem", memDumpCmd, "mem <addr> <len>   : Display <len> bytes starting at <addr>"
                    CMD_TABLE_ENTRY "read", readCmd, "read <lba>         : Read and display the sector at <lba>"

cmdTableLength      =         . - cmdTable
cmdEntryLength      =         0x0c
cmdTableEntries     =         cmdTableLength / cmdEntryLength

* Offsets into a command table entry
cmdEntryName        =         0x0                           | Offset to the address of the name
cmdEntrySubroutine  =         0x4                           | Offset to the address of the subroutine
cmdEntryDescription =         0x8                           | Offset to the address of description

*---------------------------------------------------------------------------------------------------------

                    .text
                    .global   cmdLoop
                    .global   bootCmd                       | **** DEBUG

*---------------------------------------------------------------------------------------------------------
* Command loop: display prompt, read input, find command entry, execute
*---------------------------------------------------------------------------------------------------------
cmdLoop:            BSR       newLine
                    BSR       writeDrive
                    PUTS      strPrompt

                    MOVE.B    #lineBufferLen,%D0            | Get a command line
                    LEA       lineBuffer,%A0
                    BSR       readLn

                    CMPI.B    #0,%D0                        | Check for empty line
                    BEQ       cmdLoop                       | Try again

                    LEA       tokens,%A1
                    MOVE.B    #maxTokens,%D1
                    BSR       split
                    MOVE.B    %D0,%D3                       | Returns token count

                    TST.B     %D3                           | Check for a blank string
                    BEQ       cmdLoop

                    LEA       tokens,%A1
                    MOVE.L    (%A1),%A0                     | Look for a command that matches the first token
rc1:                BSR       getCmd
                    BEQ       1f

                    BSR       unknownCmd                    | Unknown command, display error
                    BRA       cmdLoop                       | and continue

1:                  MOVE.L    cmdEntrySubroutine(%A0),%A2   | Get the address of the command
                    MOVE.B    %D3,%D0                       | %D0 will contain the number of command line tokens
                    LEA       tokens,%A0                    | %A0 will contain the token array
                    JSR       (%A2)                         | Jump to the command's subroutine

                    BRA       cmdLoop                       | and repeat ...

*---------------------------------------------------------------------------------------------------------
* Search the command table for the command pointed to by %A0, return a pointer to the command entry in %A0
*---------------------------------------------------------------------------------------------------------
getCmd:             MOVE.L    #0,%D1
                    LEA       cmdTable,%A2
1:                  MOVE.L    cmdEntryName(%A2),%A1         | Get the address of the commands name
                    BSR       strcmp                        | Compare 
                    BNE       2f
                    MOVE.L    %A2,%A0                       | Matches, return address of command entry in %A0 
                    CLR.W     %D0                           | return %D0 = 0, Z is set
                    RTS

2:                  ADD.L     #cmdEntryLength,%A2
                    ADDQ.B    #1,%D1                        | Next entry
                    CMP.B     #cmdTableEntries,%D1
                    BNE       1b

                    MOVE.W    #1,%D0                        | No matches, return %D0 = 1, Z is clear
                    RTS

*---------------------------------------------------------------------------------------------------------
* Display the list of command descriptions
*---------------------------------------------------------------------------------------------------------
helpCmd:            PUTS      strHelpHeader
                    MOVE.B    #0,%D0
                    LEA       cmdTable,%A1

1:                  MOVE.L    cmdEntryDescription(%A1),%A2  | Pointer to the description
                    BSR       writeStr
                    BSR       newLine

                    ADD.L     #cmdEntryLength,%A1           | next entry
                    ADDQ.B    #1,%D0
                    CMP.B     #cmdTableEntries,%D0
                    BNE       1b

                    BSR       newLine

                    RTS

*---------------------------------------------------------------------------------------------------------
*
*---------------------------------------------------------------------------------------------------------
unknownCmd:         PUTS      strUnknownCommand
                    RTS

*---------------------------------------------------------------------------------------------------------
*
*---------------------------------------------------------------------------------------------------------
driveACmd:          BSR       selectDriveA
                    RTS

*---------------------------------------------------------------------------------------------------------
*
*---------------------------------------------------------------------------------------------------------
driveBCmd:          BSR       selectDriveB
                    RTS

*---------------------------------------------------------------------------------------------------------
* Initialise the current drive
*---------------------------------------------------------------------------------------------------------
initIdeDriveCmd:    BSR       newLine
                    BSR       initIdeDrive
                    TST.W     %D0
                    BNE       1f
                    PUTS      strSuccess
1:                  RTS

*---------------------------------------------------------------------------------------------------------
* Display the drive's identify drive data
*---------------------------------------------------------------------------------------------------------
idCmd:              BSR       newLine
                    BSR       showDriveIdent
                    RTS

*---------------------------------------------------------------------------------------------------------
* Read the disk sector at the specified lba
*---------------------------------------------------------------------------------------------------------
readCmd:            CMPI.B    #2,%D0                        | Needs at least two args
                    BLT       wrongArgs
                    MOVE.L    %A0,%A1                       | Use %A1 as the arg base pointer

                    MOVE.L    4(%A1),%A0                    | arg[1], lba value
                    BSR       asciiToLong
                    TST.L     %D0
                    BLT       invalidArg                    | Invalid

                    BSR       setLBA

                    MOVE.L    #1,%D0                        | One sector
                    LEA       __free_ram_start__,%A2        | Use the free ram as a buffer
                    BSR       readSectors

                    LEA       __free_ram_start__,%A0        | Dump the buffer
                    MOVE.L    #0x00, %A1                    | Display as address 0
                    MOVE.L    #IDE_SEC_SIZE,%D0
                    BSR       memDump

                    RTS

*---------------------------------------------------------------------------------------------------------
*
*---------------------------------------------------------------------------------------------------------
directoryCmd:       BSR       cpmDirectory
                    RTS

*---------------------------------------------------------------------------------------------------------
* Set the LBA value
*---------------------------------------------------------------------------------------------------------
lbaCmd:             CMPI.B    #2,%D0                        | Needs at least two args
                    BLT       wrongArgs

                    MOVE.L    %A0,%A1                       | Use %A1 as the arg base pointer

                    MOVE.L    4(%A1),%A0                    | arg[1], lba value
                    BSR       asciiToLong
                    TST.L     %D0
                    BLT       invalidArg                    | Invalid

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
bootCmd:            CMPI.B    #2,%D0                        | Needs at least two args
                    BLT       wrongArgs

                    BSR       newLine
                    MOVE.L    4(%A0),-(%SP)
                    BSR       loadRecordFile                | Will return start address in %D0
                    ADDQ.L    #4,%SP

                    TST.B     %D0
                    BEQ       1f

                    CMPI.B    #1,%D0
                    BNE       1f                            | Error already displayed

                    PUTS      strFileNotFound
                    BRA       1f

1:                  RTS

*---------------------------------------------------------------------------------------------------------
* Memory dump command: %D0 contains the number of entered command args, %A0 the start of the arg array
*---------------------------------------------------------------------------------------------------------
memDumpCmd:         CMPI.B    #2,%D0                        | Needs at least two args
                    BLT       wrongArgs

                    MOVE.B    %D0,%D2                       | Save arg count

                    MOVE.L    %A0,%A1                       | Use A1

                    MOVE.L    4(%A1),%A0                    | arg[1], start address
                    BSR       asciiToLong
                    TST.L     %D0
                    BLT       invalidArg                    | Invalid

                    CMPI.L    #0xFF0000,%D0                 | Upper memory limit???
                    BGE       invalidArg

                    MOVE.L    %D0,-(%SP)                    | preserve the address

                    MOVE.L    #0x100,%D0                    | Default length
                    CMPI.B    #3,%D2                        | Has length been specified?
                    BLT       1f                            | No, use default

                    MOVE.L    8(%A1),%A0                    | arg[2], length
                    BSR       asciiToLong
                    TST.L     %D0
                    BLT       invalidArg                    | Invalid

1:                  MOVE.L    (%SP)+,%A0                    | Restore the start address to %A0, length is now in %D0
                    MOVE.L    %A0,%A1                       | Display the actual address
                    BSR       memDump
                    RTS

*---------------------------------------------------------------------------------------------------------
wrongArgs:          PUTS      strWrongArgs
                    RTS

invalidArg:         PUTS      strInvalidArgs
                    RTS

*---------------------------------------------------------------------------------------------------------
                    .bss
                    .align(2)

lineBufferLen       =         60
lineBuffer:         ds.b      lineBufferLen

maxTokens           =         4
tokens:             ds.l      maxTokens

*---------------------------------------------------------------------------------------------------------
                    .section  .rodata.strings
                    .align(2)

strPrompt:          .asciz    ":> "
strUnknownCommand:  .asciz    "\r\nunknown command"
strHelpHeader:      .asciz    "\r\nAvailable commands:\r\n"
strWrongArgs:       .asciz    "\r\nWrong arguments\r\n"
strInvalidArgs:     .asciz    "\r\Invalid argument\r\n"
strFileNotFound:    .asciz    "\r\nFile not found\r\n"
strError:           .asciz    "\r\nError\r\n"
strSuccess:         .asciz    "Success\r\n"

