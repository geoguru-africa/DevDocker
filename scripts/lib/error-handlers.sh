#!/bin/bash
# error-handlers.sh - Error detection and handling functions for DevDocker
# Provides functions to detect and handle common error conditions

# Source logging library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"

# Check if a volume mount exists and is accessible
check_volume_mount() {
    local mount_path=$1
    local mount_name=$2
    
    log_debug "Checking volume mount: $mount_name at $mount_path"
    
    if [ ! -d "$mount_path" ]; then
        log_error "Volume mount failed: $mount_name"
        log_error "  Expected path: $mount_path"
        log_error "  Directory does not exist"
        return 1
    fi
    
    # Check if directory is accessible
    if [ ! -r "$mount_path" ]; then
        log_error "Volume mount not readable: $mount_name"
        log_error "  Path: $mount_path"
        log_error "  Permission denied"
        return 1
    fi
    
    # Check if directory is writable (for non-read-only mounts)
    if [ ! -w "$mount_path" ]; then
        log_warning "Volume mount is read-only: $mount_name"
        log_warning "  Path: $mount_path"
        log_warning "  This may be intentional for read-only mounts"
    fi
    
    log_debug "Volume mount OK: $mount_name"
    return 0
}

# Check if a port is available
check_port_available() {
    local port=$1
    local service_name=$2
    
    log_debug "Checking if port $port is available for $service_name"
    
    # Check if port is already in use
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        log_error "Port conflict detected: $service_name"
        log_error "  Port $port is already in use"
        log_error "  Another service may be using this port"
        log_error "Solution: Stop the conflicting service or change the port mapping in docker-compose.yml"
        return 1
    fi
    
    log_debug "Port $port is available for $service_name"
    return 0
}

# Check disk space availability
check_disk_space() {
    local path=$1
    local min_space_mb=${2:-1024}  # Default: 1GB minimum
    local service_name=${3:-"service"}
    
    log_debug "Checking disk space for $service_name at $path (minimum: ${min_space_mb}MB)"
    
    # Get available space in MB
    local available_space=$(df -m "$path" 2>/dev/null | awk 'NR==2 {print $4}')
    
    if [ -z "$available_space" ]; then
        log_warning "Could not determine disk space for $path"
        return 0  # Don't fail if we can't determine space
    fi
    
    if [ "$available_space" -lt "$min_space_mb" ]; then
        log_error "Insufficient disk space for $service_name"
        log_error "  Path: $path"
        log_error "  Available: ${available_space}MB"
        log_error "  Required: ${min_space_mb}MB"
        log_error "Solution: Free up disk space or use a different volume location"
        return 1
    fi
    
    log_debug "Disk space OK: ${available_space}MB available for $service_name"
    return 0
}

# Check if Maven repository is accessible
check_maven_repository() {
    local repo_path="${1:-/root/.m2/repository}"
    
    log_debug "Checking Maven repository at $repo_path"
    
    if [ ! -d "$repo_path" ]; then
        log_error "Maven repository not found: $repo_path"
        log_error "Solution: Ensure Maven repository volume is properly mounted"
        return 1
    fi
    
    # Check if repository is writable
    if [ ! -w "$repo_path" ]; then
        log_error "Maven repository is not writable: $repo_path"
        log_error "Solution: Check volume mount permissions"
        return 1
    fi
    
    # Check disk space (Maven repos can get large)
    check_disk_space "$repo_path" 2048 "Maven repository" || return 1
    
    log_debug "Maven repository OK"
    return 0
}

