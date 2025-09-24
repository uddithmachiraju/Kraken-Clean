#!/bin/bash

# Exit on error, undefined variables and pipe failures
set -eo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Script Metadata
SCRIPT_NAME="kraken-clean"
SCRIPT_VERSION="0.0.1"
SCRIPT_AUTHOR="uddith machiraju"

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" 

# Configuration
LOG_FILE="${SCRIPT_DIR}/kraken-clean.log"

# Exit Codes
readonly EXIT_SUCCESS=0
readonly EXIT_ERROR=1
readonly EXIT_INVALID_ARGS=2
readonly EXIT_DOCKER_ERROR=3

# Default Configuration
DEFAULT_TAG_PREFIX="test-"

# Global Variables
declare -g DRY_RUN=false 
declare -g VERBOSE=false 
declare -g FORCE=false

# Functions to print colored outputs
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to log messages
log_messages() {
    local level=$1
    local message=$2
    local timestamp 
    timestamp=$(date '+%Y-%m-%d %H:%M:%S') 
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"

    if [[ "$VERBOSE" == true ]]; then
        case $level in 
            ("ERROR") print_color "$RED" "ERROR: $message" ;;
            ("WARN") print_color "$YELLOW" "WARNING: $message" ;;
            ("INFO") print_color "$BLUE" "INFO: $message" ;;
            ("SUCCESS") print_color "$GREEN" "SUCCESS: $message";;
        esac
    fi 
}

check_docker() {
    if ! docker info >/dev/null 2>&1; then 
        log_messages "ERROR" "Docker is not running or not accessable"
        print_color "$RED" "ERROR: Docker is not running or accessable" 
        exit 1
    fi
}

clean_images() {
    print_color "$BLUE" "Cleaning Images with prefix: $DEFAULT_TAG_PREFIX"

    # Get images with matching prefix
    local images=$(docker images --format "table {{.Repository}}:{{.Tag}}\t{{.ID}})" | grep "^$TAG_PREFIX" | awk '{print $2}' || true)

    if [[ -z $images ]]; then 
        print_color "$YELLOW" "No images found with the prefix: $DEFAULT_TAG_PREFIX"
        return 0 
    fi

    local count=0
    for image_id in $images; do 
        local image_name=$(docker inspect --format='{{index .RepoTags 0}}' "$image_id" 2>/dev/null || echo "unnamed")

        if [[ "$DRY_RUN" == true ]]; then 
            print_color "$YELLOW" "[DRY RUN] Would remove images: $image_name {image_id}"
        else 
            print_color "$GREEN" "Removing Images: $image_name"
            docker rmi "$image_id" >/dev/null 2>&1 || {
                log_messages "ERROR" "Failed to remove image $image_name" 
                continue
            }
        fi 
        ((count++))
    done 

    log_messages "SUCCESS" "Processed $count images"
    print_color "$GREEN" "Processed $count images" 
}

# Main function skeleton
main() {
    local command=""

    log_messages "ERROR" "Kraken-Clean script Failed"
    log_messages "WARN" "Kraken-Clean script Warning"
    log_messages "SUCCESS" "Kraken-clean script Success" 

    while [[ $# -gt 0 ]]; do 
        case $1 in 
            (-d | --dry-run)
                DRY_RUN=true
                shift
                ;;
            (images)
                command="images"
                shift
                ;;
            (*)
                echo "Unknown Command"
                exit 1
                ;;
        esac 
    done 

    # Check if the docker file is running or not
    check_docker 

    if [[ -z "$command" ]]; then
        command="images"
    fi

    touch $LOG_FILE  # Create the log file

    log_messages "INFO" "Kraken-Clean script Started" 

    # Execute Command 
    case "$command" in 
        (images)
            clean_images
            ;;
        (*)
            echo "Unknown Command: $command" 
            exit 1 
            ;;
    esac 

    log_messages "SUCCESS" "Kraken-clean script completed"
}

main 