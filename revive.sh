#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v python3 >/dev/null 2>&1; then
  echo "Error: Python 3 is required to run this tool."
  exit 1
fi

export PYTHONPATH="$SCRIPT_DIR/Resources:${PYTHONPATH:-}"

# Function to detect if device is in recovery mode
is_in_recovery() {
    # Method 1: Check with irecovery (if available)
    if command -v irecovery >/dev/null 2>&1; then
        if irecovery -q 2>/dev/null | grep -q "MODE.*Recovery\|MODE.*DFU"; then
            return 0
        fi
    fi

    # Method 2: Check with ideviceinfo (for normal mode detection)
    if command -v ideviceinfo >/dev/null 2>&1; then
        if ideviceinfo 2>/dev/null | grep -q "RecoveryMode"; then
            return 0
        fi
    fi

    # Method 3: Check USB devices for Apple recovery/DFU mode
    if command -v lsusb >/dev/null 2>&1; then
        # Look for Apple devices with specific product IDs that indicate recovery/DFU mode
        if lsusb 2>/dev/null | grep -q "05ac:"; then
            # Check for common recovery/DFU product IDs
            if lsusb 2>/dev/null | grep -E "05ac:128[01]|05ac:122[27]|05ac:1338" >/dev/null; then
                return 0
            fi
        fi
    fi

    return 1
}

# Function to clear NVRAM
clear_nvram() {
    echo "Clearing NVRAM requires the device to be in DFU mode."
    echo ""

    # Check if device is already in DFU/recovery mode
    if is_in_recovery; then
        echo "✓ Device is already in recovery/DFU mode."
    else
        echo "✗ Device is not in DFU mode. You need to put your device into DFU mode first."
        echo ""
        echo "=== DFU MODE INSTRUCTIONS ==="
        echo "Follow these steps carefully:"
        echo ""
        echo "1. Disconnect your device from the computer"
        echo "2. Turn off your device completely"
        echo "3. Ready your fingers on Power and Home buttons"
        echo ""
        echo "For iPod Touch/iPhone:"
        echo "• Hold Power button for 3 seconds: 3... 2... 1... GO!"
        echo "• While still holding Power, hold Home button for 8 seconds: 8... 7... 6... 5... 4... 3... 2... 1..."
        echo "• Release Power button but keep holding Home for another 8 seconds: 8... 7... 6... 5... 4... 3... 2... 1..."
        echo ""
        echo "You should see a black screen - this means you're in DFU mode!"
        echo "Now connect your device back to the computer."
        echo ""
        read -p "Press Enter when your device is in DFU mode and connected..."
    fi

    # Check if irecovery is available
    if ! command -v irecovery >/dev/null 2>&1; then
        echo "Error: irecovery not found."
        echo "This tool is needed for DFU mode operations. Try installing it:"
        echo "  - Ubuntu/Debian: sudo apt install irecovery"
        echo "  - Or run: ./install-dependencies.sh"
        return 1
    fi

    # Verify device is in DFU mode
    if ! irecovery -q 2>/dev/null | grep -q "MODE.*DFU"; then
        echo "Error: Device is not in DFU mode."
        echo "Please follow the DFU mode instructions above and try again."
        return 1
    fi

    echo "Clearing NVRAM..."
    # Send NVRAM clear command via irecovery
    if irecovery -c "nvram clear" 2>/dev/null; then
        echo "✓ NVRAM cleared successfully!"
        echo "Your device will reboot automatically."
        echo ""
        echo "Note: After rebooting, you may need to:"
        echo "1. Re-jailbreak your device if it was jailbroken"
        echo "2. Restore from backup if needed"
        echo "3. Re-trust this computer"
    else
        echo "✗ Failed to clear NVRAM."
        echo "The device may not be properly in DFU mode, or there was an error."
        return 1
    fi
}

