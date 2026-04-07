from __future__ import annotations

import argparse
import sys

from legacy_ios_revival.imessage import (
    apply_imessage_patch,
    backup_imessage_settings,
    check_dependencies,
    detect_connected_device,
    get_device_info,
)


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="fix-imessage",
        description="Legacy iMessage repair helper for iOS 5.1.1 devices on Linux.",
    )

    parser.add_argument(
        "--ssh-target",
        help="SSH target for a jailbroken device, e.g. root@192.168.1.10.",
    )
    parser.add_argument(
        "--patch-package",
        help="Path to a legacy iMessage patch package to install on the device.",
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("check", help="Check platform, toolchain, and device connectivity.")
    subparsers.add_parser("backup", help="Backup iMessage settings from a connected device.")
    subparsers.add_parser("repair", help="Run the legacy iMessage repair workflow.")

    args = parser.parse_args()

    if args.command == "check":
        check_dependencies()
        device_id = detect_connected_device()
        if not device_id:
            print("No device found. Connect your iPhone and try again.")
            return 1
        info = get_device_info(device_id)
        print("Connected device:")
        for key in ["UniqueDeviceID", "ProductType", "ProductVersion", "DeviceName"]:
            value = info.get(key, "unknown")
            print(f"  {key}: {value}")
        return 0

    if args.command == "backup":
        backup_imessage_settings(args.ssh_target)
        return 0

    if args.command == "repair":
        apply_imessage_patch(args.ssh_target, args.patch_package)
        return 0

    parser.print_help()
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
