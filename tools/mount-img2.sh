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
  
  # Figure out the device names that kpartx will create
  declare -a KPARTX_DEVS
  KPARTX_DEVS=($(while read dev rest; do
    echo "/dev/mapper/${dev}"
  done < <(sudo kpartx -v -l "${IMAGE_FILE}")))

  BOOT_DEV=${KPARTX_DEVS[0]}
  ROOT_DEV=${KPARTX_DEVS[1]}

  ROOT_MOUNTPOINT=rpi-root
  BOOT_MOUNTPOINT=rpi-boot
  MOZILLA_IOT_DIR=${ROOT_MOUNTPOINT}/home/pi/mozilla-iot

  if [ "${VERBOSE}" == "1" ]; then
    echo "  BOOT_DEV: ${BOOT_DEV}"
    echo "  ROOT_DEV: ${ROOT_DEV}"
  fi

  # Create the loop mounts
  if sudo kpartx -v -a "${IMAGE_FILE}"; then
    # It seems that there is sometimes a race and that the loop files don't
    # always exist by the time kpartx exits, so we wait until we actually
    # see the loop file before continuing.
    iter=0
    while [ ! -e ${ROOT_DEV} ]; do
      echo "Waiting for loop mount to be created"
      sleep 1
      iter=$(( ${iter} + 1 ))
      if [ ${iter} -gt 5 ]; then
        echo "Timeout waiting for loop mount"
        exit 1
      fi
    done
    echo "Loop mounts created successfully"
  else
    echo "Failed to create loop mounts"
    exit 1
  fi
  LOOP_MOUNT_CREATED=1

  # Mount the root parition of the image
  mkdir -p ${ROOT_MOUNTPOINT}
  if sudo mount ${ROOT_DEV} ${ROOT_MOUNTPOINT}; then
    echo "Root partition mounted successfully"
  else
    echo "Failed to mount root partition"
    exit 1
  fi
  ROOT_MOUNTED=1

  # Mount the boot parition of the image
  mkdir -p ${BOOT_MOUNTPOINT}
  if sudo mount ${BOOT_DEV} ${BOOT_MOUNTPOINT}; then
    echo "Boot partition mounted successfully"
  else
    echo "Failed to mount boot partition"
    exit 1
  fi
  BOOT_MOUNTED=1

  LEAVE_MOUNTED=1
}

###########################################################################
#
# Do required cleanup. We use a trap so that if the script dies for any
# reason then we'll still undo whatever is needed.
#
function cleanup() {
  if [ "${LEAVE_MOUNTED}" == 1 ]; then
    return
  fi
  if [ "${BOOT_MOUNTED}" == 1 ]; then
    echo "Unmounting ${BOOT_DEV}"
    sudo umount ${BOOT_MOUNTPOINT}
    BOOT_MOUNTED=0
  fi
  if [ -d ${BOOT_MOUNTPOINT} ]; then
    sudo rmdir ${BOOT_MOUNTPOINT}
  fi
  if [ "${ROOT_MOUNTED}" == 1 ]; then
    echo "Unmounting ${ROOT_DEV}"
    sudo umount ${ROOT_MOUNTPOINT}
    ROOT_MOUNTED=0
  fi
  if [ -d ${ROOT_MOUNTPOINT} ]; then
    sudo rmdir ${ROOT_MOUNTPOINT}
  fi
  if [ "${LOOP_MOUNT_CREATED}" == 1 ]; then
    echo "Removing loop mounts"
    sudo kpartx -v -d "${IMAGE_FILE}"
    LOOP_MOUNT_CREATED=0
  fi
}

trap cleanup EXIT

main "$@"