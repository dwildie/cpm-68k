#!/bin/bash

usage() {
  echo "Usage: $0 <image_file> <target_disk> <disks> <source_dir> <samples_disk> <samples_dir>"
}

if [ $# -ne 6 ]; then
  usage
  exit 1
fi

IMAGE=$1
TARGET=$2
DISKS=$3
SRC=$4
SAMPLES_DISK=$5
SAMPLES_DIR=$6

FMT=4mb-hd

n=0
while [ $n -lt $DISKS ]
do
  DISK=$SRC/DISK$(( $n + 1))

  if [[ -d "$DISK" ]]; then
    echo "Copying $DISK to partition $TARGET"
    cpmcp -f ${FMT}-$TARGET $IMAGE $DISK/* 0:
  fi

  n=$(( $n + 1))
done

echo "Copying samples to partition $SAMPLES_DISK"
cpmcp -f ${FMT}-$SAMPLES_DISK $IMAGE $SAMPLES_DIR/* 0:


