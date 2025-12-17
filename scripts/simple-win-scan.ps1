param (
    [Parameter(Mandatory=$true)]
    [string]$Path,
    
    [Parameter()]
    [switch]$Json,
    
    [Parameter()]
    [string]$OutputFile,
    
    [Parameter()]
    [switch]$StdOutput
)

Write-Host "Running simplified Windows security static analysis scan..."
Write-Host "Target: $Path"

# Verify path exists
if (-not (Test-Path $Path)) {
    Write-Host "ERROR: Path not found: $Path"
    exit 1
}

# Map ruleset based on default severity
$Ruleset = "p/security-audit"

# Try Docker-based scan
try {
    # Get absolute path
    $absPath = (Resolve-Path $Path).Path
    
    # Create standard output directory if requested
    $outputDir = $null
    if ($StdOutput) {
        # Source the Create-OutputDir.ps1 script
        $createOutputDirPath = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "Create-OutputDir.ps1"
        if (Test-Path $createOutputDirPath) {
            # Load the script to get access to the Create-OutputDir function
            . $createOutputDirPath
            $outputDir = Create-OutputDir -TargetPath $Path
            Write-Host "Using standardized output directory: $outputDir"
            
            # If output file is specified but not an absolute path, place it in the output directory
            if ($OutputFile -and -not [System.IO.Path]::IsPathRooted($OutputFile)) {
                $OutputFile = Join-Path -Path $outputDir -ChildPath $OutputFile
            } elseif ($Json -and -not $OutputFile) {
                # Create default JSON output file in the standardized directory
                $projectName = Split-Path -Leaf $Path
                $OutputFile = Join-Path -Path $outputDir -ChildPath "semgrep-scan-$projectName.json"
            }
        } else {
            Write-Host "Warning: Create-OutputDir.ps1 not found, using current directory"
        }
    }
    
    Write-Host "Using Docker for scanning..."
    
    # Set up command parameters
    $semgrepArgs = @(
        "--config=$Ruleset"
    )
    
    # Add JSON format if requested
    if ($Json) {
        $semgrepArgs += "--json"
        
        # If no output file is specified but JSON format is requested, create a default filename
        if (-not $OutputFile) {
            $projectName = Split-Path -Leaf $Path
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $OutputFile = "semgrep-scan-$projectName-$timestamp.json"
        }
    }
    
    # Run Docker scan
    if ($Json -and $OutputFile) {
        Write-Host "Generating JSON report to: $OutputFile"
        
        # Redirect JSON output to file
        docker run --rm -v "${absPath}:/src" returntocorp/semgrep $semgrepArgs > $OutputFile
        
        # Also run a regular scan for console output
        Write-Host "Running scan with human-readable output for console..."
        $scanOutput = docker run --rm -v "${absPath}:/src" returntocorp/semgrep --config=$Ruleset 2>&1 | Out-String
    } else {
        # Standard scan without JSON output
        $scanOutput = docker run --rm -v "${absPath}:/src" returntocorp/semgrep $semgrepArgs 2>&1 | Out-String
    }
        
    $scanResult = $LASTEXITCODE
    
    # Report results
    if ($scanResult -eq 0) {
        Write-Host "PASS: No security issues found" -ForegroundColor Green
    } else {
        Write-Host "FAIL: Security issues detected" -ForegroundColor Red
        Write-Host "Review the findings above and address identified issues"
        Write-Host ""
        Write-Host "For more details on these security issues, visit:" -ForegroundColor Yellow
        Write-Host "- Semgrep Registry: https://semgrep.dev/r"
        Write-Host "- OWASP Top Ten: https://owasp.org/Top10/"
        
        # Generate HTML report if JSON file was created
        if ($Json -and $OutputFile -and (Test-Path $OutputFile)) {
            $htmlOutputFile = $OutputFile -replace '\.json$', '.html'
            $vulnsToHtmlScript = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "vulns-to-html.py"
            
            if (Test-Path $vulnsToHtmlScript) {
                Write-Host ""
                Write-Host "Generating HTML report from JSON data..."
                
                # Verify the JSON file is valid and not empty
                try {
                    # Get the file content
                    $jsonContent = Get-Content -Path $OutputFile -Raw
                    if ($jsonContent -and $jsonContent.Trim().StartsWith("{")) {
                        # Try to parse the JSON
                        $null = $jsonContent | ConvertFrom-Json
                        
                        # If parsing succeeds, generate the HTML
                        python $vulnsToHtmlScript $OutputFile $htmlOutputFile
                        if (Test-Path $htmlOutputFile) {
                            Write-Host "HTML report generated: $htmlOutputFile" -ForegroundColor Green
                        }
                    } else {
                        Write-Host "Error: JSON file is empty or invalid" -ForegroundColor Yellow
                    }
                } catch {
                    Write-Host "Error validating or converting JSON data: $_" -ForegroundColor Yellow
                }
            }
        }
    }
    
    exit $scanResult
    
} catch {
    Write-Host "ERROR: Scan failed. Make sure Docker is running" -ForegroundColor Red
    Write-Host "Technical details: $_"
    exit 1
}
