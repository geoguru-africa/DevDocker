#!/bin/bash
# Stop GeoServer (Tomcat) gracefully
# This script stops the Tomcat server without stopping the container

set -e

echo "=== Stopping GeoServer ==="
echo ""

# Function to get Tomcat PID
get_tomcat_pid() {
    # Try multiple methods to find Tomcat process
    local pid=""
    
    # Method 1: Check PID file
    if [ -f "/tmp/tomcat.pid" ]; then
        pid=$(cat "/tmp/tomcat.pid")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo "$pid"
            return 0
        fi
    fi
    
    # Method 2: Find by process name
    pid=$(pgrep -f "catalina.sh run" || true)
    if [ -n "$pid" ]; then
        echo "$pid"
        return 0
    fi
    
    # Method 3: Find by Java process with Tomcat
    pid=$(pgrep -f "org.apache.catalina.startup.Bootstrap" || true)
    if [ -n "$pid" ]; then
        echo "$pid"
        return 0
    fi
    
    return 1
}

# Check if Tomcat is running
TOMCAT_PID=$(get_tomcat_pid)

if [ -z "$TOMCAT_PID" ]; then
    echo "GeoServer (Tomcat) is not running"
    exit 0
fi

echo "Found Tomcat process (PID: $TOMCAT_PID)"
echo "Stopping Tomcat gracefully..."

# Try graceful shutdown first using catalina.sh
if [ -x "/usr/local/tomcat/bin/catalina.sh" ]; then
    /usr/local/tomcat/bin/catalina.sh stop 2>/dev/null || true
    
    # Wait up to 30 seconds for graceful shutdown
    echo -n "Waiting for graceful shutdown"
    count=0
    while [ $count -lt 30 ]; do
        if ! ps -p "$TOMCAT_PID" > /dev/null 2>&1; then
            echo ""
            echo "Tomcat stopped gracefully"
            rm -f /tmp/tomcat.pid
            exit 0
        fi
        echo -n "."
        sleep 1
        count=$((count + 1))
    done
    echo ""
fi

# Force kill if still running after 30 seconds
if ps -p "$TOMCAT_PID" > /dev/null 2>&1; then
    echo "Graceful shutdown timed out, forcing shutdown..."
    kill -9 "$TOMCAT_PID" 2>/dev/null || true
    sleep 2
    
    if ps -p "$TOMCAT_PID" > /dev/null 2>&1; then
        echo "ERROR: Failed to stop Tomcat"
        exit 1
    fi
fi

echo "Tomcat stopped"
rm -f /tmp/tomcat.pid

# Clean up deployed WAR and expanded directory
echo "Cleaning up deployed files..."
rm -f /usr/local/tomcat/webapps/geoserver.war
rm -rf /usr/local/tomcat/webapps/geoserver

echo ""
echo "GeoServer stopped successfully"
