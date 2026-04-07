#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if pip is available and install it if missing
echo "Checking for pip..."
if ! python3 -m pip --version >/dev/null 2>&1; then
    echo "pip not found. Installing python3-pip..."
    if command -v apt >/dev/null 2>&1; then
        sudo apt update
        sudo apt install -y python3-pip
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y python3-pip
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Syu --noconfirm python-pip
    elif command -v emerge >/dev/null 2>&1; then
        sudo emerge --ask=n dev-python/pip
    else
        echo "Unable to install pip. Please manually install python3-pip and try again."
        exit 1
    fi
fi

echo "Installing Python dependencies..."
python3 -m pip install .

echo "Checking and installing system dependencies..."
if command -v apt >/dev/null 2>&1; then
    echo "Detected apt package manager (Debian/Ubuntu-based)."
    sudo apt update
    sudo apt install -y libimobiledevice-utils openssh-client
elif command -v dnf >/dev/null 2>&1; then
    echo "Detected dnf package manager (Fedora/RHEL-based)."
    sudo dnf install -y libimobiledevice-utils openssh-clients
elif command -v pacman >/dev/null 2>&1; then
    echo "Detected pacman package manager (Arch-based)."
    sudo pacman -Syu --noconfirm libimobiledevice openssh
elif command -v emerge >/dev/null 2>&1; then
    echo "Detected emerge package manager (Gentoo)."
    sudo emerge --ask=n libimobiledevice net-misc/openssh
else
    echo "Unknown package manager. Please manually install:"
    echo "  - libimobiledevice (provides idevice_id, ideviceinfo)"
    echo "  - openssh-client (provides ssh)"
    exit 1
fi

echo "Verifying installation..."
python3 -c "from legacy_ios_revival.cli import main; print('CLI import successful')"

echo "Installation complete. You can now run ./run-fix-imessage.sh"