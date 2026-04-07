#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Legacy iOS Revival Kit - Dependency Installer"
echo "=============================================="
echo ""
echo "This script will install:"
echo "  • Python 3 pip (Python package manager)"
echo "  • Python dependencies from pyproject.toml"
echo "  • libimobiledevice tools (idevice_id, ideviceinfo, ideviceenterrecovery, idevicerestore)"
echo "  • libimobiledevice development headers"
echo "  • libusbmuxd and libusbmuxd-dev (USB multiplexing)"
echo "  • openssh-client (ssh, scp for remote device access)"
echo ""
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
    sudo apt install -y libimobiledevice-utils libimobiledevice-dev libusbmuxd-dev openssh-client
elif command -v dnf >/dev/null 2>&1; then
    echo "Detected dnf package manager (Fedora/RHEL-based)."
    sudo dnf install -y libimobiledevice-utils libimobiledevice-devel libusbmuxd-devel openssh-clients
elif command -v pacman >/dev/null 2>&1; then
    echo "Detected pacman package manager (Arch-based)."
    sudo pacman -Syu --noconfirm libimobiledevice libusbmuxd openssh
elif command -v emerge >/dev/null 2>&1; then
    echo "Detected emerge package manager (Gentoo)."
    sudo emerge --ask=n libimobiledevice libusbmuxd net-misc/openssh
else
    echo "Unknown package manager. Please manually install:"
    echo "  - libimobiledevice and libimobiledevice-dev"
    echo "  - libusbmuxd and libusbmuxd-dev"
    echo "  - openssh-client (provides ssh)"
    exit 1
fi

echo "Verifying installation..."
python3 -c "from legacy_ios_revival.cli import main; print('CLI import successful')"

echo ""
echo "Checking for required tools..."
required_tools=("idevice_id" "ideviceinfo" "ssh" "scp" "ideviceenterrecovery" "idevicerestore")
missing_tools=()

for tool in "${required_tools[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        missing_tools+=("$tool")
    else
        echo "  ✓ $tool found"
    fi
done

if [[ ${#missing_tools[@]} -gt 0 ]]; then
    echo ""
    echo "Warning: The following tools are missing:"
    for tool in "${missing_tools[@]}"; do
        echo "  - $tool"
    done
    echo ""
    echo "Try running the install script again, or manually install libimobiledevice packages:"
    echo "  Ubuntu/Debian: sudo apt install libimobiledevice-utils libimobiledevice-dev"
    echo "  Fedora/RHEL: sudo dnf install libimobiledevice-utils libimobiledevice-devel"
    echo "  Arch: sudo pacman -S libimobiledevice"
else
    echo ""
    echo "All required tools are installed!"
fi

echo ""
echo "Installation complete. You can now run ./revive.sh"