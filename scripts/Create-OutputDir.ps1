# Helper script to create standardized output directory for security scan results

function Get-RepositoryName {
    param (
        [Parameter()]
        [string]$Path = "."
    )

    # Normalize the path
    $fullPath = Resolve-Path $Path -ErrorAction SilentlyContinue
    if (-not $fullPath) {
        $fullPath = $Path
    }

    # If the path is a file, get its directory
    if (Test-Path $fullPath -PathType Leaf) {
        $fullPath = Split-Path -Parent $fullPath
    }
    
    # Try to get git info if the directory is a git repository
    if (Test-Path $fullPath) {
        $originalLocation = Get-Location
        Set-Location $fullPath
        
        if (Get-Command git -ErrorAction SilentlyContinue) {
            try {
                # Check if current directory is a git repository
                $gitStatus = git rev-parse --is-inside-work-tree 2>$null
                if ($LASTEXITCODE -eq 0 -and $gitStatus -eq "true") {
                    $repoUrl = git config --get remote.origin.url
                if ($repoUrl) {
                    # Extract repo name from URL (works with https or ssh URLs)
                    Set-Location $originalLocation
                    if ($repoUrl -match '.*[:/]([^/]+?)(\.git)?/?$') {
                        # Remove .git suffix if present
                        $repoName = $Matches[1] -replace '\.git$', ''
                        return $repoName
                    }
                }
                }
            }
            catch {
                # Silently continue if git command fails
            }
        }
        
        # Return to original location
        Set-Location $originalLocation
    }
    
    # Fallback: use directory name from the path
    return (Split-Path -Leaf $fullPath)
}

function Create-OutputDir {
    param (
        [Parameter()]
        [string]$TargetPath = "."
    )
    
    # Get repository name from the target path being scanned
    $repoName = Get-RepositoryName -Path $TargetPath
    
    # Get current timestamp
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    
    # Construct output directory path
    $outputDir = Join-Path -Path ".." -ChildPath "sast-scan-output"
    $outputDir = Join-Path -Path $outputDir -ChildPath "$repoName-$timestamp"
    
    # Create directory if it doesn't exist
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Return the created directory path
    return $outputDir
}

# If script is executed directly (not sourced)
if ($MyInvocation.InvocationName -ne ".") {
    # If a path argument was provided, use it
    if ($args.Count -gt 0) {
        Create-OutputDir -TargetPath $args[0]
    } else {
        Create-OutputDir
    }
}
