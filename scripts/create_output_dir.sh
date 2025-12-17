#!/usr/bin/env bash
# Helper script to create standardized output directory for security scan results
set -euo pipefail

# Function to get repository name from specified directory
get_repo_name() {
    local target_dir="${1:-.}"
    
    # Save current directory
    local current_dir=$(pwd)
    
    # Change to target directory if it exists and differs from current
    if [[ -d "$target_dir" && "$target_dir" != "." ]]; then
        cd "$target_dir" || return 1
    fi
    
    local repo_name=""
    
    # Try to get from git
    if command -v git &> /dev/null && git rev-parse --is-inside-work-tree &> /dev/null 2>&1; then
        local repo_url=$(git config --get remote.origin.url 2>/dev/null)
        if [[ -n "$repo_url" ]]; then
            # Extract repo name from URL (works with https or ssh URLs)
            repo_name=$(echo "$repo_url" | sed -E 's|.*[:/]([^/]+)/?\.git/?$|\1|g')
        fi
    fi
    
    # If no git info found, use directory name
    if [[ -z "$repo_name" ]]; then
        repo_name=$(basename "$(pwd)")
    fi
    
    # Return to original directory
    cd "$current_dir" || true
    
    # Return the repository name
    echo "$repo_name"
}

# Create standardized output directory
create_output_dir() {
    local target_dir="${1:-.}"
    
    # Get repository name from target directory
    local repo_name=$(get_repo_name "$target_dir")
    
    # Get current timestamp
    local timestamp=$(date +"%Y%m%d%H%M%S")
    
    # Parent directory and full output path
    local parent_dir="../sast-scan-output"
    local output_dir="${parent_dir}/${repo_name}-${timestamp}"
    
    # Check if parent directory exists, create only if it doesn't
    if [[ ! -d "$parent_dir" ]]; then
        if ! mkdir -p "$parent_dir" 2>/dev/null; then
            # Try using PowerShell for Windows
            if command -v powershell.exe &> /dev/null; then
                powershell.exe -Command "if (-not (Test-Path '$parent_dir')) { New-Item -ItemType Directory -Path '$parent_dir' }" > /dev/null 2>&1
            fi
        fi
    fi
    
    # Create the timestamped subdirectory
    if ! mkdir -p "$output_dir" 2>/dev/null; then
        # Try using PowerShell for Windows
        if command -v powershell.exe &> /dev/null; then
            powershell.exe -Command "if (-not (Test-Path '$output_dir')) { New-Item -ItemType Directory -Path '$output_dir' }" > /dev/null 2>&1
        else
            echo "Warning: Cannot create output directory $output_dir" >&2
        fi
    fi
    
    # Echo the created directory path
    echo "$output_dir"
}

# If script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -gt 0 ]]; then
        create_output_dir "$1"
    else
        create_output_dir
    fi
fi
