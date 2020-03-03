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

FMT=4mb-hd

n=0
while [ $n -lt $DISKS ]
do
  DISK=$SRC/DISK$(( $n + 1))

  if [[ -d "$DISK" ]]; then
    echo "Copying $DISK to partition $n"
    cpmcp -f ${FMT}-$TARGET $IMAGE $DISK/* 0:
  fi

  n=$(( $n + 1))
done


