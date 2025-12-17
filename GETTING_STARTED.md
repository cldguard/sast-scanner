# Getting Started with SAST Scanner

This guide will help you get started with the SAST (Static Application Security Testing) scanner powered by Semgrep.

## Prerequisites

### Required
- **Docker Desktop** - The scanner runs Semgrep via Docker for consistency across environments
  - [Windows](https://docs.docker.com/desktop/install/windows-install/)
  - [Mac](https://docs.docker.com/desktop/install/mac-install/)
  - [Linux](https://docs.docker.com/engine/install/)

### Optional
- **Python 3.x** - For HTML report generation
- **PowerShell** (Windows) or **Bash** (Linux/Mac)

## Quick Start

### 1. Verify Docker is Running

```bash
docker --version
docker info
```

### 2. Run Your First Scan

**Windows (PowerShell):**
```powershell
.\scripts\win-scan.ps1 -Path "C:\path\to\your\project"
```

**Linux/Mac (Bash):**
```bash
./scripts/scan.sh /path/to/your/project
```

### 3. View Results

Scan results are saved to `../sast-scan-output/<project-name>-<timestamp>/`:
- `semgrep-results.json` - Machine-readable JSON format
- `semgrep-results.sarif` - SARIF format for IDE integration
- `semgrep-results.html` - Human-readable HTML report

## Scan Options

### Standard Output Directory
```bash
# Uses ../sast-scan-output/<repo>-YYYYMMDDHH24miss/
./scripts/scan.sh --std-output /path/to/project
```

### Custom Output Directory
```bash
./scripts/scan.sh --output-dir ./my-results /path/to/project
```

### JSON Output Only
```bash
./scripts/scan.sh --json --output results.json /path/to/project
```

## Health Checks

The scanner performs automatic health checks:

1. **Pre-scan**: Verifies Docker is available and responsive
2. **Post-scan**: Confirms Docker remained healthy during the scan

Example output:
```
=== Docker Health Check ===
Checking Docker availability...
  Docker Server version: 28.5.1
Verifying Docker daemon is responsive...
  Docker daemon is running: v28.5.1
Checking Semgrep image availability...
  Semgrep image found: returntocorp/semgrep:latest
=== Health Check PASSED ===
```

## Understanding Results

### Exit Codes
- `0` - No security issues found
- `1` - Security issues detected (review required)

### Severity Levels
- **CRITICAL** - Immediate action required
- **HIGH** - Address before deployment
- **MEDIUM** - Review and plan remediation
- **LOW** - Consider fixing when convenient

## Next Steps

### Integration
For CI/CD integration, Makefile examples, and advanced configuration:
- 📖 **[Integration Guide](./docs/INTEGRATION.md)**

### API Reference
For programmatic access and automation:
- 📖 **[OpenAPI Specification](./api/openapi.yaml)**

### Security Policy
For vulnerability reporting and security practices:
- 📖 **[Security Policy](./SECURITY.md)**

## Troubleshooting

### Docker Not Found
```
ERROR: Docker is not available
```
**Solution:** Start Docker Desktop and verify with `docker info`

### Permission Denied
```
Error writing HTML report: Permission denied
```
**Solution:** Ensure write permissions to the output directory

### Slow First Run
The first scan may be slow as Docker pulls the Semgrep image (~400MB). Subsequent scans use the cached image.

## Example Scan Output

```
Running Windows security static analysis scan...
Scanning directory: D:\Projects\my-app

=== Docker Health Check ===
  Docker Server version: 28.5.1
  Docker daemon is running: v28.5.1
  Semgrep image found: returntocorp/semgrep:latest
=== Health Check PASSED ===

Using Docker-based Semgrep scanner...
Docker image: returntocorp/semgrep
Running scan...

┌──────────────┐
│ Scan Summary │
└──────────────┘
✅ Scan completed successfully.
 • Findings: 0 (0 blocking)
 • Rules run: 107
 • Targets scanned: 45
 • Parsed lines: ~100.0%

Security scan passed - no security issues found
[[CLINE:DONE]] Security scan
```

## Support

- **Documentation**: [INTEGRATION.md](./docs/INTEGRATION.md)
- **Issues**: Report bugs via the issue tracker
- **Security**: See [SECURITY.md](../SECURITY.md) for vulnerability reporting
