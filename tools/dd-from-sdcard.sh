#!/bin/bash

SCRIPT_NAME="$0"

usage() {
  echo "Usage: ${SCRIPT_NAME} dd-device img-filename"
}

DD_DEV="$1"
if [ -z "${DD_DEV}" ]; then
  echo "Must provide the device node for the sdcard"
  usage
  exit 1
fi

IMG_FILENAME="$2"
if [ -z "${IMG_FILENAME}" ]; then
  echo "Must provide the imsage name for the sdcard"
  usage
  exit 1
fi

# Unmount anything on the source device
mount | grep "${DD_DEV}" | while read dev rest; do
  echo "Unmounting '${dev}'"
  sudo umount "${dev}"
done
echo "Reading image from '${DD_DEV}' to '${IMG_FILENAME}'"
sudo dd status=progress bs=10M if="${DD_DEV}" of="${IMG_FILENAME}"
