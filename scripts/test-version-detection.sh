#!/bin/bash
# test-version-detection.sh - Test version detection from inside the container

set -e

echo "=== Testing GeoServer Version Detection ==="
echo ""

GEOSERVER_DIR="/workspace/geoserver"

if [ ! -d "$GEOSERVER_DIR" ]; then
    echo "ERROR: GeoServer directory not found at $GEOSERVER_DIR"
    exit 1
fi

echo "1. Checking git HEAD:"
if [ -f "$GEOSERVER_DIR/.git/HEAD" ]; then
    echo "   .git/HEAD contents:"
    cat "$GEOSERVER_DIR/.git/HEAD"
else
    echo "   ERROR: .git/HEAD not found"
fi

echo ""
echo "2. Running detect-geoserver-version.sh:"
VERSION=$(/opt/devdocker/scripts/detect-geoserver-version.sh "$GEOSERVER_DIR")
echo "   Detected version: $VERSION"

echo ""
echo "3. Running get-tomcat-image.sh:"
TOMCAT_IMAGE=$(/opt/devdocker/scripts/get-tomcat-image.sh "$VERSION")
echo "   Required Tomcat image: $TOMCAT_IMAGE"

echo ""
echo "4. Current Java version in container:"
java -version 2>&1 | head -n 2

echo ""
echo "5. Current Tomcat version in container:"
if [ -f /usr/local/tomcat/RELEASE-NOTES ]; then
    cat /usr/local/tomcat/RELEASE-NOTES | grep "Apache Tomcat Version" | head -n 1
else
    echo "   Tomcat RELEASE-NOTES not found"
fi

echo ""
echo "=== Test Complete ==="
