#!/bin/bash
# build-geoserver.sh - Build GeoServer from source
# Requirements: 11.1, 11.5

# Setup logging to file
LOG_DIR="/tmp/devdocker-logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/build-geoserver-$(date +%Y%m%d-%H%M%S).log"
LATEST_LOG="$LOG_DIR/build-geoserver-latest.log"

# Function to setup logging
setup_logging() {
    # Create symlink to latest log
    ln -sf "$LOG_FILE" "$LATEST_LOG"
    
    # Log to both file and stdout
    exec > >(tee -a "$LOG_FILE")
    exec 2>&1
    
    echo "=== Build started at $(date) ==="
    echo "Log file: $LOG_FILE"
    echo ""
}

# Call setup_logging before anything else
setup_logging

set -e  # Exit on error
set -o pipefail  # Catch errors in pipes

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if GeoServer source directory exists
GEOSERVER_DIR="/workspace/geoserver"
if [ ! -d "$GEOSERVER_DIR" ]; then
    log_error "GeoServer source directory not found: $GEOSERVER_DIR"
    log_error "Please ensure GeoServer repository is mounted at /workspace/geoserver"
    exit 1
fi

# Detect and display GeoServer version
log_info "Detecting GeoServer version..."
GEOSERVER_VERSION=$(/opt/devdocker/scripts/detect-geoserver-version.sh "$GEOSERVER_DIR")
TOMCAT_IMAGE=$(/opt/devdocker/scripts/get-tomcat-image.sh "$GEOSERVER_VERSION")
log_info "GeoServer Version: $GEOSERVER_VERSION"
log_info "Required Tomcat Image: $TOMCAT_IMAGE"
echo ""

# Check if src directory exists (GeoServer build happens in src/)
if [ ! -d "$GEOSERVER_DIR/src" ]; then
    log_error "GeoServer src directory not found: $GEOSERVER_DIR/src"
    log_error "Please ensure you have a valid GeoServer repository structure"
    exit 1
fi

# Navigate to GeoServer source directory
cd "$GEOSERVER_DIR/src"
log_info "Building GeoServer from: $GEOSERVER_DIR/src"

# Display Maven and Java versions
log_info "Build environment:"
mvn --version | head -n 3

# Start build
log_info "Starting Maven build (this may take several minutes)..."
log_info "Build command: mvn clean install -DskipTests -Dmaven.gitcommitid.skip=true -T 1C"

# Record start time
START_TIME=$(date +%s)

# Execute Maven build with error handling (skip git-commit-id-plugin for Windows mount performance)
if mvn clean install -DskipTests -Dmaven.gitcommitid.skip=true -T 1C; then
    # Calculate build duration
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    MINUTES=$((DURATION / 60))
    SECONDS=$((DURATION % 60))
    
    log_success "GeoServer build completed successfully in ${MINUTES}m ${SECONDS}s"
    
    # Locate and display WAR file location
    WAR_FILE="$GEOSERVER_DIR/src/web/app/target/geoserver.war"
    if [ -f "$WAR_FILE" ]; then
        WAR_SIZE=$(du -h "$WAR_FILE" | cut -f1)
        log_success "GeoServer WAR file created:"
        log_success "  Location: $WAR_FILE"
        log_success "  Size: $WAR_SIZE"
        echo ""
        log_info "To deploy GeoServer, run: start-geoserver.sh"
        log_info "Build log saved to: $LOG_FILE"
    else
        log_warning "Build succeeded but WAR file not found at expected location: $WAR_FILE"
        log_info "Searching for WAR file..."
        find "$GEOSERVER_DIR/src" -name "geoserver.war" -type f 2>/dev/null || log_warning "No WAR file found"
        log_info "Build log saved to: $LOG_FILE"
    fi
    
    echo ""
    echo "=== Build completed at $(date) ==="
    exit 0
else
    # Build failed
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    MINUTES=$((DURATION / 60))
    SECONDS=$((DURATION % 60))
    
    log_error "GeoServer build failed after ${MINUTES}m ${SECONDS}s"
    log_error "Check the Maven output above for details"
    log_error "Build log saved to: $LOG_FILE"
    log_info "Common issues:"
    log_info "  - Missing dependencies (check Maven repository)"
    log_info "  - Compilation errors (check Java version compatibility)"
    log_info "  - Network issues (check internet connectivity)"
    echo ""
    echo "=== Build failed at $(date) ==="
    exit 1
fi
