#!/bin/bash
# DevDocker entrypoint script
# Handles container initialization and startup

set -e

# Source logging and error handling libraries
source /opt/devdocker/scripts/lib/logging.sh
source /opt/devdocker/scripts/lib/error-handlers.sh

# Set log level from environment (DEBUG, INFO, WARNING, ERROR)
case "${LOG_LEVEL:-INFO}" in
    DEBUG)   export CURRENT_LOG_LEVEL=$LOG_LEVEL_DEBUG ;;
    INFO)    export CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO ;;
    WARNING) export CURRENT_LOG_LEVEL=$LOG_LEVEL_WARNING ;;
    ERROR)   export CURRENT_LOG_LEVEL=$LOG_LEVEL_ERROR ;;
    *)       export CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO ;;
esac

log_info "=== Starting GeoServer DevDocker Environment ==="
log_info "Log level: ${LOG_LEVEL:-INFO}"
log_info "Log file: $LOG_FILE"

# Add custom tools and scripts to PATH
# - /root/bin: Personal tools (persistent in devdocker-home volume)
# - /root/.local/bin: Personal tools (standard Unix location, persistent)
# - /opt/devdocker/scripts: Project scripts (bind mount, version controlled)
export PATH="/root/bin:/root/.local/bin:/opt/devdocker/scripts:${PATH}"

# Run startup checks
log_info ""
run_startup_checks || {
    log_error "Startup checks failed - container may not function correctly"
    log_error "Review errors above and fix configuration issues"
    # Don't exit - allow container to start for debugging
}
log_info ""

# Export environment variables to /etc/profile.d for SSH sessions
# This ensures environment variables from docker-compose.yml are available when SSHing in
echo "export CUSTOM_GEOTOOLS=${CUSTOM_GEOTOOLS:-false}" > /etc/profile.d/devdocker-env.sh
echo "export CUSTOM_GEOWEBCACHE=${CUSTOM_GEOWEBCACHE:-false}" >> /etc/profile.d/devdocker-env.sh
echo "export GEOSERVER_DATA_DIR=${GEOSERVER_DATA_DIR:-/opt/geoserver/data_dir}" >> /etc/profile.d/devdocker-env.sh
echo "export JAVA_OPTS=\"${JAVA_OPTS}\"" >> /etc/profile.d/devdocker-env.sh
echo "export MAVEN_MIRROR_URL=\"${MAVEN_MIRROR_URL}\"" >> /etc/profile.d/devdocker-env.sh
chmod +x /etc/profile.d/devdocker-env.sh

# Configure Maven repository fallback chain
log_info "Configuring Maven repository chain..."

