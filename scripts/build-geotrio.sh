#!/bin/bash
# build-geotrio.sh - Orchestrate builds for GeoTools, GeoWebCache, and GeoServer
# Requirements: 12.1, 12.2, 12.3, 12.4, 12.5, 12.6

# Setup logging to file
LOG_DIR="/tmp/devdocker-logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/build-geotrio-$(date +%Y%m%d-%H%M%S).log"
LATEST_LOG="$LOG_DIR/build-geotrio-latest.log"

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

# Detect and display GeoServer version at the start
GEOSERVER_DIR="/workspace/geoserver"
if [ -d "$GEOSERVER_DIR" ]; then
    echo "=== GeoServer Version Detection ==="
    GEOSERVER_VERSION=$(/opt/devdocker/scripts/detect-geoserver-version.sh "$GEOSERVER_DIR" 2>/dev/null || echo "unknown")
    TOMCAT_IMAGE=$(/opt/devdocker/scripts/get-tomcat-image.sh "$GEOSERVER_VERSION" 2>/dev/null || echo "unknown")
    echo "GeoServer Version: $GEOSERVER_VERSION"
    echo "Required Tomcat Image: $TOMCAT_IMAGE"
    echo ""
fi

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

# Configuration flags (from environment variables)
CUSTOM_GEOTOOLS=${CUSTOM_GEOTOOLS:-false}
CUSTOM_GEOWEBCACHE=${CUSTOM_GEOWEBCACHE:-false}

# Workspace directories
GEOTOOLS_DIR="/workspace/geotools"
GEOWEBCACHE_DIR="/workspace/geowebcache"
GEOSERVER_DIR="/workspace/geoserver"

# Track overall build time
OVERALL_START_TIME=$(date +%s)

log_info "=== GeoTrio Build Orchestration ==="
log_info "Configuration:"
log_info "  CUSTOM_GEOTOOLS: $CUSTOM_GEOTOOLS"
log_info "  CUSTOM_GEOWEBCACHE: $CUSTOM_GEOWEBCACHE"
echo ""

# Display build environment
log_info "Build environment:"
mvn --version | head -n 3
echo ""

# Function to build a project
build_project() {
    local PROJECT_NAME=$1
    local PROJECT_DIR=$2
    
    log_info "=== Building $PROJECT_NAME ==="
    log_info "Location: $PROJECT_DIR"
    
    cd "$PROJECT_DIR"
    
    # Record start time
    local START_TIME=$(date +%s)
    
    # Execute Maven build with git-commit-id-plugin skip for Windows mount performance
    log_info "Build command: mvn clean install -DskipTests -Dmaven.gitcommitid.skip=true -T 1C"
    if mvn clean install -DskipTests -Dmaven.gitcommitid.skip=true -T 1C; then
        # Calculate build duration
        local END_TIME=$(date +%s)
        local DURATION=$((END_TIME - START_TIME))
        local MINUTES=$((DURATION / 60))
        local SECONDS=$((DURATION % 60))
        
        log_success "$PROJECT_NAME build completed successfully in ${MINUTES}m ${SECONDS}s"
        log_success "Artifacts installed to local Maven repository"
        echo ""
        return 0
    else
        # Build failed
        local END_TIME=$(date +%s)
        local DURATION=$((END_TIME - START_TIME))
        local MINUTES=$((DURATION / 60))
        local SECONDS=$((DURATION % 60))
        
        log_error "$PROJECT_NAME build failed after ${MINUTES}m ${SECONDS}s"
        log_error "Check the Maven output above for details"
        return 1
    fi
}

# Build GeoTools if custom flag is set
if [ "$CUSTOM_GEOTOOLS" = "true" ]; then
    if [ -d "$GEOTOOLS_DIR" ]; then
        build_project "GeoTools" "$GEOTOOLS_DIR"
    else
        log_error "CUSTOM_GEOTOOLS=true but GeoTools directory not found: $GEOTOOLS_DIR"
        log_error "Please ensure GeoTools repository is mounted at /workspace/geotools"
        log_error "Or set CUSTOM_GEOTOOLS=false to use GeoTools from Maven Central"
        exit 1
    fi
