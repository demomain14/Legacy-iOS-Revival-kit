# Legacy-iOS-Revival-kit made by PanicDEV for a school project
An application that revives old services on iOS 3.1.3 to iOS 9.3.6 (can also optionally just be used as a jailbreak service)
# V SUPPORTED PLATFORMS V
MX Linux - MX (XFCE) is a perfect distro for this, as it can be booted as a live USB with internet.

AntiX - if you have an AntiX live usb you could use this as well.

Debian stable (Trixie) - i dont beleve debian has a live usb service but if it does go nuts ig.

Gentoo Linux 
# V FUTURE SUPPORTED PLATFORMS V
Mac OS

Steam OS (For the poor souls who only have a steam deck)
# V FEATURES v
Forces older apps to connect with newer API's and apps

Utalizes Jailbreaking services to jailbreak your device optionaly 

## I AM ***NOT*** RESPONSIBLE FOR WHATEVER HAPPENS TO YOUR DEVICE

---

## Linux iMessage Repair Helper
This repository now includes a Linux CLI helper for legacy iMessage support on jailbroken iOS 5.1.1 devices.

### Requirements
- Linux (Ubuntu, MX Linux, Debian, Gentoo, etc.)
- Python 3.11+
- `libimobiledevice` tools installed (`idevice_id`, `ideviceinfo`)
- SSH access to the jailbroken device (for repair operations)

### Install
```bash
python3 -m pip install .
```

### Usage
```bash
fix-imessage check
fix-imessage backup --ssh-target root@192.168.1.10
fix-imessage repair --ssh-target root@192.168.1.10 [--patch-package ./imessage-fix.deb]
```

### What it does
- checks device connectivity and iOS version
- backs up legacy iMessage preference files
- resets cached iMessage settings on a jailbroken device
- optionally installs a local patch package if you have one

> Note: iOS 5.1.1 is a legacy device. This helper is intended to support repair workflows on jailbroken hardware; a complete iMessage restore may also require community patch packages or compatibility tweaks.
