#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v python3 >/dev/null 2>&1; then
  echo "Error: Python 3 is required to run this tool."
  exit 1
fi

export PYTHONPATH="$SCRIPT_DIR/Resources:$PYTHONPATH"

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
        echo "Error: ideviceenterrecovery not found. Install libimobiledevice."
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
        echo "Error: ideviceenterrecovery not found. Install libimobiledevice."
        return 1
    fi
    ideviceenterrecovery
    echo "Device is now in recovery mode."
}

# Function to exit recovery mode
exit_recovery() {
    echo "Exiting recovery mode..."
    if ! command -v idevicerestore >/dev/null 2>&1; then
        echo "Error: idevicerestore not found. Install libimobiledevice."
        return 1
    fi
    idevicerestore --exit-recovery
    echo "Device exited recovery mode."
}

# Function to run iMessage fix
run_imessage_fix() {
    python3 -c "from legacy_ios_revival.cli import main; import sys; sys.exit(main())" "$@"
}

# Main menu
while true; do
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
