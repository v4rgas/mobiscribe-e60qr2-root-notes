#!/usr/bin/env sh
set -eu

if [ "$#" -ne 1 ]; then
  echo "usage: $0 /path/to/twrp-ntx_6sl.img" >&2
  exit 2
fi

adb reboot fastboot
fastboot devices -l
fastboot boot "$1"
adb wait-for-device
adb shell id
