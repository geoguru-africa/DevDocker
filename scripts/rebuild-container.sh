#!/bin/bash
# rebuild-container.sh - Rebuild Docker container with correct Tomcat/Java version
# This script detects the GeoServer version and rebuilds the container with the appropriate base image
# Usage: rebuild-container.sh [--force]
#   --force: Force rebuild even if Java version matches

set -e

# Parse command line arguments
FORCE_REBUILD=false
if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
    FORCE_REBUILD=true
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo "=== DevDocker Container Rebuild ==="
echo ""

# Check if we're running from inside the container or on the host
if [ -f /.dockerenv ]; then
    log_error "This script must be run from the HOST, not inside the container"
    log_info "Exit the container and run this script from your host machine"
    exit 1
fi

# Detect GeoServer version from running container (source code is in named volume)
log_info "Detecting GeoServer version from container..."

# Check if container is running
if ! docker ps | grep -q devdocker; then
    log_warning "Container 'devdocker' is not running"
    log_info "Attempting to detect version from Docker volume..."
    
    # Try to detect version from the volume by starting a temporary container
    # This mounts the workspace volume and runs the detection script
    VERSION_INFO=$(docker run --rm \
        -v devdocker-workspace:/workspace:ro \
        -v "$(pwd)/scripts:/scripts:ro" \
        tomcat:9.0-jdk21-temurin-noble \
        bash -c 'if [ -f /workspace/geoserver/src/pom.xml ]; then grep -oP "<version>\K[0-9]+\.[0-9]+(\.[0-9]+)?(-SNAPSHOT)?" /workspace/geoserver/src/pom.xml | head -n 1; elif [ -d /workspace/geoserver/.git ]; then cd /workspace/geoserver && git rev-parse --abbrev-ref HEAD 2>/dev/null; else echo "unknown"; fi' 2>/dev/null || echo "unknown")
    
    if [ "$VERSION_INFO" = "unknown" ]; then
        log_warning "Could not detect GeoServer version from volume"
        log_warning "GeoServer may not be cloned yet in the workspace volume"
        log_info "Using default Tomcat image (tomcat:9.0-jdk21-temurin-noble)"
    else
        log_success "Detected version from volume: $VERSION_INFO"
    fi
else
    # Try to detect version from running container
    # Use MSYS_NO_PATHCONV=1 to prevent Git Bash on Windows from converting Unix paths
    VERSION_INFO=$(MSYS_NO_PATHCONV=1 docker exec devdocker /opt/devdocker/scripts/detect-geoserver-version.sh /workspace/geoserver 2>/dev/null || echo "unknown")
    
    if [ "$VERSION_INFO" = "unknown" ]; then
        log_warning "Could not detect GeoServer version from container"
        log_warning "GeoServer may not be cloned yet at /workspace/geoserver"
        log_info "Using default Tomcat image (tomcat:9.0-jdk21-temurin-noble)"
    fi
fi

log_success "GeoServer Version: $VERSION_INFO"

# Determine Tomcat image based on version
if [ "$VERSION_INFO" = "unknown" ]; then
    # Default to latest stable configuration
    TOMCAT_IMAGE="tomcat:9.0-jdk21-temurin-noble"
    log_info "Using default Tomcat image (version unknown)"
elif [[ "$VERSION_INFO" == "main" ]] || [[ "$VERSION_INFO" == "master" ]]; then
    TOMCAT_IMAGE="tomcat:11.0-jdk21-temurin-noble"