# Set up Maven repository symlink (persistent volume at /opt/maven-repo)
if [ ! -L /root/.m2/repository ]; then
    log_info "Setting up Maven repository symlink..."
    mkdir -p /root/.m2
    mkdir -p /opt/maven-repo
    
    # If /root/.m2/repository exists as a directory (from old setup), move it
    if [ -d /root/.m2/repository ] && [ ! -L /root/.m2/repository ]; then
        log_info "  Migrating existing Maven repository to persistent volume..."
        cp -r /root/.m2/repository/* /opt/maven-repo/ 2>/dev/null || true
        rm -rf /root/.m2/repository
    fi
    
    # Create symlink
    ln -s /opt/maven-repo /root/.m2/repository
    log_success "  Maven repository symlinked: /root/.m2/repository -> /opt/maven-repo"
else
    log_debug "  Maven repository symlink already configured"
fi

# 1. Check for host repository mount (first fallback after local repo)
if [ -d "/opt/maven-repo-host" ] && [ -n "$(ls -A /opt/maven-repo-host 2>/dev/null)" ]; then
    log_info "  Host repository detected at /opt/maven-repo-host"
    
    # Check if host-repo is already configured (prevent duplicates on container restart)
    if ! grep -q '<id>host-repo</id>' /root/.m2/settings.xml; then
        # Add host repo as a repository (not a mirror) so Maven can fall back to Maven Central
        # Insert after the FIRST <repositories> tag in the devdocker profile
        sed -i '0,/<repositories>/s|<repositories>|<repositories>\n        <repository>\n          <id>host-repo</id>\n          <url>file:///opt/maven-repo-host</url>\n          <releases>\n            <enabled>true</enabled>\n          </releases>\n          <snapshots>\n            <enabled>true</enabled>\n          </snapshots>\n        </repository>|' /root/.m2/settings.xml
        log_success "  Host repository added to Maven settings"
    else
        log_debug "  Host repository already configured in Maven settings"
    fi
fi

# 2. Check for classroom/presenter mirror (second fallback)
if [ -n "$MAVEN_MIRROR_URL" ]; then
    log_info "  Classroom mirror configured: $MAVEN_MIRROR_URL"
    
    # Add classroom mirror to settings.xml
    sed -i "/<mirrors>/a\\    <mirror>\\n      <id>classroom-mirror</id>\\n      <mirrorOf>*</mirrorOf>\\n      <url>$MAVEN_MIRROR_URL</url>\\n    </mirror>" /root/.m2/settings.xml
fi

# 3. Maven Central is always the final fallback (no mirror needed, it's default)
if [ -d "/opt/maven-repo-host" ] || [ -n "$MAVEN_MIRROR_URL" ]; then
    log_info "  Maven Central will be used as final fallback"
    
    log_info ""
    log_info "Maven repository fallback chain configured:"
    log_info "  1. Local repo: /root/.m2/repository -> /opt/maven-repo (devdocker-maven-repo volume)"
    [ -d "/opt/maven-repo-host" ] && log_info "  2. Host repo: /opt/maven-repo-host (read-only)"
    [ -n "$MAVEN_MIRROR_URL" ] && log_info "  3. Classroom mirror: $MAVEN_MIRROR_URL"
    log_info "  Final: Maven Central (https://repo.maven.apache.org/maven2)"
else
    log_info "  Using Maven Central directly (no mirrors configured)"
fi

# Initialize default data directory on first run
log_info ""
log_info "Checking GeoServer data directory..."
DATA_DIR="${GEOSERVER_DATA_DIR:-/opt/geoserver/data_dir}"

if [ ! -d "$DATA_DIR" ] || [ -z "$(ls -A $DATA_DIR 2>/dev/null)" ]; then
    log_info "Initializing default GeoServer data directory at $DATA_DIR"
    mkdir -p "$DATA_DIR"
    
    # Copy GeoServer's default data directory from source repository
    # Use the release data directory (full sample data) for development
    SOURCE_DATA_DIR="/workspace/geoserver/data/release"
    
    if [ -d "$SOURCE_DATA_DIR" ] && [ -n "$(ls -A $SOURCE_DATA_DIR 2>/dev/null)" ]; then
        log_info "Copying release data directory from $SOURCE_DATA_DIR"
        cp -r "$SOURCE_DATA_DIR"/* "$DATA_DIR/"
        log_success "Default data directory copied successfully"
    else
        log_warning "Source data directory not found at $SOURCE_DATA_DIR"
        log_warning "  GeoServer will create its own default data directory on first startup"
        log_warning "  Ensure /workspace/geoserver is properly mounted with GeoServer source code"
    fi
    
    log_success "Data directory initialized at $DATA_DIR"
else
    log_info "Using existing data directory at $DATA_DIR"
fi

# Verify build tools
log_info ""
/opt/devdocker/scripts/verify-tools.sh

# Execute custom startup script if present
if [ -f /opt/devdocker/startup-custom.sh ]; then
    log_info ""
    log_info "Executing custom startup script..."
    bash /opt/devdocker/startup-custom.sh || log_warning "Custom startup script failed"
fi

# Start SSH server
log_info ""
log_info "Starting SSH server..."

# Copy SSH keys from host source to persistent home directory
# The SSH keys are mounted read-only at /opt/devdocker/ssh-keys-source
# We copy them to /root/.ssh (which is in the persistent devdocker-home volume)
if [ -d /opt/devdocker/ssh-keys-source ]; then
    log_info "Copying SSH keys from host to persistent home directory..."
    
    # Create .ssh directory in persistent home
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
    
    # Copy authorized_keys if it exists
    if [ -f /opt/devdocker/ssh-keys-source/authorized_keys ]; then
        cp /opt/devdocker/ssh-keys-source/authorized_keys /root/.ssh/authorized_keys
        
        # Convert SSH2 format keys to OpenSSH format if needed
        if grep -q "BEGIN SSH2 PUBLIC KEY" /root/.ssh/authorized_keys; then
            log_info "Converting SSH2 format keys to OpenSSH format..."
            ssh-keygen -i -f /root/.ssh/authorized_keys > /root/.ssh/authorized_keys.tmp 2>/dev/null || true
            if [ -f /root/.ssh/authorized_keys.tmp ] && [ -s /root/.ssh/authorized_keys.tmp ]; then
                mv /root/.ssh/authorized_keys.tmp /root/.ssh/authorized_keys
                log_success "SSH keys converted to OpenSSH format"
            else
                rm -f /root/.ssh/authorized_keys.tmp
                log_warning "Failed to convert SSH2 keys. Please use OpenSSH format."
            fi
        fi
        
        # Set proper permissions
        chmod 600 /root/.ssh/authorized_keys
        log_success "SSH keys configured: $(wc -l < /root/.ssh/authorized_keys) key(s) found"
    else
        log_warning "No authorized_keys file found in /opt/devdocker/ssh-keys-source"
        log_warning "  SSH access will not work until you add your public key."
        log_warning "  Add your public key to ./ssh-keys/authorized_keys on the host"
    fi
    
    # Copy any other SSH files (config, known_hosts, etc.)
    for file in /opt/devdocker/ssh-keys-source/*; do
        if [ -f "$file" ] && [ "$(basename "$file")" != "authorized_keys" ]; then
            cp "$file" /root/.ssh/
            chmod 600 /root/.ssh/$(basename "$file")
        fi
    done
else
    log_warning "No SSH keys directory mounted at /opt/devdocker/ssh-keys-source!"
    log_warning "  SSH access will not work until you configure SSH keys."
    log_warning "  Create ./ssh-keys directory and add your public key to ./ssh-keys/authorized_keys"
fi

# Verify authorized_keys exists
if [ ! -f /root/.ssh/authorized_keys ]; then
    log_warning "No authorized_keys file found!"
    log_warning "  SSH access will not work until you add your public key."
    log_warning "  Add your public key to ./ssh-keys/authorized_keys on the host"
fi

# Start SSH daemon
/usr/sbin/sshd
log_success "SSH server listening on port 22 (mapped to host port ${SSH_PORT:-2222})"

# Start GeoServer auto-restart watcher in background
log_info ""
log_info "Starting GeoServer auto-restart watcher..."
/opt/devdocker/scripts/watch-geoserver.sh > /var/log/geoserver-watcher.log 2>&1 &
WATCHER_PID=$!
log_success "Watcher started (PID: $WATCHER_PID)"
log_info "  Monitoring: /workspace/geoserver/src/web/app/target/geoserver.war"
log_info "  Logs: /var/log/geoserver-watcher.log"

log_info ""
log_success "=== DevDocker environment ready ==="
log_info ""

# Change to workspace directory for convenience
cd /workspace

# Execute the command passed to the container
exec "$@"