# Check if source code directory is mounted and contains expected files
check_source_code_mount() {
    local project_name=$1
    local project_path=$2
    local required_file=${3:-"pom.xml"}  # Default: check for pom.xml
    
    log_debug "Checking source code mount for $project_name at $project_path"
    
    if [ ! -d "$project_path" ]; then
        log_warning "Source code directory not found: $project_name"
        log_warning "  Expected path: $project_path"
        log_warning "  This is optional if you're not working on $project_name"
        return 0  # Not an error - source code mounts are optional
    fi
    
    # Check if directory contains expected files
    if [ ! -f "$project_path/$required_file" ]; then
        log_warning "Source code directory exists but appears incomplete: $project_name"
        log_warning "  Path: $project_path"
        log_warning "  Missing: $required_file"
        log_warning "  Ensure you've cloned the repository correctly"
        return 0  # Warning only
    fi
    
    log_debug "Source code mount OK: $project_name"
    return 0
}

# Check if SSH keys are configured
check_ssh_keys() {
    local ssh_dir="${1:-/root/.ssh}"
    local authorized_keys="$ssh_dir/authorized_keys"
    
    log_debug "Checking SSH keys at $ssh_dir"
    
    if [ ! -d "$ssh_dir" ]; then
        log_error "SSH directory not found: $ssh_dir"
        log_error "Solution: Ensure SSH keys are properly mounted"
        return 1
    fi
    
    if [ ! -f "$authorized_keys" ]; then
        log_warning "SSH authorized_keys file not found"
        log_warning "  Path: $authorized_keys"
        log_warning "  SSH access will not work until you add your public key"
        log_warning "Solution: Add your public key to ./ssh-keys/authorized_keys on the host"
        return 0  # Warning only - container can still function
    fi
    
    # Check if authorized_keys has any keys
    local key_count=$(grep -c "^ssh-" "$authorized_keys" 2>/dev/null || echo "0")
    if [ "$key_count" -eq 0 ]; then
        log_warning "No SSH keys found in authorized_keys"
        log_warning "  Path: $authorized_keys"
        log_warning "  SSH access will not work"
        return 0  # Warning only
    fi
    
    log_debug "SSH keys OK: $key_count key(s) configured"
    return 0
}

# Check if GeoServer data directory is initialized
check_data_directory() {
    local data_dir="${1:-/opt/geoserver/data_dir}"
    
    log_debug "Checking GeoServer data directory at $data_dir"
    
    if [ ! -d "$data_dir" ]; then
        log_warning "GeoServer data directory not found: $data_dir"
        log_warning "  Will be initialized on first run"
        return 0  # Not an error - will be created
    fi
    
    # Check if data directory appears to be initialized
    if [ ! -f "$data_dir/global.xml" ]; then
        log_warning "GeoServer data directory exists but appears uninitialized"
        log_warning "  Path: $data_dir"
        log_warning "  Missing: global.xml"
        log_warning "  Will be initialized on first run"
        return 0  # Warning only
    fi
    
    log_debug "GeoServer data directory OK"
    return 0
}

