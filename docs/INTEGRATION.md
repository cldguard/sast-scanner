# Integration Guide

How to integrate sast-scanner security tooling into your service.

## Quick Start

### 1. Update Service Makefile

Add to the top of your service's `Makefile`:

```makefile
SHELL := /bin/bash

# Include shared security targets
include ../sast-scanner/Makefile.security

.PHONY: check contracts health test semgrep scan release

check:
	@echo "Running checks..."
	# Your check commands

contracts:
	@bash scripts/validate_contracts.sh || true

health:
	@bash scripts/health.sh || true

test:
	@bash tests/smoke.sh || true

# scan targets now provided by Makefile.security

release:
	@bash scripts/release.sh || true
```

### 2. Update Devcontainer Configuration

Update your service's `.devcontainer/devcontainer.json`:

```json
{
  "name": "sast-scanner",
  "extends": "../../sast-scanner/.devcontainer/devcontainer-base.json",
  "dockerComposeFile": "../docker-compose.yml",
  "service": "your-service",
  "workspaceFolder": "/workspace"
}
```

**Note**: The `extends` property inherits all features from the base config, including Semgrep.

### 3. Update Phase 5 Script

Simplify your `phase5_security.sh`:

```bash
#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "Running Phase 5 security scans..."

# Tools are already available via devcontainer or shared scripts
make scan

echo "[[CLINE:DONE]] Phase 5 security"
```

### 4. Remove Duplicate Scripts

Delete these files from your service (now provided by sast-scanner):
- `scripts/scan.sh`
- Any tool installation scripts

## Advanced Usage

### Custom Security Configuration

If your service needs custom scanning behavior, you can override targets:

```makefile
include ../sast-scanner/Makefile.security

# Override scan target for custom configuration
scan:
	@echo "Running custom vulnerability scan..."
	semgrep ci --sarif --sarif-output=semgrep.sarif --exit-code 1 .
```

### Additional Security Checks

Extend the security suite:

```makefile
include ../sast-scanner/Makefile.security

# Add service-specific security check
check-secrets:
	@echo "Checking for exposed secrets..."
	@bash scripts/detect_secrets.sh

# Override security-full to include custom checks
security-full: check-security-tools check-secrets semgrep scan
	@echo "✓ Complete security suite finished"
```

### Docker Image Scanning

For services that build Docker images:

```makefile
include ../sast-scanner/Makefile.security

scan-images:
	@echo "Scanning Docker images..."
	@for image in $$(docker images --format "{{.Repository}}:{{.Tag}}" | grep sbs-); do \
		echo "Scanning $$image..."; \
		semgrep image --severity HIGH,CRITICAL $$image; \
	done
```

## Troubleshooting

### Tools Not Found After Rebuild

If devcontainer rebuild doesn't install tools:

1. Check that `.devcontainer/devcontainer.json` properly extends the base config
2. Verify the path is correct: `../../sast-scanner/.devcontainer/devcontainer-base.json`
3. Check VS Code's devcontainer extension output for errors
4. Fallback: Run `make install-security-tools` manually

### Permission Errors

If you get permission errors when running scans:

```bash
# Or run with sudo (not recommended for regular use)
sudo make scan
```

### Docker Volume Mount Issues

If Docker-based scanning fails with volume mount errors:

```bash
# Ensure Docker is running
docker ps

# Check if current directory is accessible
docker run --rm -v "$(pwd):/test" alpine ls /test

# On Windows/WSL2, ensure path translation is correct
wsl pwd
```

### Scan Returns False Positives

If Semgrep reports vulnerabilities that don't apply:

1. Create a `.semgrepignore` file in your service root
2. Add CVE IDs to ignore (with justification comments):

```
# .semgrepignore
# CVE-2023-12345: Not applicable to our use case (dev dependency only)
CVE-2023-12345
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Security Scan

on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install security tools
        run: bash ../sast-scanner/scripts/install_security_tools.sh
      
      - name: Security scan
        run: make scan
      
```

### GitLab CI

```yaml
security:
  stage: test
  image: ubuntu:22.04
  before_script:
    - bash ../sast-scanner/scripts/install_security_tools.sh
  script:
    - make scan
```

## Best Practices

1. **Always scan in CI/CD**: Don't rely only on local scans
2. **Regular updates**: Keep Semgrep updated weekly
3. **Document exceptions**: Use `.semgrepignore` with clear justifications
4. **Monitor scan duration**: Large projects may need scanning optimizations

## Migration Checklist

- [ ] Back up existing scripts before deletion
- [ ] Update Makefile to include sast-scanner/Makefile.security
- [ ] Update devcontainer.json to extend base config
- [ ] Simplify phase5_security.sh to use Make targets
- [ ] Remove duplicate scripts (scan.sh)
- [ ] Test in devcontainer: `make check-security-tools`
- [ ] Test scanning: `make scan`
- [ ] Update service documentation
- [ ] Commit changes

## Support

For issues or questions:
1. Check this documentation first
2. Test with `make help-security` for available targets
3. File an issue with full error output and environment details
