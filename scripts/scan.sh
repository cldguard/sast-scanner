#!/usr/bin/env bash
set -euo pipefail

# Default configuration
SEVERITY="HIGH,CRITICAL"
EXIT_CODE=1  # Fail build on findings
FORMAT="text"
OUTPUT_FILE=""
OUTPUT_DIR=""
USE_STD_OUTPUT_DIR=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --json)
      FORMAT="json"
      shift
      ;;
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      FORMAT="json"  # Force JSON/SARIF output when output directory is specified
      shift 2
      ;;
    --std-output)
      USE_STD_OUTPUT_DIR=true
      shift
      ;;
    *)
      # Assume it's the target directory
      TARGET_DIR="${1:-.}"
      shift
      ;;
  esac
done

# If TARGET_DIR wasn't set by argument parsing, default to current directory
TARGET_DIR="${TARGET_DIR:-.}"
TARGET_ABS=$(realpath "$TARGET_DIR")

echo "Running security static analysis scan..."
echo "Scanning directory: $TARGET_DIR"
echo ""

# If standard output directory is requested or no output directory is specified, create standardized directory
if [[ "$USE_STD_OUTPUT_DIR" == "true" || -z "$OUTPUT_DIR" ]]; then
  # Source the create_output_dir script
  if [[ -f "$(dirname "$0")/create_output_dir.sh" ]]; then
    source "$(dirname "$0")/create_output_dir.sh"
    
    # Get the target repository name and create the output directory
    OUTPUT_DIR=$(create_output_dir "$TARGET_ABS")
    echo "Using standardized output directory: $OUTPUT_DIR"
    FORMAT="json"  # Force JSON output when using standard directory
  else
    echo "Warning: create_output_dir.sh not found, using current directory"
  fi
fi

# If output directory is set, make sure it exists
if [[ -n "$OUTPUT_DIR" ]]; then
  if ! mkdir -p "$OUTPUT_DIR" 2>/dev/null; then
    # Try PowerShell on Windows
    if command -v powershell.exe &> /dev/null; then
      powershell.exe -Command "New-Item -ItemType Directory -Force -Path '$OUTPUT_DIR'" > /dev/null 2>&1 || true
    fi
  fi
fi

