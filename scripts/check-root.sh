#!/usr/bin/env sh
set -eu

adb devices -l
adb shell id
adb shell su -v
adb shell su -c id
adb shell ps | grep daemonsu || true
