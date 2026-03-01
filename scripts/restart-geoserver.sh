#!/bin/bash
# Restart GeoServer (stop and start)
# This script stops and starts Tomcat without restarting the container

set -e

echo "=== Restarting GeoServer ==="
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Stop GeoServer
echo "Step 1: Stopping GeoServer..."
"$SCRIPT_DIR/stop-geoserver.sh"

echo ""
echo "Waiting 3 seconds before restart..."
sleep 3
echo ""

# Start GeoServer
echo "Step 2: Starting GeoServer..."
"$SCRIPT_DIR/start-geoserver.sh"
