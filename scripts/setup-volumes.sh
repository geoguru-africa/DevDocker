#!/bin/bash
# setup-volumes.sh - Initialize Docker volumes with source code and dependencies
# Run this script ONCE after creating the container with named volumes

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

echo "=== DevDocker Volume Setup ==="
echo ""

# Check if container is running
if ! docker ps | grep -q devdocker; then
    log_error "Container 'devdocker' is not running"
    log_info "Start the container with: docker-compose up -d"
    exit 1
fi

# Check if workspace is already populated
log_info "Checking if workspace is already initialized..."
if docker exec devdocker test -d /workspace/geoserver/.git; then
    log_warning "Workspace already contains GeoServer repository"
    read -p "Do you want to re-clone? This will DELETE existing code! (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping GeoServer clone"
        SKIP_CLONE=true
    else
        log_info "Removing existing GeoServer repository..."
        docker exec devdocker rm -rf /workspace/geoserver
        SKIP_CLONE=false
    fi
else
    SKIP_CLONE=false
fi

# Clone GeoServer
if [ "$SKIP_CLONE" = false ]; then
    log_info "Cloning GeoServer repository..."
    log_info "This may take several minutes..."
    
    # Prompt for version/branch
    echo ""
    echo "Which GeoServer version do you want to clone?"
    echo "  1) main (latest development)"
    echo "  2) 2.28.x (stable branch)"
    echo "  3) 2.28.2 (specific tag)"
    echo "  4) Custom (specify branch/tag)"
    read -p "Enter choice [1-4]: " choice
    
    case $choice in
        1)
            BRANCH="main"
            ;;
        2)
            BRANCH="2.28.x"
            ;;
        3)
            BRANCH="2.28.2"
            ;;
        4)
            read -p "Enter branch or tag name: " BRANCH
            ;;
        *)
            log_error "Invalid choice"
            exit 1
            ;;
    esac
    
    log_info "Cloning branch/tag: $BRANCH"
    
    if docker exec devdocker bash -c "cd /workspace && git clone --depth 1 --branch $BRANCH https://github.com/geoserver/geoserver.git"; then
        log_success "GeoServer cloned successfully"
    else
        log_error "Failed to clone GeoServer"
        exit 1
    fi
fi

# Check Maven repository
log_info "Checking Maven repository..."
if docker exec devdocker test -d /root/.m2/repository/org; then
    log_info "Maven repository already contains dependencies"
    log_info "Dependencies will be downloaded as needed during builds"
else
    log_info "Maven repository is empty"
    log_info "Dependencies will be downloaded on first build"
fi

# Summary
echo ""
log_success "=== Setup Complete ==="
echo ""
log_info "Workspace location: /workspace/geoserver"
log_info "Maven repository: /root/.m2/repository"
echo ""
log_info "Next steps:"
log_info "  1. Connect to container: docker exec -it devdocker bash"
log_info "  2. Run build: build-geoserver.sh"
log_info "  3. Expected build time: ~2-3 minutes (after dependencies downloaded)"
echo ""
log_info "To access files from host:"
log_info "  docker cp devdocker:/workspace/geoserver/file.txt ."
log_info "  docker cp file.txt devdocker:/workspace/geoserver/"
echo ""
