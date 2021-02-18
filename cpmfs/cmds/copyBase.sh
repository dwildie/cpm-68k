#!/bin/bash

usage() {
  echo "Usage: $0 <image_file> <target_disk> <disks> <source_dir>"
}

if [ $# -ne 4 ]; then
  usage
  exit 1
fi

IMAGE=$1
TARGET=$2
DISKS=$3
SRC=$4

TMPDIR=$(mktemp -d -t cpm-XXXXXXXXXX)

FMT=4mb-hd

# Copy CP/M files to tmp directory
n=0
while [ $n -lt $DISKS ]
do
  DISK=$SRC/DISK$(( $n + 1))

  if [[ -d "$DISK" ]]; then
    echo "Copying CP/M $DISK to temporary directory $TMPDIR"
	cp $DISK/* $TMPDIR
  fi

  n=$(( $n + 1))
done

echo "Temp dir $TMPDIR"
rm $TMPDIR/RELOC*.SUB $TMPDIR/LOADBIOS.SUB $TMPDIR/NORMBIOS.SUB $TMPDIR/LCPM10.SUB $TMPDIR/LCPM.SUB $TMPDIR/CPMLDR.SYS \
   $TMPDIR/MAKELDR.SUB $TMPDIR/XNORMBIO.SUB $TMPDIR/XMAKELDR.SUB $TMPDIR/XLCPM.SUB $TMPDIR/XLOADBIO.SUB $TMPDIR/RELCPM.SUB \
   $TMPDIR/*.S $TMPDIR/*.C $TMPDIR/*BIOS*.O $TMPDIR/*BOOT*.O $TMPDIR/LOADR.O $TMPDIR/OVHDLR.O $TMPDIR/XCPM*.* $TMPDIR/XPUTBOOT.REL $TMPDIR/PUTBOOT.REL \
   $TMPDIR/CPM15000.* $TMPDIR/CPM400.*

echo "Copying CP/M files to partition $TARGET"
cpmcp -t -f ${FMT}-$TARGET $IMAGE $TMPDIR/* 0:
