#!/bin/bash 

# Exit on error, undefined variables and pipe failures
set -euo pipefail

# path to kraken-clean script
SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)/kraken-clean.sh"

source "$SCRIPT" 

# Test prefix for testing
TEST_PREFIX="test-kraken-$$-$(date +%s)"
TEST_CONTAINER_NAME="${TEST_PREFIX}-container" 
RANDOM_CONTAINER_NAME="random-$RANDOM-containe"

echo "Checking Docker container..."
check_docker

echo "Pulling the hello-world image for testing..."
docker pull hello-world >/dev/null

echo "Creating test containers: $TEST_CONTAINER_NAME and $RANDOM_CONTAINER_NAME" 
docker create --name "$TEST_CONTAINER_NAME" hello-world >/dev/null
docker create --name "$RANDOM_CONTAINER_NAME" hello-world >/dev/null

echo "Verify the create containers..."
docker ps -a --format '{{.Names}}' | grep -E "$TEST_PREFIX|$RANDOM_CONTAINER_NAME" || {
    echo "Test containers are not created"; exit 1;
}

echo "Running kraken-clean in DRY-MODE for containers..."
"$SCRIPT" -d containers || true 

echo "Running kraken-clean without DRY-MODE for containers..."
"$SCRIPT" containers || true 

echo "Running kraken-clean with giving some prefix..."
"$SCRIPT" -p "random-" containers