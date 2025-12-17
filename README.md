# SAST Scanner

[![Security Scan](https://img.shields.io/badge/security-semgrep-blue)](https://semgrep.dev)
[![Docker](https://img.shields.io/badge/docker-required-blue)](https://docker.com)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

A comprehensive Static Application Security Testing (SAST) scanner powered by Semgrep, designed for automated security vulnerability detection in your codebase.

## 🚀 Features

- **Docker-based Execution** - Consistent scanning across all environments
- **Multi-format Output** - JSON, SARIF, and HTML reports
- **Health Checks** - Pre/post-scan Docker verification
- **Cross-platform** - Windows (PowerShell) and Linux/Mac (Bash) support
- **CI/CD Ready** - Exit codes and sentinels for automation
- **Standardized Output** - Organized results in `../sast-scan-output/<repo>-<timestamp>/`

## 📋 Prerequisites

| Requirement | Version | Notes |
|-------------|---------|-------|
| Docker Desktop | Latest | **Required** - All scans run via Docker |
| Python | 3.x | Optional - For HTML report generation |
| PowerShell | 5.1+ | Windows scanning |
| Bash | 4.0+ | Linux/Mac scanning |

## 🏃 Quick Start

### 1. Clone and Navigate
```bash
git clone https://github.com/cldguard/sast-scanner-dev.git
cd sast-scanner-dev
```

### 2. Verify Docker
```bash
docker --version
docker info
```

### 3. Run a Scan

**Windows:**
```powershell
.\scripts\win-scan.ps1 -Path "C:\path\to\your\project"
```

**Linux/Mac:**
```bash
./scripts/scan.sh /path/to/your/project
```

### 4. View Results
Results are saved to `../sast-scan-output/<project>-<timestamp>/`:
```
sast-scan-output/
└── myproject-20251216234329/
    ├── semgrep-results.json    # Machine-readable
    ├── semgrep-results.sarif   # IDE integration (VS Code, GitHub)
    └── semgrep-results.html    # Human-readable report
```

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [**Getting Started**](GETTING_STARTED.md) | First-time setup and quick start guide |
| [**Integration Guide**](docs/INTEGRATION.md) | CI/CD integration, Makefile examples |
| [**Security Policy**](SECURITY.md) | Vulnerability reporting, security practices |
| [**API Reference**](api/openapi.yaml) | OpenAPI specification for automation |
| [**Changelog**](CHANGELOG.md) | Version history and updates |

## 🔧 Scan Options

### Command Line Arguments

| Option | Description | Example |
|--------|-------------|---------|
| `--std-output` | Use standardized output directory | `./scripts/scan.sh --std-output` |
| `--output-dir` | Custom output directory | `./scripts/scan.sh --output-dir ./results` |
| `--json` | JSON output format | `./scripts/scan.sh --json` |
| `--output` | Custom output filename | `./scripts/scan.sh --output scan.json` |

### PowerShell Parameters

```powershell
.\scripts\win-scan.ps1 -Path "C:\project" -Severity "HIGH,CRITICAL"
```

## 🏥 Health Checks

The scanner performs automatic health verification:

```
=== Docker Health Check ===
Checking Docker availability...
  Docker Server version: 28.5.1      ✓
Verifying Docker daemon is responsive...
  Docker daemon is running: v28.5.1  ✓
Checking Semgrep image availability...
  Semgrep image found: returntocorp/semgrep:latest ✓
=== Health Check PASSED ===
```

## 📊 Understanding Results

### Exit Codes

| Code | Meaning | Action |
|------|---------|--------|
| `0` | No security issues | ✅ Safe to proceed |
| `1` | Security issues found | ⚠️ Review and remediate |

### Severity Levels

| Level | Description | SLA |
|-------|-------------|-----|
| **CRITICAL** | Exploitable vulnerability | Fix immediately |
| **HIGH** | Significant security risk | Fix before release |
| **MEDIUM** | Potential security concern | Plan remediation |
| **LOW** | Minor security consideration | Fix when convenient |

### Completion Sentinels

For CI/CD integration, scripts emit:
- `[[CLINE:DONE]] Security scan` - Scan passed
- `[[CLINE:FAIL]] Security scan` - Issues detected

## 🗂️ Project Structure

```
sast-scanner-dev/
├── scripts/                    # Scanning scripts
│   ├── scan.sh                 # Bash scanner (Docker-only)
│   ├── win-scan.ps1            # PowerShell scanner
│   ├── create_output_dir.sh    # Output directory helper
│   ├── Create-OutputDir.ps1    # PowerShell output helper
│   └── vulns-to-html.py        # HTML report generator
├── docs/                       # Documentation
│   └── INTEGRATION.md          # CI/CD integration
├── api/                        # API specifications
│   └── openapi.yaml            # OpenAPI 3.0 spec
├── examples/                   # Example configurations
│   └── Makefile.example        # Makefile integration
├── phases/                     # Development phases
├── rules/                      # Project rules and policies
├── release/                    # Release artifacts
├── Makefile.security           # Security make targets
├── SECURITY.md                 # Security policy
├── CHANGELOG.md                # Version history
├── GETTING_STARTED.md          # Quick start guide
└── README.md                   # This file
```

## 🔌 Integration

### Makefile

Include in your project's Makefile:

```makefile
include path/to/sast-scanner/Makefile.security

# Run security scan
scan:
	@$(MAKE) -f Makefile.security security-scan
```

### GitHub Actions

```yaml
- name: Run SAST Scan
  run: |
    ./scripts/scan.sh --std-output ${{ github.workspace }}
  
- name: Upload SARIF
  uses: github/codeql-action/upload-sarif@v2
  with:
    sarif_file: ../sast-scan-output/*/semgrep-results.sarif
```

### GitLab CI

```yaml
sast:
  image: docker:latest
  services:
    - docker:dind
  script:
    - ./scripts/scan.sh --std-output .
  artifacts:
    reports:
      sast: sast-scan-output/*/semgrep-results.sarif
```

## 🐳 Docker-Only Policy

> **Important**: This project mandates Docker for all Semgrep execution.


This ensures consistent behavior and version parity across all environments.

## 🆘 Troubleshooting

### Docker Not Running
```
ERROR: Docker is not available
```
**Solution**: Start Docker Desktop → Verify with `docker info`

### Permission Denied
```
Error writing HTML report: Permission denied
```
**Solution**: Check write permissions on output directory

### Slow First Scan
First scan pulls the Semgrep image (~400MB). Subsequent scans use cache.

### Windows Path Issues
Use PowerShell script for Windows paths:
```powershell
.\scripts\win-scan.ps1 -Path "D:\Projects\myapp"
```

## 📝 Version

**Current Version**: See [VERSION](release/sast-scanner/VERSION)

## 📜 License

MIT License - See [LICENSE](LICENSE) for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Run security scan on your changes
4. Submit a pull request

## 🔗 Links

- [Semgrep Documentation](https://semgrep.dev/docs)
- [SARIF Specification](https://sarifweb.azurewebsites.net/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop)
