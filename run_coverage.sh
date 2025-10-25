#!/bin/bash

# run_coverage.sh - Wrapper script for running code coverage analysis
#
# This script provides a convenient way to run coverage analysis
# both locally and in Docker.
#
# Usage:
#   ./run_coverage.sh           # Run full coverage with HTML report
#   ./run_coverage.sh --summary # Run quick summary only
#   ./run_coverage.sh --docker  # Run in Docker container
#
# Prerequisites:
#   - R installed with covr package (local mode)
#   - Docker installed (docker mode)

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
MODE="full"
USE_DOCKER=false

for arg in "$@"; do
  case $arg in
    --summary)
      MODE="summary"
      shift
      ;;
    --docker)
      USE_DOCKER=true
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --summary    Run quick coverage summary only (no HTML report)"
      echo "  --docker     Run coverage analysis inside Docker container"
      echo "  --help, -h   Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0                      # Full coverage report (local)"
      echo "  $0 --summary            # Quick summary (local)"
      echo "  $0 --docker             # Full report in Docker"
      echo "  $0 --docker --summary   # Quick summary in Docker"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $arg${NC}"
      echo "Run '$0 --help' for usage information."
      exit 1
      ;;
  esac
done

# Banner
echo -e "${BLUE}=============================================================================${NC}"
echo -e "${BLUE}  Power Analysis Tool - Code Coverage Runner${NC}"
echo -e "${BLUE}=============================================================================${NC}"
echo ""

# Determine which script to run
if [ "$MODE" = "summary" ]; then
  SCRIPT="tests/coverage_summary.R"
  echo -e "${YELLOW}Mode: Quick Summary${NC}"
else
  SCRIPT="tests/run_coverage.R"
  echo -e "${YELLOW}Mode: Full Coverage Report${NC}"
fi

# Run based on mode
if [ "$USE_DOCKER" = true ]; then
  echo -e "${YELLOW}Environment: Docker${NC}"
  echo ""
  echo "Building development Docker image..."
  docker-compose build development || {
    echo -e "${RED}Error: Docker build failed${NC}"
    exit 1
  }

  echo ""
  echo "Running coverage analysis in Docker container..."
  docker-compose run --rm development Rscript "$SCRIPT"

else
  echo -e "${YELLOW}Environment: Local${NC}"
  echo ""

  # Check if R is installed
  if ! command -v Rscript &> /dev/null; then
    echo -e "${RED}Error: Rscript not found. Please install R.${NC}"
    exit 1
  fi

  # Check if covr is installed
  if ! Rscript -e "if (!requireNamespace('covr', quietly = TRUE)) quit(status = 1)" &> /dev/null; then
    echo -e "${YELLOW}Warning: covr package not found. Installing...${NC}"
    Rscript -e "install.packages('covr', repos = 'https://cloud.r-project.org')"
  fi

  # Check if here is installed
  if ! Rscript -e "if (!requireNamespace('here', quietly = TRUE)) quit(status = 1)" &> /dev/null; then
    echo -e "${YELLOW}Warning: here package not found. Installing...${NC}"
    Rscript -e "install.packages('here', repos = 'https://cloud.r-project.org')"
  fi

  echo "Running coverage analysis locally..."
  Rscript "$SCRIPT"
fi

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
  echo -e "${GREEN}✓ Coverage analysis completed successfully${NC}"
else
  echo -e "${RED}✗ Coverage analysis failed or coverage below threshold${NC}"
fi

echo ""

exit $EXIT_CODE