elif [[ "$VERSION_INFO" =~ ^([0-9]+)\.([0-9]+) ]]; then
    MAJOR="${BASH_REMATCH[1]}"
    MINOR="${BASH_REMATCH[2]}"
    
    if [ "$MAJOR" -eq 2 ] && [ "$MINOR" -ge 28 ]; then
        TOMCAT_IMAGE="tomcat:9.0-jdk17-temurin-noble"
    elif [ "$MAJOR" -eq 2 ] && [ "$MINOR" -eq 27 ]; then
        TOMCAT_IMAGE="tomcat:9.0-jdk17-temurin-noble"
    elif [ "$MAJOR" -eq 2 ] && [ "$MINOR" -le 26 ]; then
        TOMCAT_IMAGE="tomcat:9.0-jdk11-temurin-noble"
    elif [ "$MAJOR" -ge 3 ]; then
        TOMCAT_IMAGE="tomcat:11.0-jdk21-temurin-noble"
    else
        TOMCAT_IMAGE="tomcat:9.0-jdk17-temurin-noble"
    fi
else
    TOMCAT_IMAGE="tomcat:9.0-jdk17-temurin-noble"
fi

log_success "Required Tomcat Image: $TOMCAT_IMAGE"
echo ""

# Check if container is running and compare current Java version with required
if docker ps | grep -q devdocker; then
    log_info "Checking current container configuration..."
    
    # Get current Java version from running container
    CURRENT_JAVA=$(docker exec devdocker java -version 2>&1 | head -n 1 | grep -oP 'version "\K[0-9]+' || echo "unknown")
    
    # Extract required Java version from Tomcat image name
    if [[ "$TOMCAT_IMAGE" =~ jdk([0-9]+) ]]; then
        REQUIRED_JAVA="${BASH_REMATCH[1]}"
    else
        REQUIRED_JAVA="unknown"
    fi
    
    log_info "Current Java version: $CURRENT_JAVA"
    log_info "Required Java version: $REQUIRED_JAVA"
    
    # Compare versions
    if [ "$CURRENT_JAVA" = "$REQUIRED_JAVA" ] && [ "$FORCE_REBUILD" = false ]; then
        log_success "Container is already running the correct Java version!"
        log_info "No rebuild necessary."
        echo ""
        log_info "Container details:"
        docker exec devdocker java -version 2>&1 | head -n 2
        docker exec devdocker bash -c 'cat /usr/local/tomcat/RELEASE-NOTES 2>/dev/null | grep "Apache Tomcat Version" | head -n 1 || echo "Tomcat version: $(cat /usr/local/tomcat/VERSION 2>/dev/null || echo unknown)"'
        echo ""
        log_info "Container is ready. Connect via SSH on port 2222"
        log_info "To force a rebuild, use: $0 --force"
        exit 0
    elif [ "$CURRENT_JAVA" = "$REQUIRED_JAVA" ] && [ "$FORCE_REBUILD" = true ]; then
        log_info "Java versions match, but --force flag specified"
        log_info "Proceeding with rebuild..."
        echo ""
    else
        log_warning "Java version mismatch detected"
        log_info "Current: Java $CURRENT_JAVA, Required: Java $REQUIRED_JAVA"
        log_info "Proceeding with rebuild..."
        echo ""
    fi
fi

# Stop and remove existing container
log_info "Stopping and removing existing container..."
docker-compose down || log_warning "No existing container to remove"

# Rebuild with correct base image
log_info "Building new container with base image: $TOMCAT_IMAGE"
docker-compose build --build-arg BASE_IMAGE="$TOMCAT_IMAGE"

# Start the new container
log_info "Starting new container..."
docker-compose up -d

# Wait for container to be ready
log_info "Waiting for container to be ready..."
sleep 3

# Check if container is running
if docker ps | grep -q devdocker; then
    log_success "Container rebuilt and started successfully!"
    echo ""
    log_info "Container details:"
    docker exec devdocker java -version 2>&1 | head -n 2
    docker exec devdocker bash -c 'cat /usr/local/tomcat/RELEASE-NOTES | grep "Apache Tomcat Version" | head -n 1 || echo "Tomcat: $(basename /usr/local/tomcat)"'
    echo ""
    log_info "You can now connect via SSH on port 2222"
else
    log_error "Container failed to start"
    log_info "Check logs with: docker-compose logs"
    exit 1
fi
