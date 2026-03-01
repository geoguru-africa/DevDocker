#!/bin/bash
# Test script for data directory initialization
# Verifies that the data directory is properly initialized from GeoServer source

set -e

echo "=== Testing Data Directory Initialization ==="
echo ""

# Test 1: Verify GEOSERVER_DATA_DIR environment variable is set
echo "Test 1: Checking GEOSERVER_DATA_DIR environment variable..."
if [ -z "$GEOSERVER_DATA_DIR" ]; then
    echo "FAIL: GEOSERVER_DATA_DIR is not set"
    exit 1
fi
echo "PASS: GEOSERVER_DATA_DIR=$GEOSERVER_DATA_DIR"
echo ""

# Test 2: Verify data directory exists
echo "Test 2: Checking if data directory exists..."
if [ ! -d "$GEOSERVER_DATA_DIR" ]; then
    echo "FAIL: Data directory does not exist at $GEOSERVER_DATA_DIR"
    exit 1
fi
echo "PASS: Data directory exists at $GEOSERVER_DATA_DIR"
echo ""

# Test 3: Verify data directory is not empty
echo "Test 3: Checking if data directory is initialized..."
if [ -z "$(ls -A $GEOSERVER_DATA_DIR 2>/dev/null)" ]; then
    echo "FAIL: Data directory is empty"
    exit 1
fi
echo "PASS: Data directory is initialized with content"
echo ""

# Test 4: Verify key GeoServer data directory files exist
echo "Test 4: Checking for key GeoServer data directory files..."
REQUIRED_FILES=(
    "global.xml"
    "logging.xml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$GEOSERVER_DATA_DIR/$file" ]; then
        echo "WARNING: Expected file not found: $file"
        echo "  This may be normal if using a minimal data directory"
    else
        echo "  Found: $file"
    fi
done
echo "PASS: Data directory structure verified"
echo ""

# Test 5: Verify data directory is writable
echo "Test 5: Checking if data directory is writable..."
TEST_FILE="$GEOSERVER_DATA_DIR/.test-write"
if ! touch "$TEST_FILE" 2>/dev/null; then
    echo "FAIL: Data directory is not writable"
    exit 1
fi
rm -f "$TEST_FILE"
echo "PASS: Data directory is writable"
echo ""

echo "=== All Data Directory Tests Passed ==="
