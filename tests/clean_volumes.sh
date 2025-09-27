#!/bin/bash 

set -euo pipefail 

# path to kraken-clean script 
SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)/kraken-clean.sh"

source "$SCRIPT" 

# Test prefix for scripting 
TEST_PREFIX="test-kraken-$$-$(date +%s)" 
TEST_VOLUME_NAME="${TEST_PREFIX}-volume" 
RANDOM_VOLUME_NAME="random-$RANDOM-volume"

echo "checking Docker deamon..."
check_docker

echo "Creating test volumes: $TEST_VOLUME_NAME and $RANDOM_VOLUME_NAME" 
docker volume create "$TEST_VOLUME_NAME" >/dev/null 
docker volume create "$RANDOM_VOLUME_NAME" >/dev/null

echo "Verify the created volumes..." 
docker volume ls --format '{{.Name}}' | grep -E "$TEST_PREFIX|$RANDOM_VOLUME_NAME" || {
    echo "Test volumes are not ecreated"; exit 1;
}

echo "Runnnig Kraken-clean in DRY-MODE for volumes..." 
"$SCRIPT" -d volumes || true 

echo "Running kraken-clean without DRY-MODE for volumes..."
"$SCRIPT" volumes || true 

echo "Running kraken-clean with custom prefix..."
"$SCRIPT" -p "random-" volumes 

echo "Verifying Cleanup..." 
if docker volume ls --format '{{.Name}}' | grep -q "${TEST_VOLUME_NAME}"; then
    echo "Cleanup failed"
    exit 1 
fi 