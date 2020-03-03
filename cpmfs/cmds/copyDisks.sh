#!/bin/bash

usage() {
  echo "Usage: $0 <image_file> <partitions> <source_dir>"
}

if [ $# -ne 3 ]; then
  usage
  exit 1
fi

IMAGE=$1
PARTITIONS=$2
SRC=$3

FMT=4mb-hd

n=0
while [ $n -lt $PARTITIONS ]
do
  DISK=$SRC/DISK$(( $n + 1))

  if [[ -d "$DISK" ]]; then
    echo "Copying $DISK to partition $n"
    cpmcp -f ${FMT}-$n $IMAGE  $DISK/* 0:
  fi

  n=$(( $n + 1))
done