# Function to enter recovery mode
enter_recovery() {
    echo "Entering recovery mode..."
    if ! command -v ideviceenterrecovery >/dev/null 2>&1; then
        echo "Error: ideviceenterrecovery not found."
        echo "This tool is part of libimobiledevice. Try installing it:"
        echo "  - Ubuntu/Debian: sudo apt install libimobiledevice-dev"
        echo "  - Fedora/RHEL: sudo dnf install libimobiledevice-devel"
        echo "  - Arch: sudo pacman -S libimobiledevice"
        return 1
    fi

    # Get device UDID
    local device_udid
    device_udid=$(idevice_id -l 2>/dev/null | head -1)
    if [[ -z "$device_udid" ]]; then
        echo "Error: No device connected or device not detected."
        echo "Make sure your iOS device is connected and trusted."
        return 1
    fi

    echo "Found device with UDID: $device_udid"
    ideviceenterrecovery "$device_udid"
    echo "Device is now in recovery mode."
}

# Function to exit recovery mode
exit_recovery() {
    echo "Exiting recovery mode..."
    echo "Note: This will attempt to exit recovery mode and reboot your device."
    echo ""

    # Method 1: Try with idevicerestore
    if command -v idevicerestore >/dev/null 2>&1; then
        echo "Attempting to exit recovery mode with idevicerestore..."
        if idevicerestore --exit-recovery 2>/dev/null; then
            echo "Successfully sent exit recovery command."
            echo "Your device should reboot normally."
            return 0
        fi
    fi

    # Method 2: Try with irecovery
    if command -v irecovery >/dev/null 2>&1; then
        echo "Attempting to exit recovery mode with irecovery..."
        if irecovery -n 2>/dev/null; then
            echo "Successfully sent exit recovery command."
            echo "Your device should reboot normally."
            return 0
        fi
    fi

    # Method 3: Manual instructions
    echo "Could not automatically exit recovery mode."
    echo ""
    echo "Manual steps to exit recovery mode:"
    echo "1. Disconnect your device from the computer"
    echo "2. Hold the Power button until the device restarts"
    echo "3. For iPod Touch: Hold Power + Home buttons until Apple logo appears"
    echo "4. For iPhone: Hold Power + Volume Down until Apple logo appears"
    echo ""
    echo "If that doesn't work, you may need to use iTunes/Finder to restore the device."
    return 1
}

