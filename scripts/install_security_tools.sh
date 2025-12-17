#!/usr/bin/env bash
set -euo pipefail

echo "Installing security scanning tools..."
echo ""

# Check if running with sudo/root privileges
if [ "$EUID" -eq 0 ]; then
    echo "Running as root/sudo"
    SUDO=""
else
    echo "Running as regular user, will use sudo where needed"
    SUDO="sudo"
fi

echo ""

# Install Semgrep
echo "=== Installing Semgrep ==="
if command -v semgrep &> /dev/null; then
    CURRENT_VERSION=$(semgrep --version 2>&1 | head -n1 || echo "unknown")
    echo "Semgrep already installed: $CURRENT_VERSION"
    echo "Skipping installation (use 'pip install --upgrade semgrep' to upgrade)"
else
    echo "Installing Semgrep using pip..."
    
    # Check if pip is installed
    if command -v pip3 &> /dev/null; then
        $SUDO pip3 install semgrep
    elif command -v pip &> /dev/null; then
        $SUDO pip install semgrep
    else
        echo "Neither pip nor pip3 found. Installing pip first..."
        $SUDO apt-get update
        $SUDO apt-get install -y python3-pip
        $SUDO pip3 install semgrep
    fi
    
    if command -v semgrep &> /dev/null; then
        INSTALLED_VERSION=$(semgrep --version 2>&1 | head -n1)
        echo "✓ Semgrep installed successfully: $INSTALLED_VERSION"
    else
        echo "✗ Semgrep installation failed"
        exit 1
    fi
fi

echo ""
echo "=== Installation Summary ==="

# Verify semgrep
SEMGREP_OK=false

if command -v semgrep &> /dev/null; then
    echo "✓ Semgrep: $(semgrep --version 2>&1 | head -n1)"
    SEMGREP_OK=true
else
    echo "✗ Semgrep: Not found"
fi

echo ""

if [ "$SEMGREP_OK" = true ]; then
    echo "[[CLINE:DONE]] Security tools installation complete"
    exit 0
else
    echo "[[CLINE:FAIL]] Security tools installation incomplete"
    exit 1
fi
