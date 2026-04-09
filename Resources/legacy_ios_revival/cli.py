from __future__ import annotations

import argparse
import sys

from legacy_ios_revival.imessage import (
    apply_imessage_patch,
    backup_imessage_settings,
    check_dependencies,
    detect_connected_device,
    display_device_info,
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
    repair_parser = subparsers.add_parser("repair", help="Run the legacy iMessage repair workflow.")
    repair_parser.add_argument(
        "--no-backup",
        action="store_true",
        help="Skip backing up iMessage settings during repair.",
    )

    args = parser.parse_args()

    if args.command == "check":
        check_dependencies()
        try:
            display_device_info()
        except RuntimeError as e:
            print(f"Error: {e}")
            return 1
        return 0

    if args.command == "backup":
        try:
            display_device_info(skip_if_unavailable=True)
            print()  # Add blank line for readability
            backup_imessage_settings(args.ssh_target)
        except RuntimeError as e:
            print(f"Error: {e}")
            return 1
        return 0

    if args.command == "repair":
        try:
            display_device_info(skip_if_unavailable=True)
            print()  # Add blank line for readability
            apply_imessage_patch(args.ssh_target, args.patch_package, skip_backup=args.no_backup)
        except RuntimeError as e:
            print(f"Error: {e}")
            return 1
        return 0

    parser.print_help()
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
