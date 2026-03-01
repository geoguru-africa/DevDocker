#!/bin/bash
# Start GeoServer with JDWP debugging enabled
# This script configures Tomcat to run GeoServer with remote debugging support

set -e

echo "=== Starting GeoServer with JDWP Debugging ==="

# Set GeoServer data directory
export GEOSERVER_DATA_DIR="${GEOSERVER_DATA_DIR:-/opt/geoserver/data_dir}"

# Configure JAVA_OPTS if not already set
# Check if JDWP is already configured (to avoid duplicate agent error)
if [[ ! "$JAVA_OPTS" =~ "jdwp" ]]; then
    echo "Adding JDWP debug configuration..."
    export JAVA_OPTS="${JAVA_OPTS} -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"
fi

# Add memory settings if not already present
if [[ ! "$JAVA_OPTS" =~ "Xms" ]]; then
    export JAVA_OPTS="${JAVA_OPTS} -Xms512m -Xmx2g"
fi

# Add GeoServer data directory system property
export JAVA_OPTS="${JAVA_OPTS} -DGEOSERVER_DATA_DIR=${GEOSERVER_DATA_DIR}"

echo ""
echo "Java Options: ${JAVA_OPTS}"
echo "GeoServer Data Directory: ${GEOSERVER_DATA_DIR}"
echo "Debug Port: 5005 (JDWP enabled)"
echo ""

# Check if GeoServer WAR exists
GEOSERVER_WAR="/workspace/geoserver/src/web/app/target/geoserver.war"
if [ ! -f "$GEOSERVER_WAR" ]; then
    echo "ERROR: GeoServer WAR file not found at $GEOSERVER_WAR"
    echo "Please build GeoServer first using: build-geoserver.sh"
    exit 1
fi

# Deploy GeoServer WAR to Tomcat
echo "Deploying GeoServer WAR to Tomcat..."
cp "$GEOSERVER_WAR" /usr/local/tomcat/webapps/geoserver.war

# Start Tomcat
echo "Starting Tomcat..."
echo ""
exec /usr/local/tomcat/bin/catalina.sh run
