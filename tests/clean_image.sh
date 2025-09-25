#!/bin/bash

# Exit on error, undefined variables and pipe failures
set -euo pipefail

# Path to kraken-clean script
SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)/kraken-clean.sh"

# Test prefix for testing
TEST_PREFIX="test-kraken-$$-$(date +%s)"
TEST_IMAGE_NAME="${TEST_PREFIX}:latest" # Default prefix image pass it without -p flag
RANDOM_TEST_IMAGE="random-$RANDOM:latest" # Random prefix image pass it with -p flag 

echo "Pull the official hello-world image for testing..."
docker pull hello-world >/dev/null # Supress the output

echo "tagging the image as ${TEST_IMAGE_NAME} and ${RANDOM_TEST_IMAGE}"
docker tag hello-world "$TEST_IMAGE_NAME"
docker tag hello-world "$RANDOM_TEST_IMAGE"

echo "Verify the tagged image..."
docker images | grep "$TEST_PREFIX" || { echo "Test image is not found"; exit 1; }

echo "Running kraken-clean in DRY-MODE..." 
"$SCRIPT" -d images || true

echo "Running kraken-clean for actual cleanup for default prefix..."
"$SCRIPT" images 

echo "Running kraken-clean for actual cleanup for random prefix..."
"$SCRIPT" -p "random-" images 

echo "Verifying Cleanup..."
if docker images | grep -q "${TEST_PREFIX}"; then
    echo "Cleanup failed: Prefixed image still exists."
    exit 1 
fi

if docker images | grep -q "${RANDOM_TEST_IMAGE%%:*}"; then
    echo "Cleanup failed: Random test-prefixed image still exists."
    exit 1
fi

echo "Kraken-Clean Passed" 