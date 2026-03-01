#!/bin/bash
# Watch GeoServer WAR file and automatically restart Tomcat on changes
# Uses inotify-tools to monitor file changes

set -e

echo "=== GeoServer Auto-Restart Watcher ==="
echo ""

# Configuration
GEOSERVER_WAR="/workspace/geoserver/src/web/app/target/geoserver.war"
TOMCAT_WEBAPPS="/usr/local/tomcat/webapps"
TOMCAT_PID_FILE="/tmp/tomcat.pid"

# Check if inotify-tools is installed
if ! command -v inotifywait &> /dev/null; then
    echo "ERROR: inotify-tools is not installed"
    echo "Install with: apt-get install inotify-tools"
    exit 1
fi

# Check if WAR file exists
if [ ! -f "$GEOSERVER_WAR" ]; then
    echo "WARNING: GeoServer WAR file not found at $GEOSERVER_WAR"
    echo "Waiting for WAR file to be created..."
fi

# Function to get Tomcat PID
get_tomcat_pid() {
    # Try multiple methods to find Tomcat process
    local pid=""
    
    # Method 1: Check PID file
    if [ -f "$TOMCAT_PID_FILE" ]; then
        pid=$(cat "$TOMCAT_PID_FILE")
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

# Function to gracefully stop Tomcat
stop_tomcat() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Stopping Tomcat..."
    
    local pid=$(get_tomcat_pid)
    if [ -z "$pid" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Tomcat is not running"
        return 0
    fi
    
    # Try graceful shutdown first
    if [ -x "/usr/local/tomcat/bin/catalina.sh" ]; then
        /usr/local/tomcat/bin/catalina.sh stop 2>/dev/null || true
        
        # Wait up to 30 seconds for graceful shutdown
        local count=0
        while [ $count -lt 30 ]; do
            if ! ps -p "$pid" > /dev/null 2>&1; then
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Tomcat stopped gracefully"
                return 0
            fi
            sleep 1
            count=$((count + 1))
        done
    fi
    
    # Force kill if still running
    if ps -p "$pid" > /dev/null 2>&1; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Forcing Tomcat shutdown..."
        kill -9 "$pid" 2>/dev/null || true
        sleep 2
    fi
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Tomcat stopped"
}

# Function to start Tomcat
start_tomcat() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Tomcat..."
    
    # Deploy WAR file
    if [ -f "$GEOSERVER_WAR" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Deploying GeoServer WAR..."
        cp "$GEOSERVER_WAR" "$TOMCAT_WEBAPPS/geoserver.war"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: WAR file not found, skipping deployment"
    fi
    
    # Start Tomcat in background
    export GEOSERVER_DATA_DIR="${GEOSERVER_DATA_DIR:-/opt/geoserver/data_dir}"
    
    # Configure JAVA_OPTS if not already set
    if [[ ! "$JAVA_OPTS" =~ "jdwp" ]]; then
        export JAVA_OPTS="${JAVA_OPTS} -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"
    fi
    
    if [[ ! "$JAVA_OPTS" =~ "Xms" ]]; then
        export JAVA_OPTS="${JAVA_OPTS} -Xms512m -Xmx2g"
    fi
    
    export JAVA_OPTS="${JAVA_OPTS} -DGEOSERVER_DATA_DIR=${GEOSERVER_DATA_DIR}"
    
    # Start Tomcat in background and save PID
    /usr/local/tomcat/bin/catalina.sh start > /dev/null 2>&1
    
    # Save PID
    local pid=$(get_tomcat_pid)
    if [ -n "$pid" ]; then
        echo "$pid" > "$TOMCAT_PID_FILE"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Tomcat started (PID: $pid)"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: Could not determine Tomcat PID"
    fi
}

# Function to restart Tomcat
restart_tomcat() {
    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ========================================="
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WAR file changed - restarting GeoServer"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ========================================="
    
    stop_tomcat
    sleep 2
    start_tomcat
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Restart complete"
    echo ""
}

# Initial startup
echo "Monitoring: $GEOSERVER_WAR"
echo "Tomcat webapps: $TOMCAT_WEBAPPS"
echo ""
echo "Waiting for WAR file changes..."
echo "Press Ctrl+C to stop watching"
echo ""

# Watch for changes to the WAR file
# Monitor the target directory since the WAR file might be deleted and recreated
WAR_DIR=$(dirname "$GEOSERVER_WAR")
WAR_FILE=$(basename "$GEOSERVER_WAR")

# Create directory if it doesn't exist
mkdir -p "$WAR_DIR"

# Watch for close_write events (file finished writing) and moved_to events (file moved into place)
inotifywait -m -e close_write -e moved_to "$WAR_DIR" 2>/dev/null | while read -r directory event filename; do
    # Only react to changes to the specific WAR file
    if [ "$filename" = "$WAR_FILE" ]; then
        # Debounce: wait a moment to ensure file is fully written
        sleep 2
        
        # Verify file exists and is not empty
        if [ -f "$GEOSERVER_WAR" ] && [ -s "$GEOSERVER_WAR" ]; then
            restart_tomcat
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: WAR file is empty or missing, skipping restart"
        fi
    fi
done
