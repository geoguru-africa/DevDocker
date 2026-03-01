#!/bin/bash
# get-tomcat-image.sh - Determine the appropriate Tomcat base image for GeoServer version
# Based on GeoServer Docker repository conventions:
# - GeoServer 2.28.x and main (3.0): Java 17, Tomcat 9 (but main uses Tomcat 11)
# - GeoServer 2.27.x: Java 17, Tomcat 9
# - GeoServer 2.26.x and older: Java 11, Tomcat 9

set -e

VERSION_INFO="${1:-unknown}"

# Extract version number from branch/tag name
# Examples: "2.28.2" -> "2.28", "main" -> "main", "2.28.x" -> "2.28"
if [[ "$VERSION_INFO" == "main" ]] || [[ "$VERSION_INFO" == "master" ]]; then
    # Main branch uses Tomcat 11 and Java 21
    echo "tomcat:11.0-jdk21-temurin-noble"
elif [[ "$VERSION_INFO" =~ ^([0-9]+)\.([0-9]+) ]]; then
    MAJOR="${BASH_REMATCH[1]}"
    MINOR="${BASH_REMATCH[2]}"
    
    # Determine Tomcat and Java version based on GeoServer version
    if [ "$MAJOR" -eq 2 ] && [ "$MINOR" -ge 28 ]; then
        # GeoServer 2.28.x and above: Java 17, Tomcat 9
        echo "tomcat:9.0-jdk17-temurin-noble"
    elif [ "$MAJOR" -eq 2 ] && [ "$MINOR" -eq 27 ]; then
        # GeoServer 2.27.x: Java 17, Tomcat 9
        echo "tomcat:9.0-jdk17-temurin-noble"
    elif [ "$MAJOR" -eq 2 ] && [ "$MINOR" -le 26 ]; then
        # GeoServer 2.26.x and older: Java 11, Tomcat 9
        echo "tomcat:9.0-jdk11-temurin-noble"
    elif [ "$MAJOR" -ge 3 ]; then
        # GeoServer 3.x and above: Java 21, Tomcat 11
        echo "tomcat:11.0-jdk21-temurin-noble"
    else
        # Unknown version, default to Java 17, Tomcat 9
        echo "tomcat:9.0-jdk17-temurin-noble"
    fi
else
    # Unknown format, default to Java 17, Tomcat 9
    echo "tomcat:9.0-jdk17-temurin-noble"
fi
