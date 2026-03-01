#!/bin/bash
# detect-geoserver-version.sh - Detect GeoServer version and determine Tomcat/Java requirements
# This script handles both branch names and detached HEAD states (tags)

set -e

# Color codes for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

GEOSERVER_DIR="${1:-/workspace/geoserver}"

if [ ! -d "$GEOSERVER_DIR/.git" ]; then
    echo -e "${YELLOW}Warning: Not a git repository: $GEOSERVER_DIR${NC}" >&2
    echo "unknown"
    exit 0
fi

cd "$GEOSERVER_DIR"

# Try to get the current branch name
BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")

if [ -n "$BRANCH" ]; then
    # We're on a branch
    VERSION_INFO="$BRANCH"
else
    # Detached HEAD - try to resolve to a tag
    # First, get the commit hash
    COMMIT=$(cat .git/HEAD 2>/dev/null || git rev-parse HEAD 2>/dev/null)
    
    # Try to find a tag that points to this commit
    TAG=$(git describe --exact-match --tags "$COMMIT" 2>/dev/null || echo "")
    
    if [ -n "$TAG" ]; then
        VERSION_INFO="$TAG"
    else
        # No exact tag match, try to find the nearest tag
        NEAREST_TAG=$(git describe --tags --abbrev=0 "$COMMIT" 2>/dev/null || echo "")
        if [ -n "$NEAREST_TAG" ]; then
            VERSION_INFO="$NEAREST_TAG (detached)"
        else
            # Fallback to commit hash
            VERSION_INFO="commit:${COMMIT:0:8}"
        fi
    fi
fi

echo "$VERSION_INFO"
