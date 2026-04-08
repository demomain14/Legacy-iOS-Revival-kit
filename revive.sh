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
    if ! command -v ideviceinfo >/dev/null 2>&1; then
        return 1
    fi
    ideviceinfo 2>/dev/null | grep -q "RecoveryMode" || return 1
}

# Function to clear NVRAM
clear_nvram() {
    echo "Clearing NVRAM..."
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
    echo "Device entered recovery mode. NVRAM cleared."
    echo "To exit recovery, use the 'Exit Recovery Mode' option."
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
    if ! command -v idevicerestore >/dev/null 2>&1; then
        echo "Error: idevicerestore not found."
        echo "This tool is part of libimobiledevice. Try installing it:"
        echo "  - Ubuntu/Debian: sudo apt install libimobiledevice-dev libusbmuxd-dev"
        echo "  - Fedora/RHEL: sudo dnf install libimobiledevice-devel libusbmuxd-devel"
        echo "  - Arch: sudo pacman -S libimobiledevice libusbmuxd"
        return 1
    fi
    idevicerestore --exit-recovery
    echo "Device exited recovery mode."
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
    if ! command -v ideviceinfo >/dev/null 2>&1; then
        echo "Warning: ideviceinfo not found."
        echo "This tool is part of libimobiledevice-utils. Try reinstalling dependencies:"
        echo "  Run: ./install-dependencies.sh and choose option 1"
        echo ""
        echo "Troubleshooting steps:"
        echo "  1. Make sure your iOS device is connected and unlocked"
        echo "  2. Trust this computer when prompted on your device"
        echo "  3. Check if you have proper permissions: groups | grep plugdev"
        echo "  4. Try: sudo usermod -a -G plugdev \$USER (then reboot)"
        return 1
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
        return 1
    }

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
    echo "2. Clear NVRAM"
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
