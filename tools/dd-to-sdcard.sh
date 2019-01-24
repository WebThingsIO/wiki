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
DD_NAME=$(basename ${DD_DEV})
if [[ "${DD_DEV:0:1}" != '/' ]]; then
  DD_DEV="/dev/${DD_DEV}"
fi
REMOVABLE=$(cat /sys/block/${DD_NAME}/removable)
if [ "${REMOVABLE}" != "1" ]; then
  echo "${DD_DEV} isn't a removable drive"
  exit 1
fi
MEDIA_SIZE=$(cat /sys/block/${DD_NAME}/size)
if [ "${MEDIA_SIZE}" == "0" ]; then
  echo "No media present at ${DD_DEV}"
  exit 1
fi
if [ $(( ${MEDIA_SIZE} / 2048 / 1024 )) -gt 100 ]; then
  echo "${DD_DEV} media size is larger than 100 Gb - wrong device?"
  exit 1
fi

IMG_FILENAME="$2"
if [ -z "${IMG_FILENAME}" ]; then
  echo "Must provide the image name for the sdcard"
  usage
  exit 1
fi

# Unmount anything on the source device
mount | grep "${DD_DEV}" | while read dev rest; do
  echo "Unmounting '${dev}'"
  sudo umount "${dev}"
done

if [[ "${IMG_FILENAME}" == *.zip ]]; then
  echo "Unzipping image from '${IMG_FILENAME}' to '${DD_DEV}'"
  unzip -p ${IMG_FILENAME} | sudo dd status=progress bs=10M of="${DD_DEV}"
else
  echo "Writing image to '${DD_DEV}' from '${IMG_FILENAME}'"
  sudo dd status=progress bs=10M of="${DD_DEV}" if="${IMG_FILENAME}"
fi