# Function to run iMessage fix
run_imessage_fix() {
    echo ""
    echo "iMessage Fix Options"
    echo "===================="
    echo "1. Check device connectivity"
    echo "2. Backup iMessage settings (requires SSH connection to device)"
    echo "3. Repair iMessage (requires SSH connection to device)"
    echo "4. Back to main menu"
    echo ""
    read -p "Choose an option (1-4): " imessage_choice

    case $imessage_choice in
        1)
            echo "Checking device connectivity..."
            python3 -c "from legacy_ios_revival.cli import main; import sys; sys.argv = ['fix-imessage', 'check']; sys.exit(main())"
            ;;
        2)
            echo ""
            echo "=== SSH CONNECTION SETUP ==="
            echo ""
            echo "To backup iMessage settings, we need to connect to your iOS device remotely."
            echo "This requires your device to be 'jailbroken' and have SSH access enabled."
            echo ""
            echo "WHAT IS SSH?"
            echo "SSH is like a secure remote control for your device. It lets this computer"
            echo "connect to your iPhone/iPod remotely over your WiFi network."
            echo ""
            echo "HOW TO FIND YOUR SSH TARGET:"
            echo ""
            echo "Step 1: Make sure your iOS device is jailbroken"
            echo "       - This tool only works with jailbroken devices"
            echo "       - If not jailbroken, you cannot use backup/repair features"
            echo ""
            echo "Step 2: On your iOS device, open any app that shows network info"
            echo "       - Look for 'IP Address' or 'Wi-Fi Address'"
            echo "       - Common apps: Settings → Wi-Fi → tap the (i) next to your network"
            echo "       - Or use apps like 'Network Analyzer' or 'WiFi Analyzer' from Cydia"
            echo ""
            echo "Step 3: Find the IP address"
            echo "       - It will look like: 192.168.1.100 or 192.168.0.50"
            echo "       - Write this number down"
            echo ""
            echo "Step 4: The SSH target format is: root@[IP_ADDRESS]"
            echo "       - Replace [IP_ADDRESS] with the number you found"
            echo "       - Example: root@192.168.1.100"
            echo ""
            echo "WHAT IS 'root'?"
            echo "       - 'root' is the administrator username for jailbroken iOS devices"
            echo "       - It's like the 'boss' account that can access system files"
            echo ""
            read -p "Enter SSH target (format: root@[IP_ADDRESS], e.g., root@192.168.1.100): " ssh_target
            if [[ -z "$ssh_target" ]]; then
                echo "Error: SSH target is required for backup."
                return 1
            fi
            echo "Connecting to: $ssh_target"
            echo "Backing up iMessage settings..."
            python3 -c "from legacy_ios_revival.cli import main; import sys; sys.argv = ['fix-imessage', '--ssh-target', '$ssh_target', 'backup']; sys.exit(main())"
            ;;
        3)
            echo ""
            echo "=== SSH CONNECTION SETUP ==="
            echo ""
            echo "To repair iMessage, we need to connect to your iOS device remotely."
            echo "This requires your device to be 'jailbroken' and have SSH access enabled."
            echo ""
            echo "WHAT IS SSH?"
            echo "SSH is like a secure remote control for your device. It lets this computer"
            echo "connect to your iPhone/iPod remotely over your WiFi network."
            echo ""
            echo "HOW TO FIND YOUR SSH TARGET:"
            echo ""
            echo "Step 1: Make sure your iOS device is jailbroken"
            echo "       - This tool only works with jailbroken devices"
            echo "       - If not jailbroken, you cannot use repair features"
            echo ""
            echo "Step 2: On your iOS device, find your IP address"
            echo "       - Go to: Settings → Wi-Fi → tap the (i) next to your connected network"
            echo "       - Look for 'IP Address' - it looks like: 192.168.1.100"
            echo "       - Or use apps like 'Network Analyzer' from Cydia"
            echo ""
            echo "Step 3: The SSH target format is: root@[IP_ADDRESS]"
            echo "       - Replace [IP_ADDRESS] with your device's IP address"
            echo "       - Example: root@192.168.1.100"
            echo ""
            echo "WHAT IS 'root'?"
            echo "       - 'root' is the administrator username for jailbroken iOS"
            echo "       - It's the main account that can change system settings"
            echo ""
            read -p "Enter SSH target (format: root@[IP_ADDRESS], e.g., root@192.168.1.100): " ssh_target
            if [[ -z "$ssh_target" ]]; then
                echo "Error: SSH target is required for repair."
                return 1
            fi
            read -p "Enter patch package path (optional, press Enter to skip): " patch_package
            if [[ -z "$patch_package" ]]; then
                echo "Connecting to: $ssh_target"
                echo "Running iMessage repair..."
                python3 -c "from legacy_ios_revival.cli import main; import sys; sys.argv = ['fix-imessage', '--ssh-target', '$ssh_target', 'repair']; sys.exit(main())"
            else
                echo "Connecting to: $ssh_target"
                echo "Running iMessage repair with patch..."
                python3 -c "from legacy_ios_revival.cli import main; import sys; sys.argv = ['fix-imessage', '--ssh-target', '$ssh_target', '--patch-package', '$patch_package', 'repair']; sys.exit(main())"
            fi
            ;;
        4)
            return 0
            ;;
        *)
            echo "Invalid option. Please choose 1-4."
            ;;
    esac

    read -p "Press Enter to continue..."
}

# Function to display device information
show_device_info() {
    # Check if tools are installed
    if ! command -v ideviceinfo >/dev/null 2>&1 && ! command -v irecovery >/dev/null 2>&1; then
        echo "Warning: Neither ideviceinfo nor irecovery found."
        echo "This tool requires libimobiledevice-utils. Try reinstalling dependencies:"
        echo "  Run: ./install-dependencies.sh and choose option 1"
        echo ""
        echo "Troubleshooting steps:"
        echo "  1. Make sure your iOS device is connected and unlocked"
        echo "  2. Trust this computer when prompted on your device"
        echo "  3. Check if you have proper permissions: groups | grep plugdev"
        echo "  4. Try: sudo usermod -a -G plugdev \$USER (then reboot)"
        return 1
    fi

    # Check if device is in recovery mode first
    if is_in_recovery; then
        echo "============================================================"
        echo "Device Status: IN RECOVERY MODE"
        echo "Device Type: iOS Device (Recovery Mode)"
        echo "Device Name: Unknown (Recovery Mode)"
        echo "iOS Version: Unknown (Recovery Mode)"
        echo "============================================================"
        echo ""
        echo "Note: Device is in recovery mode. Use option 3 to exit recovery mode."
        return 0
    fi

    if ! command -v idevice_id >/dev/null 2>&1; then
        echo "Warning: idevice_id not found."
        echo "This tool is part of libimobiledevice-utils. Try reinstalling dependencies."
        return 1
    fi

    # Try to get device ID
    local device_id
    device_id=$(idevice_id -l 2>/dev/null | head -1) || {
        echo "Warning: No device detected or device not trusted."
        echo ""
        echo "Troubleshooting steps:"
        echo "  1. Make sure your iOS device is connected via USB"
        echo "  2. Unlock your device and tap 'Trust' when prompted"
        echo "  3. Wait a few seconds after trusting, then try again"
        echo "  4. Check USB connection: lsusb | grep Apple"
        echo "  5. Try a different USB port or cable"
        echo "  6. If device is in recovery mode, it will show 'IN RECOVERY MODE' above"
    if [[ -z "$device_id" ]]; then
        echo "Warning: No device detected. Please connect your iOS device."
        return 1
    fi

    # Try to get device info
    local device_info
    device_info=$(ideviceinfo -u "$device_id" 2>/dev/null) || {
        echo "Warning: Could not get device information."
        echo "The device may not be properly trusted or there may be a permissions issue."
        return 1
    }

    local product_type device_name product_version
    product_type=$(echo "$device_info" | grep "^ProductType:" | cut -d' ' -f2 || echo "Unknown")
    device_name=$(echo "$device_info" | grep "^DeviceName:" | cut -d' ' -f2- || echo "Unknown Device")
    product_version=$(echo "$device_info" | grep "^ProductVersion:" | cut -d' ' -f2 || echo "Unknown")

    echo "============================================================"
    echo "Device Type: $product_type"
    echo "Device Name: $device_name"
    echo "iOS Version: $product_version"
    echo "============================================================"
}

# Main menu
while true; do
    clear
    echo ""
    
    # Display connected device info
    if ! show_device_info; then
        echo "Warning: No device detected. Please connect your iOS device."
        echo ""
    fi
    
    echo ""
    echo "Legacy iOS Revival Kit Menu"
    echo "==========================="
    echo "1. Run iMessage Fix"
    echo "2. Clear NVRAM (requires DFU mode)"
    if is_in_recovery; then
        echo "3. Exit Recovery Mode"
    else
        echo "3. Enter Recovery Mode"
    fi
    echo "4. Exit"
    echo ""
    read -p "Choose an option (1-4): " choice

    case $choice in
        1)
            echo "Running iMessage Fix..."
            run_imessage_fix
            ;;
        2)
            clear_nvram
            ;;
        3)
            if is_in_recovery; then
                exit_recovery
            else
                enter_recovery
            fi
            ;;
        4)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please choose 1-4."
            ;;
    esac
    echo ""
done
