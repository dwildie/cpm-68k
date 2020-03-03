# CP/M 68K for the S100 68000/68010 card

This project provides:
* Boot loader/monitor
* CP/M 68K BIOS
* CP/M file system images

This code assumes, and has been tested with, the following hardware:
* [68000/68010 Card](http://www.s100computers.com/My%20System%20Pages/68000%20Board/68K%20CPU%20Board.htm)
* [Propeller Console IO Card](http://www.s100computers.com/My%20System%20Pages/Console%20IO%20Board/Console%20IO%20Board.htm)
* [16MB Static RAM card](http://www.s100computers.com/My%20System%20Pages/16MG%20RAM%20Board/16MG%20RAM%20Board.htm)
* [IDE/CF Card](http://www.s100computers.com/My%20System%20Pages/IDE%20Board/My%20IDE%20Card.htm)

Requires make, gnu 68000 cross tools, cpmtools to be installed.

Alternatively, use the following docker image which provides all the necessary tools:

  `docker run -it --rm --name 68k-tools -v {my project directory}:/opt/work dwildie/68k-tools:0.0.1 bash`
  
The [Dockerfile](https://github.com/dwildie/68k-tools/blob/master/docker/Dockerfile) documents the required pakages to be installed.

To build:  In the top level directory, type `make`

## Boot loader/monitor
The Boot loader/monitor is build for the standard memory configuration:
+ ROM at 0xFD0000
+ RAM at 0xFD8000

For a different memory configuration modify the MEMORY section in the `boot.rom.lnk` file.

Once built, the target directory will contain `boot.srec` which should be burnt to the EPROMS, normal even/odd config.

## CP/M 68K BIOS
The BIOS is configured for a full populated 16MB static RAM board.  For a different memory configyuration modify the MEMORY section in the `bios.lnk` file.  The CP/M memory region table entry is created from this configuration so it must reflect your hardware.

This BIOS delegates all console and disk IO to the boot loader/monitor.  Therefore, it will not function with another monitor.

The BIOS has a tuneable LRU disk buffer.  The tuning parameters are in `buffer.i`:
+ `BUFFER_COUNT` - The number of available buffers.  Buffers are reused based on a LRU algorithm.
+ `BUFFER_SECTORS` - The size of each buffer in HDD sectors (512 bytes).  The maximum size is 32 sectors, ie. 16KB.

The BIOS is configured to support a maximum of 10 drives mapped to a single multi-partitioned disk image.  This can be increased by modifying the `DISK_COUNT` value in `bios.i` and allocating additional Disk Parameter Headers in `main.s`.

The BIOS is configured to work with the CPM400.SR system from DISK9 of the CP/M 68K V1.3 distribution disks.  The BIOS `_init` entry point has been moved from the original 0x6000 to 0x6200.  This shifts the BIOS out of the CPM400.SR BSS segment.  CPM400.SR is patched to suit.

Once built, the target directory will contain `bios.srec`.

## CP/M file system images


