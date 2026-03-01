#!/bin/bash
# tail-build-logs.sh - Tail the latest build logs
# Usage: tail-build-logs.sh [geoserver|geotrio|all] [lines]

set -e

LOG_DIR="/tmp/devdocker-logs"
BUILD_TYPE="${1:-all}"
LINES="${2:-50}"

# Color codes
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ ! -d "$LOG_DIR" ]; then
    echo -e "${YELLOW}No build logs found at $LOG_DIR${NC}"
    echo "Build logs are created when you run build-geoserver.sh or build-geotrio.sh"
    exit 0
fi

case "$BUILD_TYPE" in
    geoserver)
        LOG_FILE="$LOG_DIR/build-geoserver-latest.log"
        if [ -f "$LOG_FILE" ]; then
            echo -e "${BLUE}=== Latest GeoServer Build Log ===${NC}"
            echo -e "${GREEN}Log file: $(readlink -f $LOG_FILE)${NC}"
            echo ""
            tail -n "$LINES" "$LOG_FILE"
        else
            echo -e "${YELLOW}No GeoServer build log found${NC}"
        fi
        ;;
    geotrio)
        LOG_FILE="$LOG_DIR/build-geotrio-latest.log"
        if [ -f "$LOG_FILE" ]; then
            echo -e "${BLUE}=== Latest GeoTrio Build Log ===${NC}"
            echo -e "${GREEN}Log file: $(readlink -f $LOG_FILE)${NC}"
            echo ""
            tail -n "$LINES" "$LOG_FILE"
        else
            echo -e "${YELLOW}No GeoTrio build log found${NC}"
        fi
        ;;
    all)
        echo -e "${BLUE}=== Available Build Logs ===${NC}"
        echo ""
        
        if [ -f "$LOG_DIR/build-geoserver-latest.log" ]; then
            echo -e "${GREEN}GeoServer:${NC} $(readlink -f $LOG_DIR/build-geoserver-latest.log)"
            echo "  Last modified: $(stat -c '%y' $LOG_DIR/build-geoserver-latest.log | cut -d'.' -f1)"
        fi
        
        if [ -f "$LOG_DIR/build-geotrio-latest.log" ]; then
            echo -e "${GREEN}GeoTrio:${NC} $(readlink -f $LOG_DIR/build-geotrio-latest.log)"
            echo "  Last modified: $(stat -c '%y' $LOG_DIR/build-geotrio-latest.log | cut -d'.' -f1)"
        fi
        
        echo ""
        echo "All log files:"
        ls -lht "$LOG_DIR"/*.log 2>/dev/null | head -10 || echo "  No logs found"
        
        echo ""
        echo "Usage:"
        echo "  tail-build-logs.sh geoserver [lines]  - Show last N lines of GeoServer build"
        echo "  tail-build-logs.sh geotrio [lines]    - Show last N lines of GeoTrio build"
        echo "  tail -f $LOG_DIR/build-*-latest.log   - Follow the latest build log"
        ;;
    *)
        echo "Usage: tail-build-logs.sh [geoserver|geotrio|all] [lines]"
        exit 1
        ;;
esac
