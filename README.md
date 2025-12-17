# sast-scanner

Shared infrastructure and tooling for the SmallBizSec platform.

## Overview

This module provides centralized security static analysis tools, devcontainer configurations, and reusable scripts for all sbs-* services.

## Components

### Security Scanning

The project implements a static analysis security pipeline:

- **Semgrep**: Static Application Security Testing (SAST)
  - Configured to fail builds on HIGH/CRITICAL findings
  - Uses security-focused rulesets
  - Can run in both native and Docker modes
  - Runs on port 8501 for server mode
  - Generates detailed HTML and JSON reports

```
┌─────────────────────────────────────┐
│                                     │
│  Static Application Security Testing │
│  (Semgrep)                          │
│                                     │
└─────────────────────────────────────┘
                │
                v
┌─────────────────────────────────────────────────┐
│                                                 │
│           Security Gate (CI/CD)                 │
│    Fail build on HIGH/CRITICAL findings         │
│                                                 │
└─────────────────────────────────────────────────┘
```

For more details on the security implementation, see [SECURITY.md](./SECURITY.md).

### Shared Resources
- `.devcontainer/`: Base devcontainer configuration with pre-installed security tools
- `scripts/`: Reusable scripts for security scanning and tool installation
- `phases/`: Standard phase documentation templates
- `Makefile.security`: Makefile fragment for security targets

## Usage

### In Service Projects

Include the shared Makefile in your service's Makefile:

```makefile
include ../sast-scanner/Makefile.security
```

Extend the base devcontainer configuration:

```json
{
  "name": "your-service",
  "extends": "../../sast-scanner/.devcontainer/devcontainer-base.json"
}
```

### Running Security Scans

```bash
# Check if tools are installed
make check-security-tools

# Run static analysis security scan
make scan

# Run static analysis security scan with JSON output
bash scripts/scan.sh --json

# Run static analysis security scan with standard output directory
bash scripts/scan.sh --std-output
```

The scan results will be stored in the `./sast-scan-output/<repository>-<timestamp>/` directory:
- `semgrep-results.json`: JSON file containing detailed scan results
- `semgrep-results.html`: HTML report for easy viewing of results

## Installation

Security tools are automatically installed via devcontainer features. For manual installation:

```bash
bash scripts/install_security_tools.sh
```

## Documentation

See `phases/` directory for detailed phase-by-phase documentation.

## Version

1.0.0