# If JSON output requested but no file specified, create standardized filename
if [[ "$FORMAT" == "json" ]]; then
  if [[ -z "$OUTPUT_FILE" ]]; then
    if [[ -n "$OUTPUT_DIR" ]]; then
      OUTPUT_FILE="${OUTPUT_DIR}/semgrep-results.json"
    else
      PROJECT_NAME=$(basename "$TARGET_ABS")
      TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
      OUTPUT_FILE="semgrep-results-${PROJECT_NAME}-${TIMESTAMP}.json"
    fi
  elif [[ -n "$OUTPUT_DIR" && "$OUTPUT_FILE" != /* && "$OUTPUT_FILE" != ~/* ]]; then
    # If output file is not an absolute path, prepend output directory
    OUTPUT_FILE="${OUTPUT_DIR}/$(basename "$OUTPUT_FILE")"
  fi
fi

# Map severity to semgrep ruleset
RULESET="auto"
case "${SEVERITY,,}" in
  *critical*)
    if [[ "${SEVERITY,,}" == *high* ]]; then
      RULESET="p/security-audit"
    else
      RULESET="p/security-critical"
    fi
    ;;
  *high*)
    RULESET="p/security-high"
    ;;
  *)
    RULESET="auto"
    ;;
esac

# Docker Health Check Functions
check_docker_available() {
    echo "Checking Docker availability..."
    if docker version --format '{{.Server.Version}}' &>/dev/null; then
        local version=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
        echo "  Docker Server version: $version"
        return 0
    else
        echo "  Docker is not available or not running"
        return 1
    fi
}

check_docker_running() {
    echo "Verifying Docker daemon is responsive..."
    if docker info --format '{{.ServerVersion}}' &>/dev/null; then
        local version=$(docker info --format '{{.ServerVersion}}' 2>/dev/null)
        echo "  Docker daemon is running: v$version"
        return 0
    else
        echo "  Docker daemon is not responsive"
        return 1
    fi
}

check_semgrep_image() {
    echo "Checking Semgrep image availability..."
    local image_exists=$(docker images returntocorp/semgrep --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | head -1)
    if [[ -n "$image_exists" ]]; then
        echo "  Semgrep image found: $image_exists"
        return 0
    else
        echo "  Semgrep image not found locally, will pull on first run"
        return 0  # Docker will pull it automatically
    fi
}

docker_health_check() {
    echo ""
    echo "=== Docker Health Check ==="
    
    if ! check_docker_available; then
        echo "FAILED: Docker is not available"
        return 1
    fi
    
    if ! check_docker_running; then
        echo "FAILED: Docker daemon is not running"
        echo "Please start Docker Desktop and try again"
        return 1
    fi
    
    check_semgrep_image
    
    echo "=== Health Check PASSED ==="
    echo ""
    return 0
}

docker_post_scan_check() {
    echo ""
    echo "Verifying Docker post-scan..."
    if check_docker_running &>/dev/null; then
        echo "Docker is healthy after scan"
        return 0
    else
        echo "Warning: Docker may have become unresponsive during scan"
        return 1
    fi
}

# Function to run semgrep with Docker
run_semgrep_docker() {
    echo "Using Docker-based Semgrep scanner..."
    echo "Docker image: returntocorp/semgrep"
    
    # For Windows paths, we need to convert backslashes to forward slashes
    local target_path="${1:-.}"
    if [[ "$target_path" == *\\* ]]; then
        target_path=$(echo "$target_path" | tr '\\' '/')
    fi
    
    if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "win"* || "$OSTYPE" == "cygwin"* || "$target_path" == *:* ]]; then
        echo "Detected Windows environment, using local scan approach..."
        
        # Create a temporary directory for scanning
        local temp_dir="./temp-scan-dir"
        mkdir -p "$temp_dir"
        echo "Created temporary directory for scanning: $temp_dir"
        
        # Copy target files to temp directory
        echo "Copying files to temporary directory..."
        # Use PowerShell to handle Windows paths better
        powershell.exe -Command "Copy-Item -Path \"$target_path/*\" -Destination \"$temp_dir/\" -Recurse -Force" 2>/dev/null || true
        
        # Run Docker using the temp directory with native SARIF output
        if [[ "$FORMAT" == "json" && -n "$OUTPUT_FILE" ]]; then
            local sarif_file="${OUTPUT_FILE%.json}.sarif"
            echo "Generating reports with native Semgrep output..."
            echo "  - JSON: $OUTPUT_FILE"
            echo "  - SARIF: $sarif_file"
            
            # Use Semgrep's native multi-output capability
            docker run --rm -v "$(pwd)/$temp_dir:/src" -v "$(pwd)/$(dirname "$OUTPUT_FILE"):/output" \
                returntocorp/semgrep semgrep scan \
                --config=$RULESET \
                --json-output="/output/$(basename "$OUTPUT_FILE")" \
                --sarif-output="/output/$(basename "$sarif_file")" \
                /src
        else
            local format_flag=""
            [[ "$FORMAT" == "json" ]] && format_flag="--json"
            docker run --rm -v "$(pwd)/$temp_dir:/src" returntocorp/semgrep semgrep scan --config=$RULESET $format_flag /src
        fi
        
        # Store exit code
        local result=$?
        
        # Clean up
        echo "Cleaning up temporary directory..."
        rm -rf "$temp_dir"
        
        # Return the exit code
        return $result
    else
        # Unix path handling - direct approach
        echo "Running Docker-based scan directly on source path..."
        
        # Run the scan with native SARIF output
        if [[ "$FORMAT" == "json" && -n "$OUTPUT_FILE" ]]; then
            local sarif_file="${OUTPUT_FILE%.json}.sarif"
            local output_dir=$(dirname "$OUTPUT_FILE")
            
            # Convert relative output_dir to absolute path for Docker volume mount
            local abs_output_dir="$output_dir"
            if [[ "$output_dir" != /* ]]; then
                # Create directory first if it doesn't exist
                mkdir -p "$output_dir" 2>/dev/null || true
                abs_output_dir=$(cd "$output_dir" 2>/dev/null && pwd)
                if [[ -z "$abs_output_dir" ]]; then
                    abs_output_dir="$(pwd)/$output_dir"
                fi
            fi
            
            # For WSL + Docker Desktop, use the WSL Linux path directly
            # Docker Desktop for Windows mounts WSL paths correctly
            local docker_output_dir="$abs_output_dir"
            
            echo "Generating reports with native Semgrep output..."
            echo "  - JSON: $OUTPUT_FILE"
            echo "  - SARIF: $sarif_file"
            echo "  - Output directory: $docker_output_dir"
            
            # Use Semgrep's native multi-output capability with absolute paths
            docker run --rm -v "$target_path:/src" -v "$docker_output_dir:/output" \
                returntocorp/semgrep semgrep scan \
                --config=$RULESET \
                --json-output="/output/$(basename "$OUTPUT_FILE")" \
                --sarif-output="/output/$(basename "$sarif_file")"
        else
            local format_flag=""
            [[ "$FORMAT" == "json" ]] && format_flag="--json"
            docker run --rm -v "$target_path:/src" returntocorp/semgrep semgrep scan --config=$RULESET $format_flag
        fi
        
        # Return the exit code
        return $?
    fi
}

# Function to run semgrep natively
run_semgrep_native() {
    echo "Using native Semgrep installation..."
    local target="${1:-.}"
    local current_dir=$(pwd)
    
    # Change to target directory
    cd "$target"
    
    # Add format if JSON
    if [[ "$FORMAT" == "json" ]]; then
        # Run and capture JSON output
        if [[ -n "$OUTPUT_FILE" ]]; then
            echo "Generating JSON report to: $OUTPUT_FILE"
            semgrep --config="$RULESET" --json > "$OUTPUT_FILE"
            
            # Also run in text format for console output
            echo "Running scan with human-readable output for console..."
            semgrep --config="$RULESET"
        else
            semgrep --config="$RULESET" --json
        fi
    else
        # Standard text format
        semgrep --config="$RULESET"
    fi
    
    # Store exit code
    local result=$?
    
    # Return to original directory
    cd "$current_dir"
    
    # Return the exit code
    return $result
}

# Display output information if applicable
if [[ "$FORMAT" == "json" && -n "$OUTPUT_FILE" ]]; then
    echo "JSON output will be saved to: $OUTPUT_FILE"
    
    # Set up HTML output file
    HTML_OUTPUT_FILE="${OUTPUT_FILE%.json}.html"
    echo "HTML report will be generated to: $HTML_OUTPUT_FILE"
fi

# RULE: Docker-only for Semgrep execution (per rules/sections/20-Generic-Rules.md)
# Do NOT use locally installed semgrep - always use Docker for consistency
if command -v docker &> /dev/null; then
    echo "Using Docker for Semgrep execution (per project rules)..."
    
    # Run Docker health check before scanning
    if ! docker_health_check; then
        echo "Docker health check failed. Cannot proceed with scan."
        exit 1
    fi
    
    run_semgrep_docker "$TARGET_ABS"
    RESULT=$?
    
    # Run post-scan health check
    docker_post_scan_check
else
    echo "ERROR: Docker is not available"
    echo ""
    echo "This project requires Docker for Semgrep execution."
    echo "Please ensure Docker Desktop is running."
    echo ""
    echo "Install Docker:"
    echo "  Windows: https://docs.docker.com/desktop/install/windows-install/"
    echo "  Mac: https://docs.docker.com/desktop/install/mac-install/"
    echo "  Linux: https://docs.docker.com/engine/install/"
    exit 1
fi

echo ""

# Generate HTML report from SARIF if it exists
SARIF_FILE="${OUTPUT_FILE%.json}.sarif"
if [[ -n "$SARIF_FILE" && -f "$SARIF_FILE" ]]; then
    HTML_OUTPUT_FILE="${OUTPUT_FILE%.json}.html"
    echo "Generating HTML report from SARIF results..."
    
    if [[ -f "$(dirname "$0")/vulns-to-html.py" ]]; then
        # Pass the scanned path to include in the HTML report
        python3 "$(dirname "$0")/vulns-to-html.py" "$SARIF_FILE" "$HTML_OUTPUT_FILE" "$TARGET_ABS"
        if [[ -f "$HTML_OUTPUT_FILE" ]]; then
            echo "HTML report generated: $HTML_OUTPUT_FILE"
        else
            echo "Failed to generate HTML report"
        fi
    else
        echo "WARNING: vulns-to-html.py not found, HTML report not generated"
    fi
elif [[ -n "$OUTPUT_FILE" ]]; then
    echo "Note: SARIF file not found at $SARIF_FILE - HTML report not generated"
fi

# Report results
if [ $RESULT -eq 0 ]; then
    echo "✓ Security scan passed - no security issues found"
    echo "[[CLINE:DONE]] Security scan"
    exit 0
else
    echo "✗ Security scan failed - security issues detected"
    echo "Review the output above and:"
    echo "  1. Fix the identified security issues"
    echo "  2. Document accepted risks if false positives"
    echo "  3. Re-run scan after remediation"
    echo "[[CLINE:FAIL]] Security scan"
    exit "$RESULT"
fi
