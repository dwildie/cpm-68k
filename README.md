# CP/M 68K for the S100 68000/68010 card

This project provides:
* Boot loader/monitor
* CP/M 68K BIOS
* CP/M file system images

This code assumes and has been tested with the following hardware:
* [68000/68010 Card](http://www.s100computers.com/My%20System%20Pages/68000%20Board/68K%20CPU%20Board.htm)
* [Propeller Console IO Card](http://www.s100computers.com/My%20System%20Pages/Console%20IO%20Board/Console%20IO%20Board.htm)
* [16MB Static RAM card](http://www.s100computers.com/My%20System%20Pages/16MG%20RAM%20Board/16MG%20RAM%20Board.htm)
* [IDE/CF Card](http://www.s100computers.com/My%20System%20Pages/IDE%20Board/My%20IDE%20Card.htm)

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
