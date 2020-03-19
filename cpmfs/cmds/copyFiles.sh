#!/bin/bash

usage() {
  echo "Usage: $0 <image_file> <partition> <file1> ..."
}

if [ $# -lt 3 ]; then
  usage
  exit 1
fi

IMAGE=$1
PARTITION=$2

FMT=4mb-hd

args=("$@")

n=2
while [ $n -lt $# ]
do
  echo "Copying ${args[$n]} to $IMAGE, partition $PARTITION"
  cpmcp -f ${FMT}-${PARTITION} $IMAGE ${args[$n]} 0:
  
  n=$(( $n + 1))
done

#cpmrm -f ${FMT}-0 $IMAGE 0:$(basename $BOOT)

#echo "Copying $(basename $BOOT) to $IMAGE, partition 0"
#cpmcp -f ${FMT}-0 $IMAGE $BOOT 0:
