#!/bin/bash

# Exit on error, undefined variables and pipe failures
set -evo pipefail

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

# Main function skeleton
main() {
    touch $LOG_FILE

    # Check if the docker is running or not
    check_docker

    log_messages "INFO" "Kraken-Clean script Started" 
    log_messages "ERROR" "Kraken-Clean script Failed"
    log_messages "WARN" "Kraken-Clean script Warning"
    log_messages "SUCCESS" "Kraken-clean script Success" 
}

main 