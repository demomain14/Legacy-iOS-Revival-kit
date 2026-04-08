#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Function to install dependencies
install_dependencies() {
    echo "Legacy iOS Revival Kit - Installing Dependencies"
    echo "================================================"
    echo ""
    echo "This script will install:"
    echo "  • Python 3 pip (Python package manager)"
    echo "  • Python dependencies from pyproject.toml (installed to user directory if needed)"
    echo "  • libimobiledevice tools (idevice_id, ideviceinfo, ideviceenterrecovery, idevicerestore)"
    echo "  • libimobiledevice development headers and core dependencies"
    echo "  • libusbmuxd and libusbmuxd-dev (USB multiplexing)"
    echo "  • usbmuxd daemon (required for iOS device communication)"
    echo "  • Additional iOS tools (libirecovery, libplist, etc. - if available)"
    echo "  • openssh-client (ssh, scp for remote device access)"
    echo ""
    echo "Note: Some optional packages may not be available on all systems - this is usually OK"
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
    # Try installing with --user flag first (safer for externally managed environments)
    if python3 -m pip install --user . 2>/dev/null; then
        echo "Python dependencies installed successfully to user directory."
    else
        echo "Warning: Could not install to user directory. This may be due to an externally managed Python environment."
        echo ""
        echo "Trying alternative installation methods..."
        echo ""

        # Try with --break-system-packages (use with caution)
        if python3 -m pip install --break-system-packages . 2>/dev/null; then
            echo "Python dependencies installed successfully (system-wide)."
        else
            echo "Error: Could not install Python dependencies automatically."
            echo ""
            echo "Please choose one of the following options:"
            echo ""
            echo "Option 1 - Use a virtual environment:"
            echo "  python3 -m venv venv"
            echo "  source venv/bin/activate"
            echo "  python3 -m pip install ."
            echo ""
            echo "Option 2 - Install manually:"
            echo "  python3 -m pip install --user ."
            echo ""
            echo "Option 3 - Use system package manager (if available):"
            echo "  Check if your distribution provides a package for this tool."
            echo ""
            echo "After installing manually, run this script again with option 1 to install system dependencies."
            exit 1
        fi
    fi

    echo "Checking and installing system dependencies..."
    if command -v apt >/dev/null 2>&1; then
        echo "Detected apt package manager (Debian/Ubuntu-based)."
        sudo apt update
        # Install core libimobiledevice packages
        sudo apt install -y libimobiledevice-utils libimobiledevice-dev libusbmuxd-dev openssh-client usbmuxd
        # Try to install additional iOS recovery tools (may not be available on all systems)
        echo "Installing additional iOS tools (some may not be available)..."
        sudo apt install -y libplist-dev libimobiledevice-glue-dev 2>/dev/null || echo "Some additional packages not available - this is usually OK"
        sudo apt install -y libirecovery-dev 2>/dev/null || echo "libirecovery-dev not available - trying alternatives..."
        sudo apt install -y libirecovery3 libirecovery4 2>/dev/null || echo "libirecovery packages not found - recovery mode detection may be limited"
        sudo apt install -y irecovery 2>/dev/null || echo "irecovery not available - some recovery features may not work"
        # Try to install idevicerestore if available as separate package
        sudo apt install -y idevicerestore 2>/dev/null || echo "idevicerestore included in libimobiledevice-utils"
        # Start usbmuxd service if available
        sudo systemctl start usbmuxd 2>/dev/null || true
        sudo systemctl enable usbmuxd 2>/dev/null || true
    elif command -v dnf >/dev/null 2>&1; then
        echo "Detected dnf package manager (Fedora/RHEL-based)."
        sudo dnf install -y libimobiledevice-utils libimobiledevice-devel libusbmuxd-devel openssh-clients usbmuxd
        echo "Installing additional iOS tools (some may not be available)..."
        sudo dnf install -y libplist-devel libimobiledevice-glue-devel 2>/dev/null || echo "Some additional packages not available - this is usually OK"
        sudo dnf install -y libirecovery-devel 2>/dev/null || echo "libirecovery packages not found - idevicerestore may still work"
        sudo systemctl start usbmuxd 2>/dev/null || true
        sudo systemctl enable usbmuxd 2>/dev/null || true
    elif command -v pacman >/dev/null 2>&1; then
        echo "Detected pacman package manager (Arch-based)."
        sudo pacman -Syu --noconfirm libimobiledevice libusbmuxd openssh usbmuxd
        echo "Installing additional iOS tools (some may not be available)..."
        sudo pacman -S --noconfirm libplist libimobiledevice-glue 2>/dev/null || echo "Some additional packages not available - this is usually OK"
        sudo pacman -S --noconfirm libirecovery 2>/dev/null || echo "libirecovery packages not found - idevicerestore may still work"
        sudo systemctl start usbmuxd 2>/dev/null || true
        sudo systemctl enable usbmuxd 2>/dev/null || true
    elif command -v emerge >/dev/null 2>&1; then
        echo "Detected emerge package manager (Gentoo)."
        sudo emerge --ask=n libimobiledevice libusbmuxd net-misc/openssh sys-apps/usbmuxd
        echo "Installing additional iOS tools (some may not be available)..."
        sudo emerge --ask=n dev-libs/libplist app-pda/libimobiledevice-glue 2>/dev/null || echo "Some additional packages not available - this is usually OK"
        sudo emerge --ask=n app-pda/libirecovery 2>/dev/null || echo "libirecovery packages not found - idevicerestore may still work"
        sudo systemctl start usbmuxd 2>/dev/null || true
        sudo systemctl enable usbmuxd 2>/dev/null || true
    else
        echo "Unknown package manager. Please manually install:"
        echo "  - libimobiledevice-utils and libimobiledevice-dev"
        echo "  - libusbmuxd-dev and usbmuxd"
        echo "  - libirecovery-dev, libplist-dev, and libimobiledevice-glue-dev"
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
}

