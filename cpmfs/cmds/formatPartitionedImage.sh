#!/bin/bash

usage() {
  echo "Usage: $0 <image_file> <partions>"
}

if [ $# -ne 2 ]; then
  usage
  exit 1
fi

IMAGE=$1
PARTITIONS=$2

LABEL=/tmp/label.txt

# Diskdef
SECSIZE=128
SECTRK=32
TRACKS=1024

FMT=4mb-hd

PARTITION_SIZE=$(( $SECSIZE * SECTRK * TRACKS ))
echo "Partition size: $PARTITION_SIZE bytes"

DISK_SIZE=$(( $PARTITION_SIZE * $PARTITIONS ))
echo "Disk size:      $DISK_SIZE bytes"
echo ""

echo "Formatting a $PARTITIONS partition image -> $IMAGE"
dd if=/dev/zero bs=$DISK_SIZE count=1 | tr '\0' '\345' > $IMAGE

n=0
while [ $n -lt $PARTITIONS ]
do
  echo "Partition: $n" > $LABEL
  echo "Created:   $(date)" >> $LABEL
  unix2dos $LABEL
  echo -e -n '\x1a' >> $LABEL
  
  cpmcp -f ${FMT}-$n $IMAGE $LABEL 0:

  n=$(( $n + 1))
done