# Check if a process is running
check_process_running() {
    local process_name=$1
    local pid_file=$2
    
    log_debug "Checking if $process_name is running"
    
    if [ -n "$pid_file" ] && [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p "$pid" > /dev/null 2>&1; then
            log_debug "$process_name is running (PID: $pid)"
            return 0
        else
            log_warning "$process_name PID file exists but process is not running"
            log_warning "  PID file: $pid_file"
            log_warning "  Stale PID: $pid"
            return 1
        fi
    fi
    
    # Check by process name
    if pgrep -f "$process_name" > /dev/null 2>&1; then
        log_debug "$process_name is running"
        return 0
    else
        log_debug "$process_name is not running"
        return 1
    fi
}

# Validate environment variables
validate_environment() {
    log_debug "Validating environment variables"
    
    # Check CUSTOM_GEOTOOLS flag
    if [ -n "$CUSTOM_GEOTOOLS" ] && [ "$CUSTOM_GEOTOOLS" != "true" ] && [ "$CUSTOM_GEOTOOLS" != "false" ]; then
        log_warning "Invalid CUSTOM_GEOTOOLS value: $CUSTOM_GEOTOOLS"
        log_warning "  Expected: true or false"
        log_warning "  Defaulting to: false"
        export CUSTOM_GEOTOOLS=false
    fi
    
    # Check CUSTOM_GEOWEBCACHE flag
    if [ -n "$CUSTOM_GEOWEBCACHE" ] && [ "$CUSTOM_GEOWEBCACHE" != "true" ] && [ "$CUSTOM_GEOWEBCACHE" != "false" ]; then
        log_warning "Invalid CUSTOM_GEOWEBCACHE value: $CUSTOM_GEOWEBCACHE"
        log_warning "  Expected: true or false"
        log_warning "  Defaulting to: false"
        export CUSTOM_GEOWEBCACHE=false
    fi
    
    # Check GEOSERVER_DATA_DIR
    if [ -z "$GEOSERVER_DATA_DIR" ]; then
        log_warning "GEOSERVER_DATA_DIR not set"
        log_warning "  Defaulting to: /opt/geoserver/data_dir"
        export GEOSERVER_DATA_DIR=/opt/geoserver/data_dir
    fi
    
    log_debug "Environment validation complete"
    return 0
}

# Run all startup checks
run_startup_checks() {
    log_info "Running startup checks..."
    
    local checks_failed=0
    
    # Validate environment variables
    validate_environment || ((checks_failed++))
    
    # Check critical volume mounts
    check_volume_mount "/workspace" "workspace" || ((checks_failed++))
    check_volume_mount "/root" "home directory" || ((checks_failed++))
    
    # Check Maven repository
    check_maven_repository || ((checks_failed++))
    
    # Check source code mounts (warnings only)
    check_source_code_mount "GeoServer" "/workspace/geoserver" "pom.xml"
    check_source_code_mount "GeoTools" "/workspace/geotools" "pom.xml"
    check_source_code_mount "GeoWebCache" "/workspace/geowebcache" "pom.xml"
    
    # Check SSH keys (warning only)
    check_ssh_keys
    
    # Check data directory (warning only)
    check_data_directory
    
    # Check disk space for critical paths
    check_disk_space "/workspace" 5120 "workspace" || ((checks_failed++))
    check_disk_space "/root" 2048 "home directory" || ((checks_failed++))
    
    if [ "$checks_failed" -gt 0 ]; then
        log_error "Startup checks failed: $checks_failed critical error(s)"
        log_error "Container may not function correctly"
        return 1
    else
        log_success "All startup checks passed"
        return 0
    fi
}

# Handle build errors
handle_build_error() {
    local project_name=$1
    local exit_code=$2
    local log_file=$3
    
    log_error "$project_name build failed with exit code $exit_code"
    
    if [ -n "$log_file" ] && [ -f "$log_file" ]; then
        log_error "Build log: $log_file"
        
        # Extract last 20 lines of error output
        log_error "Last 20 lines of build output:"
        tail -n 20 "$log_file" | while IFS= read -r line; do
            log_error "  $line"
        done
    fi
    
    log_info "Common build issues:"
    log_info "  - Missing dependencies: Check Maven repository and network connectivity"
    log_info "  - Compilation errors: Check Java version compatibility"
    log_info "  - Out of memory: Increase Docker memory limits"
    log_info "  - Disk space: Check available disk space"
    
    return "$exit_code"
}

# Cleanup on error
cleanup_on_error() {
    log_warning "Performing error cleanup..."
    
    # Stop any running processes
    if check_process_running "catalina" "/usr/local/tomcat/temp/catalina.pid"; then
        log_info "Stopping Tomcat..."
        /usr/local/tomcat/bin/catalina.sh stop 2>/dev/null || true
    fi
    
    # Clean up temporary files
    if [ -d "/tmp/devdocker-temp" ]; then
        log_info "Cleaning up temporary files..."
        rm -rf /tmp/devdocker-temp
    fi
    
    log_info "Cleanup complete"
}

# Set up error trap
setup_error_trap() {
    trap 'cleanup_on_error' ERR EXIT
}
