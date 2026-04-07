from __future__ import annotations

import os
import shlex
import shutil
import subprocess
import sys
from pathlib import Path


def run_command(command: str, capture_output: bool = True) -> str:
    result = subprocess.run(
        shlex.split(command),
        capture_output=capture_output,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"Command failed: {command}\nExit code: {result.returncode}\n{result.stderr.strip()}"
        )
    return result.stdout.strip()


def check_dependencies() -> None:
    print("Checking Linux platform and required tools...")
    if sys.platform != "linux":
        raise RuntimeError("This tool is supported only on Linux.")

    required = ["idevice_id", "ideviceinfo"]
    missing = [tool for tool in required if shutil.which(tool) is None]
    if missing:
        raise RuntimeError(
            "Missing required tools: " + ", ".join(missing) + ".\n"
            "Install libimobiledevice and try again."
        )

    print("  OK: libimobiledevice tools detected.")
    if shutil.which("ssh"):
        print("  OK: ssh available for jailbroken device access.")
    else:
        print("  Warning: ssh is not installed. Jailbroken repair operations require ssh.")


def detect_connected_device() -> str | None:
    output = run_command("idevice_id -l")
    device_ids = [line.strip() for line in output.splitlines() if line.strip()]
    if not device_ids:
        return None
    return device_ids[0]


def get_device_info(device_id: str) -> dict[str, str]:
    output = run_command(f"ideviceinfo -u {device_id}")
    info: dict[str, str] = {}
    for line in output.splitlines():
        if ": " in line:
            key, value = line.split(": ", 1)
            info[key.strip()] = value.strip()
    return info


def backup_imessage_settings(ssh_target: str | None = None) -> None:
    print("Backing up iMessage settings...")
    if ssh_target is None:
        raise RuntimeError(
            "Backup requires a jailbroken device reachable over SSH. "
            "Use --ssh-target root@<device-ip>."
        )

    backup_dir = Path.cwd() / "legacy-imessage-backup"
    backup_dir.mkdir(parents=True, exist_ok=True)
    remote_path = "/private/var/mobile/Library/Preferences/com.apple.iChat.plist"
    local_path = backup_dir / "com.apple.iChat.plist"

    print(f"  Copying {remote_path} from {ssh_target} to {local_path}...")
    run_command(f"scp -o StrictHostKeyChecking=no {ssh_target}:{remote_path} {shlex.quote(str(local_path))}")
    print(f"Backup complete: {local_path}")
    print(
        "If this file does not exist, the device may not be jailbroken or iMessage is not configured yet."
    )


def apply_imessage_patch(ssh_target: str | None = None, patch_package: str | None = None) -> None:
    print("Starting legacy iMessage repair workflow...")
    if ssh_target is None:
        raise RuntimeError(
            "Repair requires a jailbroken device reachable over SSH. "
            "Use --ssh-target root@<device-ip>."
        )

    if patch_package is not None:
        patch_file = Path(patch_package).expanduser().resolve()
        if not patch_file.exists():
            raise RuntimeError(f"Patch package not found: {patch_file}")

        print(f"Installing patch package {patch_file.name} to device...")
        run_command(f"scp -o StrictHostKeyChecking=no {shlex.quote(str(patch_file))} {ssh_target}:/tmp/{patch_file.name}")
        run_command(f"ssh -o StrictHostKeyChecking=no {ssh_target} 'dpkg -i /tmp/{patch_file.name} || true'"
                    )
        print("Patch copy completed. Verify installation on the device.")

    print("Applying required runtime repairs...")
    print("  1) Backing up iMessage preference file.")
    backup_imessage_settings(ssh_target)

    print("  2) Resetting iMessage cache and preferences.")
    commands = [
        "rm -f /private/var/mobile/Library/Preferences/com.apple.iChat.plist",
        "rm -rf /private/var/mobile/Library/Preferences/com.apple.iChat.*",
        "rm -rf /private/var/mobile/Library/Logs/iMessage",
    ]
    for cmd in commands:
        run_command(f"ssh -o StrictHostKeyChecking=no {ssh_target} '{cmd}'")

    print(
        "Repair workflow completed. On the device, restart and open Settings -> Messages. "
        "Sign back into your Apple ID and verify iMessage activation."
    )
    print(
        "NOTE: iOS 5.1.1 is legacy hardware. If messages still fail, you may need a community patch package "
        "or a newer compatibility server."
    )
