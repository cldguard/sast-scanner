#!/usr/bin/env bash
set -euo pipefail

echo "Checking security tools installation..."
echo ""

SEMGREP_INSTALLED=false

# Check for Semgrep
if command -v semgrep &> /dev/null; then
    SEMGREP_VERSION=$(semgrep --version 2>&1 | head -n1 || echo "version unknown")
    echo "✓ Semgrep is installed: $SEMGREP_VERSION"
    SEMGREP_INSTALLED=true
else
    echo "✗ Semgrep is NOT installed"
    echo "  Install via devcontainer feature or run:"
    echo "  bash ../sast-scanner/scripts/install_security_tools.sh"
    echo "  or directly with: pip install semgrep"
fi

echo ""

# Check for Docker (fallback option)
if command -v docker &> /dev/null; then
    echo "✓ Docker is available for container-based scanning"
else
    echo "✗ Docker is NOT available"
    echo "  Container-based scanning fallback will not work"
fi

echo ""

# Exit status
if [ "$SEMGREP_INSTALLED" = true ]; then
    echo "[[CLINE:DONE]] Security tools check - All tools available"
    exit 0
elif command -v docker &> /dev/null; then
    echo "[[CLINE:DONE]] Security tools check - Docker fallback available"
    exit 0
else
    echo "[[CLINE:FAIL]] Security tools check - No scanning method available"
    exit 1
fi
