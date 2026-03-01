#!/bin/bash
# Build tool verification script
# Checks that Java, Maven, and Git are installed and functional

set -e

echo "=== DevDocker Build Tools Verification ==="
echo ""

# Check Java
echo "Checking Java..."
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1)
    echo "✓ Java found: $JAVA_VERSION"
else
    echo "✗ ERROR: Java not found"
    exit 1
fi

# Check Maven
echo ""
echo "Checking Maven..."
if command -v mvn &> /dev/null; then
    MVN_VERSION=$(mvn -version | head -n 1)
    echo "✓ Maven found: $MVN_VERSION"
    
    # Verify Maven version is 3.8+
    MVN_VER=$(mvn -version | head -n 1 | grep -oP 'Apache Maven \K[0-9]+\.[0-9]+' || echo "0.0")
    MVN_MAJOR=$(echo $MVN_VER | cut -d. -f1)
    MVN_MINOR=$(echo $MVN_VER | cut -d. -f2)
    
    if [ "$MVN_MAJOR" -lt 3 ] || ([ "$MVN_MAJOR" -eq 3 ] && [ "$MVN_MINOR" -lt 8 ]); then
        echo "✗ ERROR: Maven version must be 3.8 or later (found $MVN_VER)"
        exit 1
    fi
else
    echo "✗ ERROR: Maven not found"
    exit 1
fi

# Check Git
echo ""
echo "Checking Git..."
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version)
    echo "✓ Git found: $GIT_VERSION"
else
    echo "✗ ERROR: Git not found"
    exit 1
fi

echo ""
echo "=== All build tools verified successfully ==="
exit 0
