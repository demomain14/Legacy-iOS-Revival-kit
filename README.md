# Legacy-iOS-Revival-kit made by PanicDEV for a school project
An application that revives legacy services on iOS 5.1.1 to iOS 9.3.6 (can also optionally just be used as a jailbreak service)
# V SUPPORTED PLATFORMS V
MX Linux - MX (XFCE) is a perfect distro for this, as it can be booted as a live USB with internet.

AntiX - if you have an AntiX live usb you could use this as well.

Debian stable (Trixie) - i dont beleve debian has a live usb service but if it does go nuts ig.

Gentoo Linux - i recomend using the gui 
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
fix-imessage repair --ssh-target root@192.168.1.10 [--patch-package ./imessage-fix.deb] [--no-backup]
fix-imessage test --ssh-target root@192.168.1.10
```

### What it does
- `check`: Verifies device connectivity and iOS version
- `backup`: Backs up legacy iMessage preference files to a local directory
- `repair`: Resets cached iMessage settings on a jailbroken device, with optional `--no-backup` flag to skip backup step
- `test`: Tests the iMessage fix by emulating a broken state and verifying that the repair workflow successfully fixes it

> Note: iOS 5.1.1 is a legacy device. This helper is intended to support repair workflows on jailbroken hardware; a complete iMessage restore may also require community patch packages or compatibility tweaks.
