# CP/M 68K for the S100 68000/68010 card

This project provides:
* Boot loader/monitor
* CP/M 68K BIOS
* CP/M file system images

Requires make, gnu 68000 cross tools, cpmtools to be installed.

Alternatively, use the following docker image which provides all the necessary tools:

  `docker run -it --rm --name 68k-tools -v {my project directory}:/opt/work dwildie/68k-tools:0.0.1 bash`

To build:  In the top level directory, type `make`

## Boot loader/monitor
The Boot loader/monitor is build for the standard memory configuration:
+ ROM at 0xFD0000
+ RAM at 0xFD8000
For a different memory configuration modify the MEMORY section in the `boot.rom.lnk` file.

Once built, the target directory will contain `boot.srec` which should be burnt to the EPROMS.

## CP/M 68K BIOS

## CP/M file system images
