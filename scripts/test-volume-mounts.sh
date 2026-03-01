#!/bin/bash
# Test script to verify source code volume mounts are working correctly

set -e

echo "=========================================="
echo "Testing Source Code Volume Mounts"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test function
test_mount() {
    local mount_point=$1
    local description=$2
    
    echo -n "Testing ${description}... "
    
    if [ -d "${mount_point}" ]; then
        # Check if directory is accessible
        if ls "${mount_point}" > /dev/null 2>&1; then
            # Check if it's actually mounted (not empty container directory)
            if [ "$(ls -A ${mount_point} 2>/dev/null)" ]; then
                echo -e "${GREEN}✓ MOUNTED (contains files)${NC}"
                return 0
            else
                echo -e "${YELLOW}⚠ EMPTY (directory exists but no files)${NC}"
                return 1
            fi
        else
            echo -e "${RED}✗ NOT ACCESSIBLE${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ DIRECTORY NOT FOUND${NC}"
        return 1
    fi
}

# Test each workspace directory
echo "Checking workspace directories:"
echo ""

geoserver_ok=0
geotools_ok=0
geowebcache_ok=0

test_mount "/workspace/geoserver" "GeoServer (/workspace/geoserver)" && geoserver_ok=1
test_mount "/workspace/geotools" "GeoTools (/workspace/geotools)" && geotools_ok=1
test_mount "/workspace/geowebcache" "GeoWebCache (/workspace/geowebcache)" && geowebcache_ok=1

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="

if [ $geoserver_ok -eq 1 ]; then
    echo -e "${GREEN}✓ GeoServer repository is mounted and accessible${NC}"
else
    echo -e "${RED}✗ GeoServer repository is NOT properly mounted${NC}"
    echo "  Action: Clone your GeoServer fork to ./geoserver/"
    echo "  Command: git clone https://github.com/YOUR_USERNAME/geoserver.git"
fi

if [ $geotools_ok -eq 1 ]; then
    echo -e "${GREEN}✓ GeoTools repository is mounted and accessible${NC}"
else
    echo -e "${YELLOW}⚠ GeoTools repository is empty or not mounted${NC}"
    echo "  This is optional. Only needed if CUSTOM_GEOTOOLS=true"
    echo "  To use: git clone https://github.com/YOUR_USERNAME/geotools.git"
fi

if [ $geowebcache_ok -eq 1 ]; then
    echo -e "${GREEN}✓ GeoWebCache repository is mounted and accessible${NC}"
else
    echo -e "${YELLOW}⚠ GeoWebCache repository is empty or not mounted${NC}"
    echo "  This is optional. Only needed if CUSTOM_GEOWEBCACHE=true"
    echo "  To use: git clone https://github.com/YOUR_USERNAME/geowebcache.git"
fi

echo ""

# Test write permissions
echo "Testing write permissions:"
echo ""

test_file="/workspace/.mount-test-$$"
if touch "${test_file}" 2>/dev/null; then
    echo -e "${GREEN}✓ Write permissions OK${NC}"
    rm -f "${test_file}"
else
    echo -e "${RED}✗ Write permissions FAILED${NC}"
    echo "  Volume mounts may be read-only or permission issue exists"
fi

echo ""

# Final verdict
if [ $geoserver_ok -eq 1 ]; then
    echo -e "${GREEN}Volume mounts are working correctly!${NC}"
    exit 0
else
    echo -e "${RED}GeoServer repository must be mounted to proceed.${NC}"
    echo "Please clone your fork and restart the container."
    exit 1
fi