else
    log_info "Using GeoTools from Maven Central (CUSTOM_GEOTOOLS=false)"
    if [ -d "$GEOTOOLS_DIR" ]; then
        log_info "Note: GeoTools repository found at $GEOTOOLS_DIR but will not be built"
        log_info "      Set CUSTOM_GEOTOOLS=true to build from local source"
    fi
    echo ""
fi

# Build GeoWebCache if custom flag is set
if [ "$CUSTOM_GEOWEBCACHE" = "true" ]; then
    if [ -d "$GEOWEBCACHE_DIR" ]; then
        # Check for nested geowebcache directory structure
        if [ -d "$GEOWEBCACHE_DIR/geowebcache" ]; then
            build_project "GeoWebCache" "$GEOWEBCACHE_DIR/geowebcache"
        else
            build_project "GeoWebCache" "$GEOWEBCACHE_DIR"
        fi
    else
        log_error "CUSTOM_GEOWEBCACHE=true but GeoWebCache directory not found: $GEOWEBCACHE_DIR"
        log_error "Please ensure GeoWebCache repository is mounted at /workspace/geowebcache"
        log_error "Or set CUSTOM_GEOWEBCACHE=false to use GeoWebCache from Maven Central"
        exit 1
    fi
else
    log_info "Using GeoWebCache from Maven Central (CUSTOM_GEOWEBCACHE=false)"
    if [ -d "$GEOWEBCACHE_DIR" ]; then
        log_info "Note: GeoWebCache repository found at $GEOWEBCACHE_DIR but will not be built"
        log_info "      Set CUSTOM_GEOWEBCACHE=true to build from local source"
    fi
    echo ""
fi

# Build GeoServer
log_info "=== Building GeoServer ==="
if [ ! -d "$GEOSERVER_DIR" ]; then
    log_error "GeoServer source directory not found: $GEOSERVER_DIR"
    log_error "Please ensure GeoServer repository is mounted at /workspace/geoserver"
    exit 1
fi

if [ ! -d "$GEOSERVER_DIR/src" ]; then
    log_error "GeoServer src directory not found: $GEOSERVER_DIR/src"
    log_error "Please ensure you have a valid GeoServer repository structure"
    exit 1
fi

cd "$GEOSERVER_DIR/src"
log_info "Location: $GEOSERVER_DIR/src"

# Record start time
GEOSERVER_START_TIME=$(date +%s)

# Execute Maven build with git-commit-id-plugin skip for Windows mount performance
log_info "Build command: mvn clean install -DskipTests -Dmaven.gitcommitid.skip=true -T 1C"
if mvn clean install -DskipTests -Dmaven.gitcommitid.skip=true -T 1C; then
    # Calculate build duration
    GEOSERVER_END_TIME=$(date +%s)
    DURATION=$((GEOSERVER_END_TIME - GEOSERVER_START_TIME))
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
    else
        log_warning "Build succeeded but WAR file not found at expected location: $WAR_FILE"
    fi
    echo ""
    
    # Calculate overall build time
    OVERALL_END_TIME=$(date +%s)
    OVERALL_DURATION=$((OVERALL_END_TIME - OVERALL_START_TIME))
    OVERALL_MINUTES=$((OVERALL_DURATION / 60))
    OVERALL_SECONDS=$((OVERALL_DURATION % 60))
    
    log_success "=== Build Complete ==="
    log_success "Total build time: ${OVERALL_MINUTES}m ${OVERALL_SECONDS}s"
    log_info "To deploy GeoServer, run: start-geoserver.sh"
    log_info "Build log saved to: $LOG_FILE"
    
    echo ""
    echo "=== Build completed at $(date) ==="
    exit 0
else
    # Build failed
    GEOSERVER_END_TIME=$(date +%s)
    DURATION=$((GEOSERVER_END_TIME - GEOSERVER_START_TIME))
    MINUTES=$((DURATION / 60))
    SECONDS=$((DURATION % 60))
    
    log_error "GeoServer build failed after ${MINUTES}m ${SECONDS}s"
    log_error "Check the Maven output above for details"
    log_error "Build log saved to: $LOG_FILE"
    log_info "Common issues:"
    log_info "  - Missing dependencies (check Maven repository)"
    log_info "  - Compilation errors (check Java version compatibility)"
    log_info "  - Incompatible GeoTools/GeoWebCache versions"
    log_info "  - Network issues (check internet connectivity)"
    
    echo ""
    echo "=== Build failed at $(date) ==="
    exit 1
fi
