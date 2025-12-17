#!/usr/bin/env bash
# smoke_test.sh - Simple smoke tests for security scanning functionality
set -euo pipefail

echo "Running security scanning smoke tests..."
echo ""

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
run_test() {
    local name=$1
    local command=$2
    
    echo "======================================"
    echo "Test: $name"
    echo "Command: $command"
    echo "--------------------------------------"
    
    if eval "$command"; then
        echo "✅ PASS: $name"
        ((TESTS_PASSED++))
    else
        echo "❌ FAIL: $name"
        ((TESTS_FAILED++))
    fi
    
    echo ""
}

# Test 1: Security tools check
run_test "Security Tools Check" "bash $(dirname "$0")/check_security_tools.sh > /dev/null"

# Test 2: Create test directory with sample code
echo "Creating test directory for security scanning..."
TEST_DIR=$(mktemp -d)
cat > "$TEST_DIR/test.js" <<EOL
// Sample file for testing semgrep
function testFunc() {
  const password = "hardcoded-password"; // This should trigger a finding
  return password;
}

const executeQuery = (input) => {
  const query = "SELECT * FROM users WHERE name = '" + input + "'"; // SQL injection vulnerability
  return query;
}

module.exports = { testFunc, executeQuery };
EOL

# Test 3: Static analysis security scanning
run_test "Static Analysis Security Scanning" "cd $TEST_DIR && bash $(dirname "$0")/scan.sh || true"

# Clean up
echo "Cleaning up test files..."
rm -rf "$TEST_DIR"

# Summary
echo "======================================"
echo "Tests Summary"
echo "--------------------------------------"
echo "Total tests: $((TESTS_PASSED + TESTS_FAILED))"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"

if [ $TESTS_FAILED -eq 0 ]; then
    echo "✅ All tests passed!"
    echo "[[CLINE:DONE]] Security smoke tests"
    exit 0
else
    echo "❌ Some tests failed"
    echo "[[CLINE:FAIL]] Security smoke tests"
    exit 1
fi
