param (
    [string]$Path = ".",
    [string]$Severity = "HIGH,CRITICAL",
    [int]$ExitCode = 1,
    [switch]$StdOutput
)

Write-Host "Running Windows security static analysis scan..."
Write-Host "Scanning directory: $Path"
Write-Host ""

# Get absolute path
$TargetPath = (Resolve-Path $Path -ErrorAction SilentlyContinue).Path
if (-not $TargetPath) {
    $TargetPath = $Path
}

# Check if path exists
if (-not (Test-Path -Path $TargetPath)) {
    Write-Host "ERROR: Path not found: $TargetPath" -ForegroundColor Red
    exit 1
}

# Create standardized output directory
$OutputDir = $null
if ($StdOutput -or $true) {
    # Source the Create-OutputDir script
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $createOutputDirScript = Join-Path $scriptDir "Create-OutputDir.ps1"
    
    if (Test-Path $createOutputDirScript) {
        . $createOutputDirScript
        $OutputDir = Create-OutputDir -TargetPath $TargetPath
        Write-Host "Using standardized output directory: $OutputDir"
    }
}

# Set up output files
$OutputFile = Join-Path $OutputDir "semgrep-results.json"
$SarifFile = Join-Path $OutputDir "semgrep-results.sarif"
$HtmlFile = Join-Path $OutputDir "semgrep-results.html"

Write-Host "JSON output: $OutputFile"
Write-Host "SARIF output: $SarifFile"
Write-Host "HTML output: $HtmlFile"
Write-Host ""

# Docker Health Check Functions
function Test-DockerAvailable {
    Write-Host "Checking Docker availability..." -ForegroundColor Cyan
    try {
        $dockerVersion = docker version --format '{{.Server.Version}}' 2>$null
        if ($LASTEXITCODE -eq 0 -and $dockerVersion) {
            Write-Host "  Docker Server version: $dockerVersion" -ForegroundColor Green
            return $true
        }
    } catch {
        # Ignore errors
    }
    Write-Host "  Docker is not available or not running" -ForegroundColor Red
    return $false
}

function Test-DockerRunning {
    Write-Host "Verifying Docker daemon is responsive..." -ForegroundColor Cyan
    try {
        $dockerInfo = docker info --format '{{.ServerVersion}}' 2>$null
        if ($LASTEXITCODE -eq 0 -and $dockerInfo) {
            Write-Host "  Docker daemon is running: v$dockerInfo" -ForegroundColor Green
            return $true
        }
    } catch {
        # Ignore errors
    }
    Write-Host "  Docker daemon is not responsive" -ForegroundColor Red
    return $false
}

function Test-SemgrepImageAvailable {
    Write-Host "Checking Semgrep image availability..." -ForegroundColor Cyan
    try {
        $imageExists = docker images returntocorp/semgrep --format '{{.Repository}}:{{.Tag}}' 2>$null | Select-Object -First 1
        if ($imageExists) {
            Write-Host "  Semgrep image found: $imageExists" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  Semgrep image not found locally, will pull on first run" -ForegroundColor Yellow
            return $true  # Docker will pull it automatically
        }
    } catch {
        return $true  # Docker will pull it automatically
    }
}

function Invoke-DockerHealthCheck {
    Write-Host ""
    Write-Host "=== Docker Health Check ===" -ForegroundColor Cyan
    
    if (-not (Test-DockerAvailable)) {
        Write-Host "FAILED: Docker is not available" -ForegroundColor Red
        return $false
    }
    
    if (-not (Test-DockerRunning)) {
        Write-Host "FAILED: Docker daemon is not running" -ForegroundColor Red
        Write-Host "Please start Docker Desktop and try again" -ForegroundColor Yellow
        return $false
    }
    
    Test-SemgrepImageAvailable | Out-Null
    
    Write-Host "=== Health Check PASSED ===" -ForegroundColor Green
    Write-Host ""
    return $true
}

# Map severity to semgrep ruleset
$Ruleset = "auto"
if ($Severity.ToLower().Contains("critical")) {
    if ($Severity.ToLower().Contains("high")) {
        $Ruleset = "p/security-audit"
    } else {
        $Ruleset = "p/security-critical"
    }
} elseif ($Severity.ToLower().Contains("high")) {
    $Ruleset = "p/security-high"
}

# Function to run semgrep with Docker
function Run-SemgrepDocker {
    param (
        [string]$TargetPath,
        [string]$OutputDir,
        [string]$JsonFile,
        [string]$SarifFile
    )
    
    Write-Host "Using Docker-based Semgrep scanner..."
    Write-Host "Docker image: returntocorp/semgrep"
    
    # Ensure output directory exists
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }
    
    try {
        # Run Docker with volume mounts for source and output
        Write-Host "Running scan..."
        docker run --rm `
            -v "${TargetPath}:/src" `
            -v "${OutputDir}:/output" `
            returntocorp/semgrep semgrep scan `
            --config=$Ruleset `
            --json-output="/output/semgrep-results.json" `
            --sarif-output="/output/semgrep-results.sarif"
        
        return $LASTEXITCODE
    }
    catch {
        Write-Host "Failed to run Docker Semgrep: $_" -ForegroundColor Red
        return -1
    }
}

# Check which tools are available and run scan
$result = -1

if (Get-Command "docker" -ErrorAction SilentlyContinue) {
    # Run Docker health check before scanning
    if (-not (Invoke-DockerHealthCheck)) {
        Write-Host "Docker health check failed. Cannot proceed with scan." -ForegroundColor Red
        exit 1
    }
    
    $result = Run-SemgrepDocker -TargetPath $TargetPath -OutputDir $OutputDir -JsonFile $OutputFile -SarifFile $SarifFile
    
    # Verify Docker is still responsive after scan (post-scan health check)
    Write-Host ""
    Write-Host "Verifying Docker post-scan..." -ForegroundColor Cyan
    if (Test-DockerRunning) {
        Write-Host "Docker is healthy after scan" -ForegroundColor Green
    } else {
        Write-Host "Warning: Docker may have become unresponsive during scan" -ForegroundColor Yellow
    }
}
else {
    Write-Host "ERROR: Docker is not available" -ForegroundColor Red
    Write-Host "Ensure Docker Desktop is running for container-based scanning"
    exit 1
}

Write-Host ""

# Generate HTML report from SARIF if it exists
if (Test-Path $SarifFile) {
    Write-Host "Generating HTML report from SARIF results..."
    $vulnsScript = Join-Path $scriptDir "vulns-to-html.py"
    
    if (Test-Path $vulnsScript) {
        python $vulnsScript $SarifFile $HtmlFile $TargetPath
        if (Test-Path $HtmlFile) {
            Write-Host "HTML report generated: $HtmlFile" -ForegroundColor Green
        }
    }
}

# Report results
if ($result -eq 0) {
    Write-Host ""
    Write-Host "Security scan passed - no security issues found" -ForegroundColor Green
    Write-Host "[[CLINE:DONE]] Security scan"
    exit 0
}
elseif ($result -gt 0) {
    Write-Host ""
    Write-Host "Security scan failed - security issues detected" -ForegroundColor Red
    Write-Host "Review the output above and:"
    Write-Host "  1. Fix the identified security issues"
    Write-Host "  2. Document accepted risks if false positives"
    Write-Host "  3. Re-run scan after remediation"
    Write-Host "[[CLINE:FAIL]] Security scan"
    exit $result
}
else {
    Write-Host ""
    Write-Host "Security scan did not complete successfully" -ForegroundColor Yellow
    exit 1
}
