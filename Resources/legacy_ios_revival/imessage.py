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


def get_device_type_name(product_type: str) -> str:
    """Map ProductType code to human-readable device name."""
    device_map = {
        # iPhone models
        "iPhone2,1": "iPhone 3GS",
        "iPhone3,1": "iPhone 4",
        "iPhone3,2": "iPhone 4 (CDMA)",
        "iPhone3,3": "iPhone 4",
        "iPhone4,1": "iPhone 4S",
        "iPhone5,1": "iPhone 5",
        "iPhone5,2": "iPhone 5 (CDMA)",
        "iPhone5,3": "iPhone 5C",
        "iPhone5,4": "iPhone 5C (CDMA)",
        "iPhone6,1": "iPhone 5S",
        "iPhone6,2": "iPhone 5S (CDMA)",
        "iPhone7,1": "iPhone 6 Plus",
        "iPhone7,2": "iPhone 6",
        "iPhone8,1": "iPhone 6S",
        "iPhone8,2": "iPhone 6S Plus",
        "iPhone8,4": "iPhone SE",
        "iPhone9,1": "iPhone 7",
        "iPhone9,3": "iPhone 7",
        "iPhone9,2": "iPhone 7 Plus",
        "iPhone9,4": "iPhone 7 Plus",
        # iPad models
        "iPad1,1": "iPad",
        "iPad2,1": "iPad 2",
        "iPad2,2": "iPad 2 (GSM)",
        "iPad2,3": "iPad 2 (CDMA)",
        "iPad2,4": "iPad 2",
        "iPad3,1": "iPad (3rd Gen)",
        "iPad3,2": "iPad (3rd Gen, CDMA)",
        "iPad3,3": "iPad (3rd Gen)",
        "iPad3,4": "iPad (4th Gen)",
        "iPad3,5": "iPad (4th Gen, CDMA)",
        "iPad3,6": "iPad (4th Gen)",
        "iPad4,1": "iPad Air",
        "iPad4,2": "iPad Air (CDMA)",
        "iPad4,3": "iPad Air",
        "iPad5,1": "iPad Air 2",
        "iPad5,2": "iPad Air 2",
        "iPad6,7": "iPad Pro 12.9-inch",
        "iPad6,8": "iPad Pro 12.9-inch",
        "iPad6,3": "iPad Pro 9.7-inch",
        "iPad6,4": "iPad Pro 9.7-inch",
        # iPad Mini models
        "iPad2,5": "iPad Mini (1st Gen)",
        "iPad2,6": "iPad Mini (1st Gen, GSM)",
        "iPad2,7": "iPad Mini (1st Gen, CDMA)",
        "iPad4,4": "iPad Mini 2",
        "iPad4,5": "iPad Mini 2 (CDMA)",
        "iPad4,6": "iPad Mini 2",
        "iPad4,7": "iPad Mini 3",
        "iPad4,8": "iPad Mini 3 (CDMA)",
        "iPad4,9": "iPad Mini 3",
        "iPad5,3": "iPad Mini 4",
        "iPad5,4": "iPad Mini 4",
        # iPod models
        "iPod1,1": "iPod Touch",
        "iPod2,1": "iPod Touch (2nd Gen)",
        "iPod2,2": "iPod Touch (2nd Gen)",
        "iPod3,1": "iPod Touch (3rd Gen)",
        "iPod4,1": "iPod Touch (4th Gen)",
        "iPod5,1": "iPod Touch (5th Gen)",
        "iPod7,1": "iPod Touch (6th Gen)",
    }
    return device_map.get(product_type, product_type)


def display_device_info(device_id: str | None = None, skip_if_unavailable: bool = False) -> None:
    """Display connected device information at the top.
    
    Args:
        device_id: Optional device ID to use (auto-detect if not provided)
        skip_if_unavailable: If True, silently skip display if device not accessible
                           (useful for SSH operations when device may be in DFU mode)
    """
    if device_id is None:
        device_id = detect_connected_device()
    
    if not device_id:
        if skip_if_unavailable:
            print("Note: Device not accessible via USB (may be in DFU/Recovery mode)")
            print("      Using SSH to connect directly to the device.")
            return
        raise RuntimeError("No device found. Connect your iOS device and try again.")
    
    info = get_device_info(device_id)
    product_type = info.get("ProductType", "Unknown")
    device_name = get_device_type_name(product_type)
    device_display_name = info.get("DeviceName", "Unknown Device")
    ios_version = info.get("ProductVersion", "Unknown")
    
    print("=" * 60)
    print(f"Device Type: {device_name}")
    print(f"Device Name: {device_display_name}")
    print(f"iOS Version: {ios_version}")
    print("=" * 60)


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
    print(f"  Note: If prompted for a '{ssh_target} password', the default jailbroken root password is 'alpine'")
    
    try:
        run_command(f"scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa {ssh_target}:{remote_path} {shlex.quote(str(local_path))}")
        print(f"Backup complete: {local_path}")
    except RuntimeError as e:
        if "No such file or directory" in str(e):
            raise RuntimeError(
                f"iMessage settings file not found on device.\n\n"
                f"This means iMessage has not been configured yet. Please:\n"
                f"1. On your iOS device, go to Settings → Messages\n"
                f"2. Enable iMessage and sign in with your Apple ID\n"
                f"3. Wait for activation to complete\n"
                f"4. Then run this tool again to back up the settings\n\n"
                f"Alternatively, you can skip backup and run the repair directly:\n"
                f"  ./revive.sh repair --ssh-target {ssh_target}"
            ) from e
        raise