# Function to uninstall dependencies
uninstall_dependencies() {
    echo "Legacy iOS Revival Kit - Uninstalling Dependencies"
    echo "=================================================="
    echo ""
    echo "This will remove:"
    echo "  • Python dependencies installed via pip (from user directory or system-wide)"
    echo "  • System packages (libimobiledevice, libusbmuxd, usbmuxd, openssh-client)"
    echo "  • Note: python3-pip will NOT be removed (it may be needed by other programs)"
    echo ""

    read -p "Are you sure you want to uninstall all dependencies? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Uninstallation cancelled."
        return 0
    fi

    echo ""
    echo "Uninstalling Python dependencies..."
    # Try uninstalling from user directory first
    if python3 -m pip uninstall -y --user legacy-ios-revival-kit 2>/dev/null; then
        echo "Python package removed from user directory."
    else
        # Try system-wide uninstall
        python3 -m pip uninstall -y legacy-ios-revival-kit 2>/dev/null || echo "Python package not found or already removed."
    fi

    echo "Uninstalling system packages..."
    if command -v apt >/dev/null 2>&1; then
        echo "Detected apt package manager (Debian/Ubuntu-based)."
        sudo apt remove -y libimobiledevice-utils libimobiledevice-dev libusbmuxd-dev openssh-client usbmuxd libplist-dev libimobiledevice-glue-dev 2>/dev/null || true
        sudo apt remove -y libirecovery-dev libirecovery3 libirecovery4 idevicerestore 2>/dev/null || true
        sudo apt autoremove -y 2>/dev/null || true
    elif command -v dnf >/dev/null 2>&1; then
        echo "Detected dnf package manager (Fedora/RHEL-based)."
        sudo dnf remove -y libimobiledevice-utils libimobiledevice-devel libusbmuxd-devel openssh-clients usbmuxd libplist-devel libimobiledevice-glue-devel 2>/dev/null || true
        sudo dnf remove -y libirecovery-devel 2>/dev/null || true
    elif command -v pacman >/dev/null 2>&1; then
        echo "Detected pacman package manager (Arch-based)."
        sudo pacman -Rns --noconfirm libimobiledevice libusbmuxd openssh usbmuxd libplist libimobiledevice-glue 2>/dev/null || true
        sudo pacman -Rns --noconfirm libirecovery 2>/dev/null || true
    elif command -v emerge >/dev/null 2>&1; then
        echo "Detected emerge package manager (Gentoo)."
        sudo emerge --unmerge libimobiledevice libusbmuxd net-misc/openssh sys-apps/usbmuxd dev-libs/libplist app-pda/libimobiledevice-glue 2>/dev/null || true
        sudo emerge --unmerge app-pda/libirecovery 2>/dev/null || true
    else
        echo "Unknown package manager. Please manually uninstall:"
        echo "  - libimobiledevice-utils and libimobiledevice-dev"
        echo "  - libusbmuxd-dev and usbmuxd"
        echo "  - libirecovery-dev, libplist-dev, and libimobiledevice-glue-dev"
        echo "  - openssh-client (provides ssh)"
        echo "  - Run: pip uninstall legacy-ios-revival-kit"
        exit 1
    fi

    echo ""
    echo "Uninstallation complete."
    echo "Note: Some mdadm warnings above are harmless and can be ignored."
    echo "Note: Some dependencies may still be present if they were installed by other programs."
}

# Main menu
echo "Legacy iOS Revival Kit - Dependency Manager"
echo "==========================================="
echo ""
echo "Choose an option:"
echo "1. Install dependencies"
echo "2. Uninstall dependencies"
echo "3. Exit"
echo ""
read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        install_dependencies
        ;;
    2)
        uninstall_dependencies
        ;;
    3)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid choice. Please run the script again and choose 1-3."
        exit 1
        ;;
esac