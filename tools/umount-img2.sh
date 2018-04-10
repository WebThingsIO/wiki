#!/bin/bash
#
# Script which loop mounts an image

SCRIPT_NAME=$(basename $0)

VERBOSE=0
ROOT_MOUNTED=0
LEAVE_MOUNTED=0

###########################################################################
#
# Prints the program usage
#
usage() {
  echo "Usage: ${SCRIPT_NAME} [-v] IMAGE_FILE"
}

###########################################################################
#
# Parses command line arguments and run the program.
#
main () {
  while getopts "v" opt "$@"; do
    case $opt in
      v)
        VERBOSE=1
        ;;
      ?)
        echo "Unrecognized option: ${opt}"
        usage
        exit 1
        ;;
      esac
  done
  shift $((${OPTIND} - 1))
  IMAGE_FILE=$1
  if [ -z "${IMAGE_FILE}" ]; then
    echo "No image file provided."
    usage
    exit 1
  fi

  if [ "${VERBOSE}" == "1" ]; then
    echo "Image File: ${IMAGE_FILE}"
  fi

  if [ ! -f "${IMAGE_FILE}" ]; then
    echo "Image File: '${IMAGE_FILE}' not a file."
    exit 1
  fi
  
  ROOT_MOUNTPOINT=rpi-root
  BOOT_MOUNTPOINT=rpi-boot

  # Unmount the boot parition of the image
  if sudo umount ${BOOT_MOUNTPOINT}; then
    echo "Boot partition unmounted successfully"
  else
    echo "Failed to unmount boot partition"
    exit 1
  fi

  # Unmount the root parition of the image
  if sudo umount ${ROOT_MOUNTPOINT}; then
    echo "Root partition unmounted successfully"
  else
    echo "Failed to unmount root partition"
    exit 1
  fi

  # Remove the loop mounts
  if sudo kpartx -v -d "${IMAGE_FILE}"; then
    echo "Loop mounts removed successfully"
  else
    echo "Failed to remove loop mounts"
    exit 1
  fi

  rmdir ${BOOT_MOUNTPOINT}
  rmdir ${ROOT_MOUNTPOINT}
}

main "$@"