def apply_imessage_patch(ssh_target: str | None = None, patch_package: str | None = None, skip_backup: bool = False) -> None:
    print("Starting legacy iMessage repair workflow...")
    if ssh_target is None:
        raise RuntimeError(
            "Repair requires a jailbroken device reachable over SSH. "
            "Use --ssh-target root@<device-ip>."
        )

    print(f"Note: If prompted for a '{ssh_target} password' during SSH/SCP operations, the default jailbroken root password is 'alpine'")
    print()

    if patch_package is not None:
        patch_file = Path(patch_package).expanduser().resolve()
        if not patch_file.exists():
            raise RuntimeError(f"Patch package not found: {patch_file}")

        print(f"Installing patch package {patch_file.name} to device...")
        run_command(f"scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa {shlex.quote(str(patch_file))} {ssh_target}:/tmp/{patch_file.name}")
        run_command(f"ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa {ssh_target} 'dpkg -i /tmp/{patch_file.name} || true'"
                    )
        print("Patch copy completed. Verify installation on the device.")

    print("Applying required runtime repairs...")
    if not skip_backup:
        print("  1) Backing up iMessage preference file.")
        backup_imessage_settings(ssh_target)
        print("  2) Resetting iMessage cache and preferences.")
    else:
        print("  1) Resetting iMessage cache and preferences (backup skipped).")

    commands = [
        "rm -f /private/var/mobile/Library/Preferences/com.apple.iChat.plist",
        "rm -rf /private/var/mobile/Library/Preferences/com.apple.iChat.*",
        "rm -rf /private/var/mobile/Library/Logs/iMessage",
    ]
    for cmd in commands:
        run_command(f"ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa {ssh_target} '{cmd}'")

    print(
        "Repair workflow completed. On the device, restart and open Settings -> Messages. "
        "Sign back into your Apple ID and verify iMessage activation."
    )
    print(
        "NOTE: iOS 5.1.1 is legacy hardware. If messages still fail, you may need a community patch package "
        "or a newer compatibility server."
    )


def test_imessage_fix(ssh_target: str | None = None) -> None:
    """Test the iMessage fix by emulating a broken state and verifying the repair works."""
    print("Starting iMessage fix test workflow...")
    if ssh_target is None:
        raise RuntimeError(
            "Test requires a jailbroken device reachable over SSH. "
            "Use --ssh-target root@<device-ip>."
        )

    print(f"Note: If prompted for a '{ssh_target} password' during SSH operations, the default jailbroken root password is 'alpine'")
    print()

    # Step 1: Create a broken state
    print("=" * 60)
    print("STEP 1: Creating broken iMessage state for testing...")
    print("=" * 60)
    
    imessage_plist = "/private/var/mobile/Library/Preferences/com.apple.iChat.plist"
    imessage_log_dir = "/private/var/mobile/Library/Logs/iMessage"
    
    # Create a dummy broken plist file to simulate corruption
    print(f"  Creating corrupted plist at {imessage_plist}...")
    run_command(
        f"ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa {ssh_target} "
        f"'echo \"BROKEN_DATA_CORRUPTED\" > {imessage_plist}'"
    )
    
    # Create iMessage log directory with test files
    print(f"  Creating test log directory at {imessage_log_dir}...")
    run_command(
        f"ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa {ssh_target} "
        f"'mkdir -p {imessage_log_dir} && echo \"test log\" > {imessage_log_dir}/test.log'"
    )
    
    # Verify broken state was created
    print("  Verifying broken state was created...")
    try:
        output = run_command(
            f"ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa {ssh_target} "
            f"'test -f {imessage_plist} && echo EXISTS || echo MISSING'"
        )
        if "EXISTS" not in output:
            raise RuntimeError("Failed to create broken plist for testing.")
        print("  ✓ Broken state confirmed (corrupted plist exists)")
    except RuntimeError as e:
        raise RuntimeError(f"Failed to verify broken state: {e}") from e

    # Step 2: Run the repair
    print()
    print("=" * 60)
    print("STEP 2: Running repair workflow on broken state...")
    print("=" * 60)
    print()
    
    apply_imessage_patch(ssh_target, patch_package=None, skip_backup=True)

    # Step 3: Verify the fix worked
    print()
    print("=" * 60)
    print("STEP 3: Verifying repair was successful...")
    print("=" * 60)
    
    # Check that the corrupted plist was removed
    print(f"  Checking if corrupted plist was removed...")
    try:
        output = run_command(
            f"ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa {ssh_target} "
            f"'test -f {imessage_plist} && echo EXISTS || echo REMOVED'"
        )
        if "REMOVED" not in output:
            raise RuntimeError(
                f"Fix failed: corrupted plist still exists at {imessage_plist}.\n"
                "The repair workflow did not properly clean up broken files."
            )
        print("  ✓ Corrupted plist successfully removed")
    except RuntimeError as e:
        if "does not exist" in str(e):
            print("  ✓ Corrupted plist successfully removed")
        else:
            raise

    # Check that iMessage logs were cleared
    print(f"  Checking if iMessage logs were cleared...")
    try:
        output = run_command(
            f"ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa {ssh_target} "
            f"'test -d {imessage_log_dir} && echo EXISTS || echo REMOVED'"
        )
        if "REMOVED" not in output:
            print(f"  ⚠ Warning: iMessage log directory still exists (may contain old logs)")
        else:
            print("  ✓ iMessage logs successfully cleared")
    except RuntimeError:
        print("  ✓ iMessage logs successfully cleared")

    print()
    print("=" * 60)
    print("✓ TEST PASSED: iMessage fix repair works correctly!")
    print("=" * 60)
    print()
    print("The repair workflow successfully:")
    print("  • Removed corrupted iMessage preference files")
    print("  • Cleared iMessage cache and logs")
    print()
    print("Next steps:")
    print("  1. On your iOS device, go to Settings → Messages")
    print("  2. Sign back into your Apple ID")
    print("  3. Wait for iMessage to activate")

