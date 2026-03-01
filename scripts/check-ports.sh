#!/bin/bash
# check-ports.sh - Check if required ports are available
# This script should be run before starting services to detect port conflicts

# Source logging library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logging.sh"

log_info "Checking port availability..."

# Ports to check (container-side ports)
PORTS=(
    "22:SSH"
    "5005:JDWP Debug"
    "8080:GeoServer"
    "8000:Documentation Server"
)

CONFLICTS=0

for port_info in "${PORTS[@]}"; do
    IFS=':' read -r port service <<< "$port_info"
    
    # Check if port is in use
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        log_error "Port conflict: $service (port $port) is already in use"
        CONFLICTS=$((CONFLICTS + 1))
    else
        log_debug "Port $port available for $service"
    fi
done

if [ $CONFLICTS -gt 0 ]; then
    log_error "Found $CONFLICTS port conflict(s)"
    log_error "Solution: Stop conflicting services or change port mappings in docker-compose.yml"
    exit 1
else
    log_success "All required ports are available"
    exit 0
fi
