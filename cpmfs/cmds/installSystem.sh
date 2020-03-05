#!/bin/bash

usage() {
  echo "Usage: $0 <image_file> <boot_file>"
}

if [ $# -ne 2 ]; then
  usage
  exit 1
fi

IMAGE=$1
BOOT=$2

FMT=4mb-hd

cpmrm -f ${FMT}-0 $IMAGE 0:$(basename $BOOT)

echo "Copying $(basename $BOOT) to $IMAGE, partition 0"
cpmcp -f ${FMT}-0 $IMAGE $BOOT 0:
