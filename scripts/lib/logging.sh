#!/bin/bash
# logging.sh - Centralized logging library for DevDocker
# Provides consistent logging functions with log levels and file output

# Log levels
export LOG_LEVEL_DEBUG=0
export LOG_LEVEL_INFO=1
export LOG_LEVEL_WARNING=2
export LOG_LEVEL_ERROR=3

# Default log level (can be overridden by LOG_LEVEL environment variable)
export CURRENT_LOG_LEVEL=${LOG_LEVEL:-$LOG_LEVEL_INFO}

# Log directory and file
export LOG_DIR="/var/log/devdocker"
export LOG_FILE="${LOG_DIR}/devdocker.log"

# Color codes for output
export COLOR_RED='\033[0;31m'
export COLOR_GREEN='\033[0;32m'
export COLOR_YELLOW='\033[1;33m'
export COLOR_BLUE='\033[0;34m'
export COLOR_CYAN='\033[0;36m'
export COLOR_NC='\033[0m' # No Color

# Initialize logging system
init_logging() {
    # Create log directory if it doesn't exist
    mkdir -p "$LOG_DIR"
    
    # Set permissions
    chmod 755 "$LOG_DIR"
    
    # Create log file if it doesn't exist
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
}

# Get timestamp for log entries
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Log to file only (no console output)
log_to_file() {
    local level=$1
    local message=$2
    local timestamp=$(get_timestamp)
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Log debug message
log_debug() {
    local message=$1
    
    if [ "$CURRENT_LOG_LEVEL" -le "$LOG_LEVEL_DEBUG" ]; then
        echo -e "${COLOR_CYAN}[DEBUG]${COLOR_NC} $message"
        log_to_file "DEBUG" "$message"
    fi
}

# Log info message
log_info() {
    local message=$1
    
    if [ "$CURRENT_LOG_LEVEL" -le "$LOG_LEVEL_INFO" ]; then
        echo -e "${COLOR_BLUE}[INFO]${COLOR_NC} $message"
        log_to_file "INFO" "$message"
    fi
}

# Log success message
log_success() {
    local message=$1
    
    if [ "$CURRENT_LOG_LEVEL" -le "$LOG_LEVEL_INFO" ]; then
        echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_NC} $message"
        log_to_file "SUCCESS" "$message"
    fi
}

# Log warning message
log_warning() {
    local message=$1
    
    if [ "$CURRENT_LOG_LEVEL" -le "$LOG_LEVEL_WARNING" ]; then
        echo -e "${COLOR_YELLOW}[WARNING]${COLOR_NC} $message" >&2
        log_to_file "WARNING" "$message"
    fi
}

# Log error message
log_error() {
    local message=$1
    
    if [ "$CURRENT_LOG_LEVEL" -le "$LOG_LEVEL_ERROR" ]; then
        echo -e "${COLOR_RED}[ERROR]${COLOR_NC} $message" >&2
        log_to_file "ERROR" "$message"
    fi
}

# Log fatal error and exit
log_fatal() {
    local message=$1
    local exit_code=${2:-1}
    
    echo -e "${COLOR_RED}[FATAL]${COLOR_NC} $message" >&2
    log_to_file "FATAL" "$message"
    
    exit "$exit_code"
}

# Initialize logging on source
init_logging
