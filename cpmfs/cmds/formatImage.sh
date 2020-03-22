#!/bin/bash

usage() {
  echo "Usage: $0 <image_file> <disk-def>"
}

if [ $# -ne 2 ]; then
  usage
  exit 1
fi

IMAGE=$1
DEF=$2

LABEL=/tmp/label.txt

# Diskdef
SECSIZE=128
SECTRK=32
TRACKS=1024

DISK_SIZE=$(( $SECSIZE * SECTRK * TRACKS ))
echo "Disk size: $DISK_SIZE bytes"
echo ""

echo "Formatting $DEF image -> $IMAGE"
dd if=/dev/zero bs=$DISK_SIZE count=1 | tr '\0' '\345' > $IMAGE

echo "Definition: ${DEF}" > $LABEL
echo "Created:    $(date)" >> $LABEL
unix2dos $LABEL
echo -e -n '\x1a' >> $LABEL
  
cpmcp -f ${DEF} $IMAGE $LABEL 0:

