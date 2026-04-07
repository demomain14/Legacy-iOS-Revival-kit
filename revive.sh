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
    ideviceenterrecovery
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
    ideviceenterrecovery
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
    echo "2. Backup iMessage settings (requires SSH)"
    echo "3. Repair iMessage (requires SSH)"
    echo "4. Back to main menu"
    echo ""
    read -p "Choose an option (1-4): " imessage_choice
    
    case $imessage_choice in
        1)
            echo "Checking device connectivity..."
            python3 -c "from legacy_ios_revival.cli import main; import sys; sys.argv = ['fix-imessage', 'check']; sys.exit(main())"
            ;;
        2)
            read -p "Enter SSH target (e.g., root@192.168.1.10): " ssh_target
            if [[ -z "$ssh_target" ]]; then
                echo "Error: SSH target is required."
                return 1
            fi
            echo "Backing up iMessage settings..."
            python3 -c "from legacy_ios_revival.cli import main; import sys; sys.argv = ['fix-imessage', '--ssh-target', '$ssh_target', 'backup']; sys.exit(main())"
            ;;
        3)
            read -p "Enter SSH target (e.g., root@192.168.1.10): " ssh_target
            if [[ -z "$ssh_target" ]]; then
                echo "Error: SSH target is required."
                return 1
            fi
            read -p "Enter patch package path (optional, press Enter to skip): " patch_package
            if [[ -z "$patch_package" ]]; then
                echo "Running iMessage repair..."
                python3 -c "from legacy_ios_revival.cli import main; import sys; sys.argv = ['fix-imessage', '--ssh-target', '$ssh_target', 'repair']; sys.exit(main())"
            else
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
    if ! command -v ideviceinfo >/dev/null 2>&1; then
        echo "Warning: ideviceinfo not found. Cannot display device info."
        return 1
    fi
    
    if ! command -v idevice_id >/dev/null 2>&1; then
        echo "Warning: idevice_id not found. No device connected."
        return 1
    fi
    
    local device_id
    device_id=$(idevice_id -l 2>/dev/null | head -1) || return 1
    
    if [[ -z "$device_id" ]]; then
        return 1
    fi
    
    local device_info
    device_info=$(ideviceinfo -u "$device_id" 2>/dev/null) || return 1
    
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
