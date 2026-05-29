# MobiScribe E60QR2 Root Notes

This repo documents the root process used on a first-generation MobiScribe / Netronix E60QR2 e-ink Android notepad.

The tested device runs Android 4.4.2 on a Freescale i.MX6SoloLite / `ntx_6sl` platform. The process uses temporary TWRP boot over fastboot, then installs SuperSU from recovery.

## Device

Observed properties:

```text
model: EVK_MX6SL
device: ntx_6sl
hardware: E60QR2
platform: imx6
Android: 4.4.2 / API 19
build: v5.35.4965
build type: user / release-keys
kernel: Linux 3.0.35-hg1d588555a7a0 #269 PREEMPT Wed Sep 29 10:59:20 CST 2021 armv7l
SELinux: Disabled
```

Normal ADB shell is not root:

```sh
adb shell id
# uid=2000(shell) ...
```

`adb root` does not work on this production build:

```text
adbd cannot run as root in production builds
```

## Important Fastboot Detail

On this device, use:

```sh
adb reboot fastboot
```

Do not use `adb reboot bootloader` if the goal is Android fastboot. On this unit, `adb reboot bootloader` entered a Freescale/vendor USB mode with mass storage and did not respond to normal `fastboot`.

Expected fastboot detection:

```sh
fastboot devices -l
# <serial> Android fastboot usb:...
```

The bootloader is minimal. These failed or were unsupported:

```sh
fastboot getvar all
fastboot getvar unlocked
fastboot oem device-info
```

Basic variables that worked:

```text
product: i.mx6sl NTX Smart Device
version: 0.5
```

## Files Used

Do not commit these binaries to this repo. Download and verify them locally:

- `twrp-ntx_6sl.img`: TWRP image from Ryogo-Z's `nook_ntx_6sl_twrp` release.
- `SuperSU-v2.82-201705271822.zip`: Chainfire SuperSU v2.82 stable ZIP. This ZIP contains the `Superuser.apk`, `su`, `daemonsu`, and related binaries installed by TWRP.

Known checksum for the SuperSU ZIP used:

```text
md5: 8755c94775431f20bd8de368a2c7a179
```

The TWRP image used locally was:

```text
sha256: 13ba8836f76dd6fc5c4991923a340a534f056c80c9a95f0df61d7b221620c246
```

## Credits and Sources

This procedure combines local testing on the device with third-party tools and public community notes. The binaries and background material are not original work from this repo.

| Item | What it was used for | Source / credit |
| --- | --- | --- |
| Netronix E60QR2 hardware information | Confirmed the device family: E60QR2, 6.8 inch EPD, Android, 1440x1080, i.MX6SoloLite-class hardware | Netronix product page: <https://www.netronixinc.com/products.aspx?ID=4> |
| `twrp-ntx_6sl.img` / TWRP for `ntx_6sl` | Temporarily booted recovery with `fastboot boot`; provided root recovery ADB | Ryogo-Z `nook_ntx_6sl_twrp` releases: <https://github.com/Ryogo-Z/nook_ntx_6sl_twrp/releases> |
| TWRP community notes | Helped identify that related `ntx_6sl` e-readers use `adb reboot fastboot`, and that fastboot/TWRP can work across related Netronix/Nook devices | MobileRead TWRP thread: <https://www.mobileread.com/forums/showthread.php?t=292026> |
| MobiScribe 1st gen compatibility note | Community report that this TWRP also works on MobiScribe 1st gen | XDA thread, `[GP, G3, GP7.8] TWRP & alternative firmware`: <https://xdaforums.com/t/gp-g3-gp7-8-twrp-alternative-firmware.4074347/> |
| SuperSU v2.82 ZIP | Installed persistent Android 4.4 root; this package supplied `Superuser.apk`, `su`, `daemonsu`, `supolicy`, and `install-recovery.sh` | Chainfire/XDA SuperSU v2.82 thread: <https://xdaforums.com/t/stable-2017-05-27-supersu-v2-82.3452703/> |
| SuperSU ZIP mirror used locally | The original Chainfire/S3 URL did not serve the ZIP during this run, so a mirror was used and verified by the known MD5 | Mirror URL used locally: <https://supersuroot.org/downloads/SuperSU-v2.82-201705271822.zip>; expected MD5: `8755c94775431f20bd8de368a2c7a179` |

Local observations in this document, such as the exact build fingerprint, partition mapping, fastboot behavior, TWRP UI freeze, and final `su -c id` result, came from commands run directly against the tested MobiScribe E60QR2.

## Temporary TWRP Boot

Boot TWRP temporarily without flashing recovery:

```sh
adb reboot fastboot
fastboot boot twrp-ntx_6sl.img
```

On this device, TWRP reached the "Swipe to allow modifications" screen, but the UI/touch became unreliable. Recovery ADB still worked and was root:

```sh
adb devices -l
# <serial> recovery usb:... product:Nook NTX model:Nook_eBook device:ntx_6sl

adb shell id
# uid=0(root) gid=0(root) ...
```

## Backup Before Modifying

Before installing root permanently, pull critical partitions from TWRP:

```sh
mkdir -p backups-mobiscribe

adb pull /dev/block/mmcblk0p1 backups-mobiscribe/mmcblk0p1.img
adb pull /dev/block/mmcblk0p2 backups-mobiscribe/mmcblk0p2.img
adb pull /dev/block/mmcblk0p5 backups-mobiscribe/system-p5.img
adb pull /dev/block/mmcblk0p8 backups-mobiscribe/device-p8.img
adb pull /tmp/recovery.log backups-mobiscribe/twrp-recovery.log

sha256sum backups-mobiscribe/*.img
```

Observed stock Android mount mapping:

```text
/dev/block/mmcblk0p5 -> /system
/dev/block/mmcblk0p6 -> /cache
/dev/block/mmcblk0p7 -> /data
/dev/block/mmcblk0p8 -> /device
```

Observed TWRP mapping differed for `/data` because this recovery is Nook-oriented:

```text
/dev/block/mmcblk0p4 -> /data and /sdcard (vfat)
/dev/block/mmcblk0p6 -> /cache
```

So use raw partition paths for backups.

## Install SuperSU

Push the SuperSU ZIP and run TWRP's command-line installer:

```sh
adb push SuperSU-v2.82-201705271822.zip /sdcard/SuperSU-v2.82.zip
adb shell twrp install /sdcard/SuperSU-v2.82.zip
```

The successful installer output included:

```text
SuperSU installer
- System mode
- Placing files
- Post-installation script
- Done !
```

After installing, verify the files from recovery:

```sh
adb shell mount /dev/block/mmcblk0p5 /system
adb shell ls -l /system/xbin/su /system/xbin/daemonsu /system/app/Superuser.apk /system/bin/install-recovery.sh
```

The install created:

```text
/system/xbin/su
/system/xbin/daemonsu
/system/xbin/supolicy
/system/app/Superuser.apk
/system/etc/install-recovery.sh
/system/bin/install-recovery.sh -> /system/etc/install-recovery.sh
```

Set setuid bits if needed:

```sh
adb shell chmod 6755 /system/xbin/su /system/xbin/daemonsu
adb shell sync
```

Then reboot:

```sh
adb reboot
```

## Verify Root

After booting Android:

```sh
adb shell id
# uid=2000(shell) ...

adb shell su -v
# 2.82:SUPERSU

adb shell su -c id
# uid=0(root) gid=0(root)

adb shell ps | grep daemonsu
# daemonsu:mount:master
# daemonsu:master
```

Root is persistent if `su -c id` still returns `uid=0(root)` after reboot.

## Notes

- TWRP UI may freeze or be difficult to use on this e-ink panel. Recovery ADB still works.
- Do not flash recovery until temporary boot is known to work and backups exist.
- Keep raw partition backups offline and out of GitHub.
- This is an old Android 4.4 device. Avoid exposing root services to untrusted networks.

## Next Steps

Apps tested on this build (Android 4.4.2, API 19, ARMv7):

- **KOReader** (`org.koreader.launcher`). EPUB/PDF/CBZ/MOBI reader. The official ARM build installs on KitKat:
  ```sh
  adb install koreader-android-arm-v2026.03.apk
  ```
  Releases: <https://github.com/koreader/koreader/releases>

- **eLauncher**, KitKat backport at <https://github.com/v4rgas/eLauncher/tree/kitkat-api19>. Upstream needs API 24, so this branch downgrades AGP/Gradle/AndroidX, guards the API 21+ calls (UsageStats, status bar color, the usage-access intent), swaps Java 8 stream/`forEach`/`ArrayList.sort` for KitKat-safe loops, and replaces `?attr/...` inside drawable XML with literal colors (drawable theme attrs only resolve from API 21).

  Build:
  ```sh
  ANDROID_HOME=/opt/android-sdk JAVA_HOME=/usr/lib/jvm/java-17-openjdk ./gradlew assembleRelease
  adb install app/build/outputs/apk/release/app-release.apk
  ```
  Needs SDK platform-19 and platform-28, build-tools 30.0.3, JDK 17.

What does NOT install (`INSTALL_FAILED_OLDER_SDK`):

- Olauncher, Niagara, LessPhone, Einkify, unmodified eLauncher (all need API 23+).
- KISS Launcher 3.25.x. Old builds with `minSdk <= 19` exist but were not tested here.

## Sources

- Netronix E60QR2 public product specs identify the hardware class: i.MX6SoloLite, Android, 1440x1080 e-ink.
- XDA and related `ntx_6sl` threads document that `adb reboot fastboot` and `nook_ntx_6sl_twrp` work on related Netronix/Nook devices; the same TWRP image also booted on this MobiScribe.
