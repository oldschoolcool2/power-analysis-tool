#!/bin/bash

#######################################################################
# Quick Test Script for Power Analysis Tool
#
# This script runs quick validation checks before deployment.
#
# Usage:
#   ./scripts/quick_test.sh
#   ./scripts/quick_test.sh --full    # Run comprehensive tests
#
# Exit codes:
#   0 - All checks passed
#   1 - Some checks failed
#######################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running full tests
FULL_TEST=false
if [[ "$1" == "--full" ]]; then
  FULL_TEST=true
fi

echo ""
echo "=============================================="
echo "  Power Analysis Tool - Quick Test Suite"
echo "=============================================="
echo ""

TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
  local test_name="$1"
  local test_command="$2"

  echo -n "Testing: $test_name... "

  if eval "$test_command" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
    return 0
  else
    echo -e "${RED}✗ FAIL${NC}"
    ((TESTS_FAILED++))
    return 1
  fi
}

# Test 1: Repository structure
run_test "Repository structure" \
  "test -f DESCRIPTION && test -f NAMESPACE && test -d R && test -d tests"

# Test 2: No legacy files
run_test "No legacy inst/app.R" \
  "! test -f inst/app.R"

# Test 3: Critical R files exist
run_test "Critical R files present" \
  "test -f R/run_app.R && test -f R/app_server.R && test -f R/app_ui.R"

# Test 4: All modules present
run_test "All analysis modules present" \
  "test -f R/mod_01_single_proportion.R && \
   test -f R/mod_02_two_group.R && \
   test -f R/mod_03_survival.R && \
   test -f R/mod_04_matched_case_control.R && \
   test -f R/mod_05_continuous.R && \
   test -f R/mod_06_non_inferiority.R && \
   test -f R/mod_08_mediation.R"

# Test 5: Validation functions exist
run_test "Validation functions present" \
  "test -f R/fct_single_proportion.R && \
   test -f R/fct_two_group.R && \
   test -f R/utils_validation.R"

# Test 6: Docker configuration valid
run_test "Docker files present" \
  "test -f Dockerfile && test -f docker-compose.yml"

# Test 7: Test suite exists
run_test "Test suite present" \
  "test -d tests/testthat && ls tests/testthat/test-*.R | wc -l | grep -q '[1-9]'"

# Test 8: Documentation exists
run_test "Documentation present" \
  "test -f README.md && test -f DEPLOYMENT_GUIDE.md && test -f IMPLEMENTATION_STATUS.md"

# Test 9: No debug cat() statements (should use logger)
if ! grep -r "cat(\"DEBUG" R/ --include="*.R" > /dev/null 2>&1; then
  echo -e "Testing: No debug cat() statements... ${GREEN}✓ PASS${NC}"
  ((TESTS_PASSED++))
else
  echo -e "Testing: No debug cat() statements... ${YELLOW}! WARNING${NC}"
  echo "  Found debug cat() statements. Should use logger::log_debug() instead."
  ((TESTS_FAILED++))
fi

# Test 10: No empty test files
EMPTY_TESTS=$(find tests/testthat -name "test-*.R" -type f -empty 2>/dev/null | wc -l)
if [ "$EMPTY_TESTS" -eq 0 ]; then
  echo -e "Testing: No empty test files... ${GREEN}✓ PASS${NC}"
  ((TESTS_PASSED++))
else
  echo -e "Testing: No empty test files... ${RED}✗ FAIL${NC}"
  echo "  Found $EMPTY_TESTS empty test file(s)"
  ((TESTS_FAILED++))
fi

# Test 11: NAMESPACE exports (count)
EXPORT_COUNT=$(grep -c "^export(" NAMESPACE 2>/dev/null || echo "0")
if [ "$EXPORT_COUNT" -ge 20 ]; then
  echo -e "Testing: NAMESPACE has exports ($EXPORT_COUNT)... ${GREEN}✓ PASS${NC}"
  ((TESTS_PASSED++))
else
  echo -e "Testing: NAMESPACE has exports ($EXPORT_COUNT)... ${YELLOW}! WARNING${NC}"
  echo "  Expected at least 20 exports, found $EXPORT_COUNT"
  echo "  Run: Rscript scripts/regenerate_namespace.R"
  ((TESTS_FAILED++))
fi

echo ""
echo "----------------------------------------------"

# Full tests (require Docker or R)
if $FULL_TEST; then
  echo ""
  echo "Running full tests (requires Docker or R)..."
  echo ""

  # Test 12: R package check (if R available)
  if command -v R > /dev/null 2>&1; then
    echo -n "Testing: R package check... "
    if R -e "devtools::check(error_on='error')" > /tmp/r_check.log 2>&1; then
      echo -e "${GREEN}✓ PASS${NC}"
      ((TESTS_PASSED++))
    else
      echo -e "${RED}✗ FAIL${NC}"
      echo "  See /tmp/r_check.log for details"
      ((TESTS_FAILED++))
    fi
  fi

  # Test 13: Docker build (if Docker available)
  if command -v docker > /dev/null 2>&1; then
    echo -n "Testing: Docker build... "
    if docker build -t power-analysis-tool:test . > /tmp/docker_build.log 2>&1; then
      echo -e "${GREEN}✓ PASS${NC}"
      ((TESTS_PASSED++))

      # Test 14: Docker run
      echo -n "Testing: Docker run... "
      CONTAINER_ID=$(docker run -d -p 13838:3838 power-analysis-tool:test)
      sleep 10  # Wait for app to start

      if curl -f http://localhost:13838 > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((TESTS_PASSED++))
      else
        echo -e "${RED}✗ FAIL${NC}"
        ((TESTS_FAILED++))
      fi

      # Cleanup
      docker stop "$CONTAINER_ID" > /dev/null 2>&1
      docker rm "$CONTAINER_ID" > /dev/null 2>&1
    else
      echo -e "${RED}✗ FAIL${NC}"
      echo "  See /tmp/docker_build.log for details"
      ((TESTS_FAILED++))
    fi
  fi
fi

echo ""
echo "=============================================="
echo "  RESULTS"
echo "=============================================="
echo ""
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ All tests passed!${NC}"
  echo ""
  echo "Ready for deployment ✓"
  echo ""
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  echo ""
  echo "Fix the issues above before deploying"
  echo ""
  exit 1
fi
