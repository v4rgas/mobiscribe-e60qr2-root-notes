# What Did Not Work

These are the root paths investigated before the working temporary-TWRP plus
SuperSU path. They are kept here so future attempts do not burn time repeating
the same dead ends.

## Normal Android ADB root

`adb root` failed because this is a production/user build:

```text
adbd cannot run as root in production builds
```

The normal Android shell stayed unprivileged:

```sh
adb shell id
# uid=2000(shell) ...
```

Relevant device signals:

- `ro.secure=1`
- `ro.debuggable=0`
- `ro.adb.secure=1`
- build type is `user / release-keys`

## `adb reboot bootloader`

`adb reboot bootloader` was the wrong reboot target for Android fastboot on this
unit. It entered a Freescale/vendor USB mode with mass storage behavior and did
not respond to normal `fastboot`.

Use this instead:

```sh
adb reboot fastboot
```

## Minimal fastboot variables

Fastboot itself worked after `adb reboot fastboot`, but the bootloader exposed
very little information. These commands failed or were unsupported:

```sh
fastboot getvar all
fastboot getvar unlocked
fastboot oem device-info
```

Only basic variables such as `product` and `version` were useful. The successful
root process therefore did not depend on an unlock query or OEM unlock flow.

## Stock recovery / OTA route

The audit did not find useful update, recovery, firmware, key, certificate, ZIP,
or image hits in `/system`, `/device`, or `/cache`.

See:

- `ntx_audit/update_recovery_hits.txt`
- `ntx_audit/report.md`

This made a vendor OTA or stock recovery package route a poor target compared
with temporarily booting a known-compatible `ntx_6sl` TWRP image.

## Userspace setuid/setgid route

No useful setuid or setgid binaries were found or readable during the audit.

See:

- `ntx_audit/setuid.txt`
- `ntx_audit/setgid.txt`

That made a privileged userspace binary bug unlikely as the fastest path.

## Kernel local privilege escalation attempts

Several old Android/kernel LPE ideas were explored because the device runs
Android 4.4.2 on Linux 3.0.35. They were not the path that produced root on this
unit.

Artifacts left from this exploration include:

- Futex/Towelroot-style CVE-2014-3153 work: `futex_requeue.c`,
  `futex_main.c`, `CVE-2014-3153.so`, `CVE-2014-3153-marker.so`,
  `futexloader.dex`, and `futexloader.jar`.
- Android get_user/put_user CVE-2013-6282 work: `CVE-2013-6282.so`,
  `CVE-2013-6282-marker.so`, `cve6282loader.dex`, `cve6282loader.jar`,
  `put_user_vroot.rb`, and `libget_user_README.md`.
- Dirty COW-style file overwrite work: `cowwrite.c`, `cowwrite`, and
  `run-as.backup`.
- CVE-2015-3636 research/build artifacts: `cve-2015-3636-exp.c`,
  `cve-2015-3636-poc.c`, `cve2015dir.json`, and `cve2015jni.json`.

The practical blockers were:

- `kptr_restrict=2`, which made older kernel-address-dependent exploits harder
  to adapt from an unprivileged Android shell.
- The 2021 kernel build was old by version number but likely had vendor
  backports for common public LPEs.
- The available exploits needed device-specific offsets, symbols, or reliability
  work, while temporary TWRP gave root recovery ADB without modifying stock
  recovery first.

Conclusion: kernel LPEs were not worth continuing once `fastboot boot
twrp-ntx_6sl.img` was confirmed to work.

## Launcher/app dead ends

For post-root usability, several modern Android launchers did not install on
this Android 4.4.2/API 19 build:

```text
INSTALL_FAILED_OLDER_SDK
```

Known failures:

- Olauncher
- Niagara
- LessPhone
- Einkify
- unmodified eLauncher
- KISS Launcher 3.25.x

Old KISS builds with `minSdk <= 19` may exist, but they were not validated in
this run. The tested path was Postscribe, the KitKat/API 19 eLauncher fork:
<https://github.com/v4rgas/Postscribe/tree/kitkat-api19>.
