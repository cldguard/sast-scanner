# Changelog

All notable changes to the sast-scanner module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2025-12-15

### Added
- Complete SDLC Phase execution (Phases 0-7)
- Phase completion records in `phase_completions/` directory
- Updated plan.md with Semgrep-focused SAST workflow
- Architecture diagrams in Phase 6 documentation

### Changed  
- Refined plan.md to focus on Semgrep 
- Updated project documentation alignment

### Security
- **Semgrep security gate PASSED** (Phase 5)
  - 61 files scanned with 170 rules
  - 2 ERROR-level findings in test samples (intentionally accepted)
  - 0 findings in production code
  - Docker-based Semgrep v1.144.1 verified
- Production code security verified clean
- Test sample vulnerabilities documented as accepted exceptions

### Documentation
- Full SDLC documentation trail in `phase_completions/`
- Architecture diagrams added
- API endpoint documentation validated

## [1.1.0] - 2025-12-06

### Added
- Comprehensive smoke test suite for security tools
- Docker fallback modes for all security scanners
- Enhanced security documentation in SECURITY.md
- Security pipeline flow diagrams
- Expanded test coverage for security tooling

### Changed
- Enhanced vulnerability scanning process
- Updated documentation with detailed architecture information

### Security
- Security scanning pipeline with Semgrep has passed all tests
- Implemented security gates for HIGH and CRITICAL vulnerabilities
- Added secret scanning capabilities
- Created automated testing for security tools

## [1.0.0] - 2025-01-10

### Added
- Initial shared infrastructure module
- Base devcontainer configuration with Semgrep features
- Shared security scanning scripts (scan.sh, check_security_tools.sh)
- Installation script for non-devcontainer environments
- Docker-based scanning option
- Makefile.security fragment for reusable targets
- Phase 5 Security template documentation
- Cline meta-ruleset and memory bank for AI-assisted development

### Security
- Integrated Semgrep for vulnerability scanning (HIGH/CRITICAL severity gates)
