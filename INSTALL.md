# Installation Guide

## Quick Start

### 1. Copy to your project

Copy the `sast-scanner` folder to your project workspace:

```bash
cp -r sast-scanner/ ../your-project/sast-scanner/
```

### 2. Include in your Makefile

Add to your service's Makefile:

```makefile
include sast-scanner/Makefile.security
```

Or if using a relative path from a subdirectory:

```makefile
include ../sast-scanner/Makefile.security
```

### 3. Install security tools (if not using devcontainer)

```bash
bash sast-scanner/scripts/install_security_tools.sh
```

### 4. Run security scan

```bash
make scan
```

## Available Targets

After including `Makefile.security`, these targets are available:

- `check-security-tools` - Verify Semgrep is installed
- `scan` - Run static analysis security scanning
- `security-full` - Run complete security suite
- `install-security-tools` - Install Semgrep

## Documentation

- `README.md` - Project overview
- `SECURITY.md` - Security policies and procedures
- `CHANGELOG.md` - Version history
- `docs/INTEGRATION.md` - Detailed integration guide

## Support

For issues, see: https://github.com/cldguard/sast-scanner
