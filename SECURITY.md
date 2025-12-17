# Security Documentation

This document outlines the security features and tools integrated into the `sast-scanner` project.

## Security Pipeline Overview

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

## Security Tools

### Static Analysis with Semgrep

[Semgrep](https://semgrep.dev/) is used for static application security testing (SAST):

- **Command**: `make scan` or `bash scripts/scan.sh`
- **Configuration**: 
  - Scans for HIGH and CRITICAL security issues
  - Uses exit code 1 to fail builds when issues are found
  - Uses security-focused rulesets (p/security-audit, p/security-high, etc.)
- **Fallback**: If Semgrep is not installed natively, a Docker-based fallback is used
- **Integration**: Automatically integrated in CI/CD pipeline
- **Server**: Runs on port 8501 when in server mode

```bash
# Manual security scanning
bash scripts/scan.sh
```

## Security Testing

The project includes automated security tests to ensure the security tooling functions correctly:

- **Command**: `make test` or `bash scripts/smoke_test.sh`
- **Tests**:
  - Security tools availability
  - Static analysis scanning

## Architecture and Security Flow

```
┌────────────────┐        ┌────────────────┐
│                │        │                │
│  Application   │◄──────►│  Security      │
│  Code          │        │  Scanning      │
│                │        │  (Semgrep)     │
└────────────────┘        └────────────────┘
        │                         │
        │                         │
        ▼                         ▼
┌────────────────┐
│                │
│  Scan Results  │
│  & Reports     │
│                │
└────────────────┘
```

## Security Policy

- Any HIGH or CRITICAL security issues must be fixed before merging to main
- Security scanning must be integrated into CI/CD pipelines
- Security tools should be regularly updated to latest versions

## API Integration

The security scanning tools are integrated via scripts and Makefile targets, and can be extended through the security API:

- **Check Tools**: `scripts/check_security_tools.sh`
- **Install Tools**: `scripts/install_security_tools.sh`
- **Security Scan**: `scripts/scan.sh`
- **Test Tools**: `scripts/smoke_test.sh`

