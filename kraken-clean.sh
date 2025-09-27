#!/bin/bash

# Exit on error, undefined variables and pipe failures
set -euo pipefail

# Color Codes
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
declare -g VERBOSE=true 
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

usage() {
    cat <<EOF 
Usage: $0 [options] <command>

Commands:
    images           Clean images matching with the configured tag prefix
Options:
    -d | --dry-run    Show what would be removed (no destruction)
    -p | --prefix     Set the prefix
    -v | --verbose    Verbose logging to console
    -f | --force      Force remove images 
    -h | --help       Help
EOF
    exit 0 
}

# Function to check if docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then 
        log_messages "ERROR" "Docker is not running or not accessable"
        print_color "$RED" "ERROR: Docker is not running or not accessable" 
        exit 1
    fi
}

clean_volumes() {
    print_color "$BLUE" "Cleaning volumes with prefix: $DEFAULT_TAG_PREFIX" 

    # Get volume references
    local -a volume_refs=()
    mapfile -t volume_refs < <(docker volume ls --quite | grep "^$DEFAULT_TAG_PREFIX" || true) 

    # Print detailed information about the volumes
    if [[ "$VERBOSE" == true ]]; then 
        print_color "$BLUE" "Volume candidates to process:"
        for volume_ref in "${volume_refs[@]}"; do 
            if [[ -n "$volume_ref" ]]; then 
                local volume_name
                set +e 
                volume_name=$(docker volume inspect "$volume_ref" --format '{{.Driver}} - {{.Mountpoint}}' 2>/dev/null || echo "unknown")  
                print_color "$BLUE" "- $volume_ref ($volume_name)"
                set -e 
            fi 
        done 
    fi 

    # No volumes found 
    if (( ${#volume_refs[@]} == 0 )); then 
        print_color "$YELLOW" "No volumes found with the prefix: $DEFAULT_TAG_PREFIX" 
        return 0 
    fi 

    local count=0 # Keeps track of the volumes

    # Just show don't delete
    if [[ "$DRY_RUN" == true ]]; then
        for volume_ref in "${volume_refs[@]}"; do 
            if [[ -n "$volume_ref" ]]; then 
                print_color "$YELLOW" "[DRY RUN] would remove volume: $volume_ref"
                ((count++))
            fi 
        done 
    else
        # Actually delete volumes
        for volume_ref in "${volume_refs[@]}"; do
            if [[ -n "$volume_ref" ]]; then 
                print_color "$GREEN" "Removing volume: $volume_ref" 

                # Don't show mercy 
                if [[ "$FORCE" == true ]]; then 
                    set +e 
                    docker volume rm -f "$volume_ref" >/dev/null 2>&1 || {
                        log_messages "ERROR" "Failed to remove volume: $volume_ref"
                        continue 
                    }
                    set -e 
                # Show some mercy 
                else 
                    set +e 
                    docker volume rm "$volume_ref" >/dev/null 2>&1 || {
                        log_messages "ERROR" "Failed to remove volume: $volume_ref" 
                        continue
                    }
                    set -e 
                fi 
                ((count++)) 
            fi 
        done 
    fi 

    log_messages "SUCCESS" "Processed $count volumes" 
    print_color "$GREEN" "Processed $count volumes"

}

clean_containers() {
    print_color "$BLUE" "Cleaning Containers with prefix: '$DEFAULT_TAG_PREFIX'" 

    # Get container references (container id) with matching prefix; headerless format avoids filtering the header
    local -a container_refs=()
    mapfile -t container_refs < <(docker ps -a --format "{{.ID}} {{.Names}}" | awk -v prefix="$DEFAULT_TAG_PREFIX" '$2 ~ prefix {print $1}' || true)

    # print detailed information about the containers
    if [[ "$VERBOSE" == true ]]; then
        print_color "$BLUE" "Container candidates to process:" 
        for container_id in "${container_refs[@]}"; do 
            if [[ -n "$container_id" ]]; then
                local container_name
                set +e
                container_name=$(docker inspect --format '{{.Name}}' "$container_id" 2>/dev/null | sed 's|^/||' || echo "unknown")
                print_color "$BLUE" " - $container_id ($container_name)" 
            fi 
            set -e 
        done 
    fi 

    # No containers found 
    if (( ${#container_refs[@]} == 0 )) || [[ -z "${container_refs[0]:-}" ]]; then 
        print_color "$YELLOW" "No containers found with the prefix: $DEFAULT_TAG_PREFIX"
        return 0 
    fi 

    local count=0  # Keeps track of the containers

    # Just show don't delete 
    if [[ "$DRY_RUN" == true ]]; then 
        for container_id in "${container_refs[@]}"; do 
            if [[ -n "$container_id" ]]; then 
                local container_name
                set +e
                container_name=$(docker inspect --format '{{.Name}}' "$container_id" 2>/dev/null | sed 's|^/||' || echo "unknown")
                print_color "$YELLOW" "[DRY RUN] Would remove container: $container_id ($container_name)"
                ((count++))
            fi 
            set -e
        done 
    else 
        # just deletes never shows which one is getting deleted
        for container_id in "${container_refs[@]}"; do 
            if [[ -n "$container_id" ]]; then
                local container_name 
                set +e
                container_name=$(docker inspect --format '{{.Name}}' "$container_id" 2>/dev/null | sed 's|^/||' || echo "unknown")
                print_color "$GREEN" "Removing container: $container_id ($container_name)"

                # No mercy on containers 
                if [[ "$FORCE" == true ]]; then 
                    docker rm -f "$container_id" >/dev/null 2>&1 || {
                        log_messages "ERROR" "Failed to remove container: $container_id ($container_name)"
                        continue
                    }
                # Have some mercy on containers
                else
                    docker rm "$container_id" >/dev/null 2>&1 || {
                        log_messages "ERROR" "Failed to remove container: $container_id ($container_name)" 
                        continue 
                    }
                fi 
                ((count++))
            fi 
            set -e
        done 
    fi 

    log_messages "SUCCESS" "Processed $count containers"
    print_color "$GREEN" "Processed $count conatainers" 

}

# Function to clean images 
clean_images() {
    print_color "$BLUE" "Cleaning Images with prefix: $DEFAULT_TAG_PREFIX"

    # Get image references (repo:tag) with matching prefix; headerless format avoids filtering the header
    local -a image_refs=()
    mapfile -t image_refs < <(docker images --format "{{.Repository}}:{{.Tag}}" | grep "^$DEFAULT_TAG_PREFIX" || true)

    if [[ "$VERBOSE" == true ]]; then
        print_color "$BLUE" "Candidates to process:"
        for cand in "${image_refs[@]}"; do
            [[ -n "$cand" ]] && print_color "$BLUE" " - $cand"
        done
    fi

    # No images found with the given prefix
    if (( ${#image_refs[@]} == 0 )); then 
        print_color "$YELLOW" "No images found with the prefix: $DEFAULT_TAG_PREFIX"
        return 0 
    fi

    local count=0
    for image_ref in "${image_refs[@]}"; do 
        local image_name="$image_ref"

        if [[ "$DRY_RUN" == true ]]; then 
            print_color "$YELLOW" "[DRY RUN] Would remove images: $image_name"
        else 
            print_color "$GREEN" "Removing Images: $image_name"
            if [[ "$FORCE" == true ]]; then
                set +e
                docker rmi -f "$image_ref" >/dev/null 2>&1 || {
                    log_messages "ERROR" "Failed to remove image $image_name"
                    continue
                set -e
                }
            else
                set +e
                docker rmi "$image_ref" >/dev/null 2>&1 || {
                set -e
                log_messages "ERROR" "Failed to remove image $image_name" 
                continue
                }
            fi
        fi 
        ((count++))
    done 

    log_messages "SUCCESS" "Processed $count images"
    print_color "$GREEN" "Processed $count images" 
}

# Main function skeleton
main() {

    if [[ $# -eq 0 ]]; then
        usage 
    fi

    local command=""

    while [[ $# -gt 0 ]]; do 
        case $1 in 
            (-d | --dry-run)
                DRY_RUN=true
                shift
                ;;
            (-p | --prefix)
                if [[ $# -lt 2 ]]; then
                    echo "Error: --prefix requires a value"; exit $EXIT_INVALID_ARGS
                fi
                DEFAULT_TAG_PREFIX="$2"
                shift 2
                ;;
            (images)
                command="images"
                shift
                ;;
            (containers)
                command="containers"
                shift 
                ;;
            (volumes)
                command="volumes"
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
        (containers)
            clean_containers
            ;;
        (volumes)
            clean_volumes
            ;;
        (*)
            echo "Unknown Command: $command" 
            exit 1 
            ;;
    esac 

    log_messages "SUCCESS" "Kraken-clean script completed"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi  