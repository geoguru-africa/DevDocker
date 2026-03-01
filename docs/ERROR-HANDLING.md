# Error Handling and Logging Guide

## Overview

The DevDocker environment includes comprehensive error detection and logging to help diagnose and resolve issues quickly. This guide covers the logging system, common errors, and troubleshooting steps.

## Logging System

### Log Levels

The logging system supports four log levels:

- **DEBUG**: Detailed diagnostic information for troubleshooting
- **INFO**: General informational messages (default)
- **WARNING**: Warning messages that don't prevent operation
- **ERROR**: Error messages indicating failures

### Setting Log Level

Set the log level using the `LOG_LEVEL` environment variable in `docker-compose.yml`:

```yaml
environment:
  - LOG_LEVEL=DEBUG  # Options: DEBUG, INFO, WARNING, ERROR
```

### Log Locations

| Log File | Purpose | Location |
|----------|---------|----------|
| Main log | Container startup and operations | `/var/log/devdocker/devdocker.log` |
| Build logs | Maven build output | `/tmp/devdocker-logs/build-*.log` |
| GeoServer watcher | Auto-restart monitoring | `/var/log/geoserver-watcher.log` |
| GeoServer runtime | Tomcat and GeoServer logs | `/usr/local/tomcat/logs/` |

### Viewing Logs

**From host:**
```bash
# View container logs
docker logs devdocker

# Follow logs in real-time
docker logs -f devdocker

# View last 100 lines
docker logs --tail 100 devdocker
```

**From inside container:**
```bash
# View main log
tail -f /var/log/devdocker/devdocker.log

# View latest build log
tail -f /tmp/devdocker-logs/build-geoserver-latest.log

# View GeoServer watcher log
tail -f /var/log/geoserver-watcher.log
```

## Startup Checks

The container performs automatic checks on startup:

### Volume Mount Checks
- Verifies `/workspace` is mounted
- Verifies `/root` (home directory) is accessible
- Checks Maven repository is writable
- Validates source code directories (warnings only)

### Disk Space Checks
- Workspace: Minimum 5GB required
- Home directory: Minimum 2GB required
- Maven repository: Minimum 2GB required

### Environment Validation
- Validates `CUSTOM_GEOTOOLS` flag (true/false)
- Validates `CUSTOM_GEOWEBCACHE` flag (true/false)
- Checks `GEOSERVER_DATA_DIR` is set

### SSH Configuration
- Verifies SSH keys are present
- Checks `authorized_keys` file exists
- Validates key format (OpenSSH vs SSH2)

## Common Errors and Solutions

### 1. Volume Mount Failures

**Error:**
```
[ERROR] Volume mount failed: workspace
  Expected path: /workspace
  Directory does not exist
```

**Cause:** Docker volume not properly mounted

**Solution:**
```bash
# Check docker-compose.yml volume configuration
# Ensure volumes section includes:
volumes:
  - devdocker-workspace:/workspace

# Recreate volumes
docker-compose down -v
docker-compose up -d
```

### 2. Port Binding Conflicts

**Error:**
```
[ERROR] Port conflict detected: SSH
  Port 2222 is already in use
  Another service may be using this port
```

**Cause:** Host port already in use by another service

**Solution:**
```bash
# Option 1: Stop conflicting service
# Find process using port
netstat -tuln | grep 2222
# Or on Windows:
netstat -ano | findstr 2222

# Option 2: Change port in docker-compose.yml
ports:
  - "2223:22"  # Use different host port
```

### 3. Disk Space Exhaustion

**Error:**
```
[ERROR] Insufficient disk space for Maven repository
  Path: /root/.m2/repository
  Available: 512MB
  Required: 2048MB
```

**Cause:** Not enough disk space for Maven dependencies

**Solution:**
```bash
# Check disk space
df -h

# Clean up Docker resources
docker system prune -a --volumes

# Clean Maven repository (inside container)
rm -rf /root/.m2/repository/org/geoserver
rm -rf /root/.m2/repository/org/geotools
rm -rf /root/.m2/repository/org/geowebcache

# Or use the cleanup script (when available)
prune-maven-cache.sh 2.27
```

### 4. SSH Connection Failures

**Error:**
```
[WARNING] No SSH keys found in authorized_keys
  Path: /root/.ssh/authorized_keys
  SSH access will not work
```

**Cause:** SSH public key not configured

**Solution:**
```bash
# On host, create SSH keys directory
mkdir -p ssh-keys

# Add your public key
cat ~/.ssh/id_rsa.pub > ssh-keys/authorized_keys

# Restart container
docker-compose restart
```

### 5. Maven Build Failures

**Error:**
```
[ERROR] GeoServer build failed with exit code 1
  Check the Maven output above for details
```

**Common causes and solutions:**

**Missing dependencies:**
```bash
# Check network connectivity
ping repo.maven.apache.org

# Clear corrupted Maven cache
rm -rf /root/.m2/repository/org/geoserver
rm -rf /root/.m2/repository/org/geotools

# Rebuild
build-geoserver.sh
```

**Out of memory:**
```yaml
# Increase memory in docker-compose.yml
deploy:
  resources:
    limits:
      memory: 12G  # Increase from 8G
```

**Compilation errors:**
```bash
# Check Java version
java -version

# Ensure correct base image for GeoServer version
# GeoServer 2.27.x requires JDK 17
# GeoServer 2.28.x requires JDK 21
```

### 6. GeoServer Won't Start

**Error:**
```
[ERROR] GeoServer WAR file not found at /workspace/geoserver/src/web/app/target/geoserver.war
  Please build GeoServer first using: build-geoserver.sh
```

**Cause:** GeoServer not built yet

**Solution:**
```bash
# Build GeoServer
build-geoserver.sh

# Then start
start-geoserver.sh
```

### 7. Data Directory Issues

**Error:**
```
[WARNING] Source data directory not found at /workspace/geoserver/data/release
  GeoServer will create its own default data directory on first startup
```

**Cause:** GeoServer source code not properly mounted

**Solution:**
```bash
# Verify GeoServer is cloned in workspace volume
docker exec -it devdocker bash
cd /workspace
git clone https://github.com/your-username/geoserver.git

# Restart container to initialize data directory
docker-compose restart
```

### 8. Custom GeoTools/GeoWebCache Build Errors

**Error:**
```
[ERROR] CUSTOM_GEOTOOLS=true but GeoTools directory not found: /workspace/geotools
  Please ensure GeoTools repository is mounted at /workspace/geotools
  Or set CUSTOM_GEOTOOLS=false to use GeoTools from Maven Central
```

**Cause:** Environment flag set but repository not present

**Solution:**
```bash
# Option 1: Clone the repository
docker exec -it devdocker bash
cd /workspace
git clone https://github.com/your-username/geotools.git

# Option 2: Disable custom build
# In docker-compose.yml or .env:
CUSTOM_GEOTOOLS=false
```

## Debugging Tips

### Enable Debug Logging

```yaml
# docker-compose.yml
environment:
  - LOG_LEVEL=DEBUG
```

### Check Container Health

```bash
# View container status
docker ps

# Check resource usage
docker stats devdocker

# Inspect container
docker inspect devdocker
```

### Access Container Shell

```bash
# SSH into container
ssh -p 2222 root@localhost

# Or use docker exec
docker exec -it devdocker bash
```

### Review Build Logs

```bash
# Inside container
cd /tmp/devdocker-logs

# List all build logs
ls -lh

# View latest build
cat build-geoserver-latest.log

# Search for errors
grep -i error build-geoserver-latest.log
```

### Check Maven Repository

```bash
# Inside container
du -sh /root/.m2/repository

# Check specific artifacts
ls -lh /root/.m2/repository/org/geoserver/
ls -lh /root/.m2/repository/org/geotools/
```

### Monitor GeoServer

```bash
# Check if GeoServer is running
ps aux | grep catalina

# View GeoServer logs
tail -f /usr/local/tomcat/logs/catalina.out

# Check GeoServer web interface
curl http://localhost:8080/geoserver/web/
```

## Error Recovery

### Soft Reset (Preserve Data)

```bash
# Restart container
docker-compose restart

# Rebuild container (preserves volumes)
docker-compose up -d --build
```

### Hard Reset (Clean Slate)

```bash
# Stop and remove container
docker-compose down

# Remove volumes (WARNING: Deletes all data)
docker volume rm devdocker-home devdocker-workspace devdocker-maven-repo

# Rebuild from scratch
docker-compose up -d --build
```

### Partial Reset (Maven Only)

```bash
# Remove Maven repository volume only
docker-compose down
docker volume rm devdocker-maven-repo
docker-compose up -d
```

## Getting Help

### Collect Diagnostic Information

```bash
# Save all logs
docker logs devdocker > devdocker-logs.txt

# Inside container, collect system info
docker exec devdocker bash -c "
  echo '=== System Info ===' > /tmp/diagnostics.txt
  uname -a >> /tmp/diagnostics.txt
  echo '' >> /tmp/diagnostics.txt
  echo '=== Java Version ===' >> /tmp/diagnostics.txt
  java -version 2>> /tmp/diagnostics.txt
  echo '' >> /tmp/diagnostics.txt
  echo '=== Maven Version ===' >> /tmp/diagnostics.txt
  mvn -version >> /tmp/diagnostics.txt
  echo '' >> /tmp/diagnostics.txt
  echo '=== Disk Space ===' >> /tmp/diagnostics.txt
  df -h >> /tmp/diagnostics.txt
  echo '' >> /tmp/diagnostics.txt
  echo '=== Volume Mounts ===' >> /tmp/diagnostics.txt
  mount | grep workspace >> /tmp/diagnostics.txt
"

# Copy diagnostics to host
docker cp devdocker:/tmp/diagnostics.txt .
```

### Report Issues

When reporting issues, include:

1. Error messages from logs
2. Docker version: `docker --version`
3. Docker Compose version: `docker-compose --version`
4. Host OS and version
5. Steps to reproduce
6. Diagnostic information (see above)

## Best Practices

### Regular Maintenance

```bash
# Weekly: Clean up old build logs
docker exec devdocker bash -c "find /tmp/devdocker-logs -name '*.log' -mtime +7 -delete"

# Monthly: Prune Docker resources
docker system prune -a

# As needed: Clean Maven cache
# (Use prune-maven-cache.sh when available)
```

### Monitor Resources

```bash
# Check container resource usage
docker stats devdocker

# Check disk space regularly
docker exec devdocker df -h
```

### Backup Important Data

```bash
# Backup GeoServer data directory
docker cp devdocker:/opt/geoserver/data_dir ./backup/data_dir

# Backup custom configurations
docker cp devdocker:/root/.bashrc ./backup/
docker cp devdocker:/root/.gitconfig ./backup/
```

## Advanced Troubleshooting

### Enable Maven Debug Output

```bash
# Inside container
cd /workspace/geoserver/src
mvn clean install -X -DskipTests  # -X enables debug output
```

### Check Network Connectivity

```bash
# Inside container
ping repo.maven.apache.org
curl -I https://repo.maven.apache.org/maven2/

# Test Maven Central access
mvn dependency:get -Dartifact=org.geotools:gt-main:30.0
```

### Verify Volume Permissions

```bash
# Inside container
ls -la /workspace
ls -la /root
ls -la /root/.m2/repository

# Check ownership
stat /workspace
stat /root
```

### Debug SSH Issues

```bash
# Inside container
# Check SSH daemon status
ps aux | grep sshd

# Check SSH configuration
cat /etc/ssh/sshd_config

# Check authorized_keys
cat /root/.ssh/authorized_keys

# Test SSH from host
ssh -vvv -p 2222 root@localhost
```
