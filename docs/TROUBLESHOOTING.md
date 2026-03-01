# GeoServer DevDocker Troubleshooting Guide

This guide covers common issues you might encounter when using the GeoServer DevDocker environment and provides practical solutions.

## Table of Contents

1. [Container Startup Issues](#container-startup-issues)
2. [Port Conflicts](#port-conflicts)
3. [SSH Connectivity Problems](#ssh-connectivity-problems)
4. [Maven Repository Issues](#maven-repository-issues)
5. [Build Failures](#build-failures)
6. [Volume Mount Problems](#volume-mount-problems)
7. [IDE Connection Issues](#ide-connection-issues)
8. [Debugging Problems](#debugging-problems)
9. [Data Directory Issues](#data-directory-issues)
10. [Performance Issues](#performance-issues)
11. [Docker and System Issues](#docker-and-system-issues)

---

## Container Startup Issues

### Container Exits Immediately After Starting

**Symptoms**:
- `docker ps` shows no running container
- `docker ps -a` shows container with "Exited" status
- Container stops within seconds of starting

**Diagnosis**:
```bash
# Check container logs for errors
docker logs devdocker

# Check container exit code
docker inspect devdocker --format='{{.State.ExitCode}}'
```

**Common Causes and Solutions**:



**1. SSH Key Mount is Read-Only**

Error message: `chmod: changing permissions of '/root/.ssh': Read-only file system`

Solution: The entrypoint script handles this automatically. If you see this error:
```bash
# Rebuild the container
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

**2. Missing SSH Keys**

Error message: `No SSH keys found in /root/.ssh/authorized_keys`

Solution:
```bash
# Run the SSH setup script
./scripts/setup-ssh-keys.sh

# Or manually copy your public key
mkdir -p ssh-keys
cp ~/.ssh/id_rsa.pub ssh-keys/authorized_keys
chmod 644 ssh-keys/authorized_keys

# Restart container
docker-compose restart
```

**3. Build Tool Verification Failed**

Error message: `ERROR: Maven not found` or `ERROR: Java version mismatch`

Solution:
```bash
# Rebuild the Docker image
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# Verify tools after restart
docker-compose exec devdocker verify-tools.sh
```



### Container Starts But SSH Server Not Running

**Symptoms**:
- Container is running (`docker ps` shows it)
- Cannot connect via SSH
- Connection refused errors

**Diagnosis**:
```bash
# Check if SSH server is running
docker exec devdocker ps aux | grep sshd

# Check SSH server logs
docker logs devdocker | grep -i ssh
```

**Solution**:
```bash
# Restart SSH service inside container
docker exec devdocker service ssh restart

# If that doesn't work, restart the container
docker-compose restart

# Verify SSH is listening
docker exec devdocker netstat -tlnp | grep :22
```

---

## Port Conflicts

### SSH Port 2222 Already in Use

**Symptoms**:
- Error: `Bind for 0.0.0.0:2222 failed: port is already allocated`
- Container fails to start

**Diagnosis**:
```bash
# Check what's using port 2222
# On Linux/macOS:
sudo lsof -i :2222

# On Windows (PowerShell):
netstat -ano | findstr :2222
```

**Solution**:



**Option 1: Change DevDocker Port**
```bash
# Edit .env file
echo "SSH_PORT=2223" >> .env

# Restart container
docker-compose down
docker-compose up -d

# Connect using new port
ssh -p 2223 root@localhost
```

**Option 2: Stop Conflicting Service**
```bash
# Find the process ID (PID) from lsof/netstat output
# On Linux/macOS:
sudo kill <PID>

# On Windows (PowerShell as Administrator):
Stop-Process -Id <PID> -Force

# Restart DevDocker
docker-compose restart
```

### JDWP Debug Port 5005 Already in Use

**Symptoms**:
- Error: `Bind for 0.0.0.0:5005 failed: port is already allocated`
- Debugging doesn't work

**Solution**:
```bash
# Change debug port in .env
echo "DEBUG_PORT=5006" >> .env

# Restart container
docker-compose down
docker-compose up -d

# Update your IDE debug configuration to use port 5006
```

### GeoServer Port 8080 Already in Use

**Symptoms**:
- Error: `Bind for 0.0.0.0:8080 failed: port is already allocated`
- Cannot access GeoServer web interface

**Solution**:
```bash
# Change GeoServer port in .env
echo "GEOSERVER_PORT=8081" >> .env

# Restart container
docker-compose down
docker-compose up -d

# Access GeoServer at http://localhost:8081/geoserver
```



---

## SSH Connectivity Problems

### Permission Denied (publickey)

**Symptoms**:
- `Permission denied (publickey)` when trying to connect
- SSH asks for password (but password auth is disabled)

**Diagnosis**:
```bash
# Test SSH connection with verbose output
ssh -v -p 2222 root@localhost

# Check if authorized_keys is configured
docker exec devdocker cat /root/.ssh/authorized_keys
```

**Solutions**:

**1. SSH Key Not Configured**
```bash
# Run automated setup
./scripts/setup-ssh-keys.sh

# Or manually:
mkdir -p ssh-keys
cp ~/.ssh/id_rsa.pub ssh-keys/authorized_keys
chmod 644 ssh-keys/authorized_keys
docker-compose restart
```

**2. Wrong SSH Key**
```bash
# Specify the correct key explicitly
ssh -i ~/.ssh/your_correct_key -p 2222 root@localhost

# Or add to ~/.ssh/config:
Host devdocker
    HostName localhost
    Port 2222
    User root
    IdentityFile ~/.ssh/your_correct_key
```

**3. SSH Key Permissions Too Open**
```bash
# Fix key permissions (Linux/macOS)
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# Retry connection
ssh -p 2222 root@localhost
```



### Host Key Verification Failed

**Symptoms**:
- Error: `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`
- Error: `Host key verification failed`
- Occurs after rebuilding container

**Explanation**: Docker containers generate new SSH host keys each time they're rebuilt. Your SSH client remembers the old key and rejects the new one as a security precaution.

**Solutions**:

**Option 1: Remove Old Host Key**
```bash
# Remove the old key for localhost:2222
ssh-keygen -R "[localhost]:2222"

# Retry connection
ssh -p 2222 root@localhost
```

**Option 2: Disable Host Key Checking (Development Only)**

Add to `~/.ssh/config`:
```
Host devdocker
    HostName localhost
    Port 2222
    User root
    IdentityFile ~/.ssh/your_key
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

**Warning**: Only use this for local development containers. Never disable host key checking for production servers.

See [SSH Host Key Verification](SSH-HOST-KEY-VERIFICATION.md) for detailed explanation.

### Connection Refused

**Symptoms**:
- `Connection refused` error
- Cannot connect even with correct keys

**Diagnosis**:
```bash
# Check if container is running
docker ps | grep devdocker

# Check if SSH port is exposed
docker port devdocker 22

# Check if SSH server is running
docker exec devdocker service ssh status
```

**Solutions**:

**1. Container Not Running**
```bash
docker-compose up -d
```

**2. SSH Server Not Running**
```bash
docker exec devdocker service ssh start
# Or restart container
docker-compose restart
```

**3. Port Not Mapped Correctly**
```bash
# Check docker-compose.yml has correct port mapping
# Should have: "2222:22"
docker-compose down
docker-compose up -d
```



---

## Maven Repository Issues

### Maven Repository Corruption

**Symptoms**:
- Error: `Checksum validation failed`
- Error: `Could not resolve dependencies`
- Error: `Corrupted artifact`
- Builds fail with dependency errors after previously working

**Diagnosis**:
```bash
# Check for corrupted artifacts
docker exec devdocker find /root/.m2/repository -name "*.lastUpdated"

# Check repository size
docker exec devdocker du -sh /root/.m2/repository
```

**Solutions**:

**Option 1: Clean Specific Artifact**
```bash
# Remove the corrupted artifact (example: GeoTools)
docker exec devdocker rm -rf /root/.m2/repository/org/geotools

# Rebuild to re-download
docker exec devdocker bash -c "cd /workspace/geoserver/src && mvn clean install -DskipTests"
```

**Option 2: Purge Local Repository**
```bash
# Use Maven's purge command
docker exec devdocker bash -c "cd /workspace/geoserver/src && mvn dependency:purge-local-repository"

# Rebuild
docker exec devdocker bash -c "cd /workspace/geoserver/src && mvn clean install -DskipTests"
```

**Option 3: Complete Repository Reset**
```bash
# Stop container
docker-compose down

# Remove Maven repository volume
docker volume rm devdocker-maven-repo

# Restart and rebuild
docker-compose up -d
ssh -p 2222 root@localhost
cd /workspace/geoserver/src
mvn clean install -DskipTests
```



### Disk Space Exhaustion

**Symptoms**:
- Error: `No space left on device`
- Maven downloads fail
- Builds fail with I/O errors

**Diagnosis**:
```bash
# Check Docker disk usage
docker system df

# Check Maven repository size
docker exec devdocker du -sh /root/.m2/repository

# Check available space in container
docker exec devdocker df -h
```

**Solutions**:

**1. Clean Maven Cache**
```bash
# Remove old GeoServer versions (keep current)
docker exec devdocker bash -c "cd /root/.m2/repository/org/geoserver && ls -d */ | grep -v '2.28' | xargs rm -rf"

# Remove old GeoTools versions
docker exec devdocker bash -c "cd /root/.m2/repository/org/geotools && ls -d */ | grep -v '31' | xargs rm -rf"

# Remove old GeoWebCache versions
docker exec devdocker bash -c "cd /root/.m2/repository/org/geowebcache && ls -d */ | grep -v '1.26' | xargs rm -rf"
```

**2. Clean Docker System**
```bash
# Remove unused Docker resources
docker system prune -a

# Remove unused volumes (WARNING: This removes ALL unused volumes)
docker volume prune
```

**3. Increase Docker Disk Space**

On Docker Desktop:
- Open Docker Desktop Settings
- Go to Resources → Advanced
- Increase "Disk image size"
- Click "Apply & Restart"

### Cannot Download Dependencies (Network Issues)

**Symptoms**:
- Error: `Could not transfer artifact`
- Error: `Connection timed out`
- Builds fail during dependency download

**Diagnosis**:
```bash
# Test network connectivity from container
docker exec devdocker ping -c 3 repo.maven.apache.org

# Test Maven Central access
docker exec devdocker curl -I https://repo.maven.apache.org/maven2/
```

**Solutions**:

**1. Check Network Connection**
```bash
# Verify host has internet access
ping repo.maven.apache.org

# Restart Docker networking
docker-compose down
docker-compose up -d
```

**2. Configure Proxy (if behind corporate firewall)**

Edit `docker-compose.yml` to add proxy settings:
```yaml
services:
  devdocker:
    environment:
      - HTTP_PROXY=http://proxy.company.com:8080
      - HTTPS_PROXY=http://proxy.company.com:8080
      - NO_PROXY=localhost,127.0.0.1
```

**3. Use Host Maven Repository as Fallback**

Uncomment in `docker-compose.yml`:
```yaml
volumes:
  - ~/.m2/repository:/root/.m2/repository-host:ro
```

This allows the container to use dependencies already downloaded on your host.



---

## Build Failures

### Maven Build Fails with Compilation Errors

**Symptoms**:
- Error: `[ERROR] COMPILATION ERROR`
- Error: `cannot find symbol`
- Build fails during compilation phase

**Diagnosis**:
```bash
# Check Java version
docker exec devdocker java -version

# Check Maven version
docker exec devdocker mvn -version

# Try clean build
docker exec devdocker bash -c "cd /workspace/geoserver/src && mvn clean compile"
```

**Solutions**:

**1. Clean Build**
```bash
# Clean and rebuild
ssh -p 2222 root@localhost
cd /workspace/geoserver/src
mvn clean install -DskipTests
```

**2. Update Source Code**
```bash
# Fetch latest changes
cd /workspace/geoserver
git fetch upstream
git merge upstream/main

# Rebuild
cd src
mvn clean install -DskipTests
```

**3. Check Java Version Compatibility**
```bash
# GeoServer 2.28+ requires Java 21
docker exec devdocker java -version

# If wrong version, rebuild container with correct base image
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Maven Build Hangs or Takes Too Long

**Symptoms**:
- Build appears stuck
- No output for several minutes
- Build takes over 30 minutes

**Diagnosis**:
```bash
# Check if Maven is actually running
docker exec devdocker ps aux | grep mvn

# Check CPU and memory usage
docker stats devdocker
```

**Solutions**:

**1. Increase Memory Allocation**

Edit `.env`:
```bash
JAVA_OPTS=-Xms1g -Xmx4g
```

Restart container:
```bash
docker-compose restart
```

**2. Reduce Parallel Build Threads**
```bash
# Build with single thread (slower but more stable)
mvn clean install -DskipTests -T 1

# Or use fewer threads
mvn clean install -DskipTests -T 2
```

**3. Skip Tests**
```bash
# Tests can take a long time
mvn clean install -DskipTests
```



### Build Script Not Found

**Symptoms**:
- Error: `build-geoserver.sh: command not found`
- Error: `build-geotrio.sh: No such file or directory`

**Diagnosis**:
```bash
# Check if scripts exist
docker exec devdocker ls -la /usr/local/bin/build-*

# Check PATH
docker exec devdocker echo $PATH
```

**Solutions**:

**1. Rebuild Container**
```bash
# Scripts are added during image build
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

**2. Use Full Path**
```bash
# Scripts are in /opt/devdocker/scripts
docker exec devdocker /opt/devdocker/scripts/build-geoserver.sh
```

**3. Add to PATH Manually**
```bash
docker exec devdocker bash -c "export PATH=/opt/devdocker/scripts:$PATH && build-geoserver.sh"
```

### Multi-Project Build Fails

**Symptoms**:
- Error: `CUSTOM_GEOTOOLS=true but /workspace/geotools not found`
- Error: `CUSTOM_GEOWEBCACHE=true but /workspace/geowebcache not found`

**Diagnosis**:
```bash
# Check environment flags
docker exec devdocker env | grep CUSTOM

# Check if repositories exist
docker exec devdocker ls -la /workspace/
```

**Solutions**:

**1. Clone Missing Repositories**
```bash
ssh -p 2222 root@localhost
cd /workspace

# Clone GeoTools if needed
git clone https://github.com/YOUR_USERNAME/geotools.git
cd geotools
git remote add upstream https://github.com/geotools/geotools.git

# Clone GeoWebCache if needed
cd /workspace
git clone https://github.com/YOUR_USERNAME/geowebcache.git
cd geowebcache
git remote add upstream https://github.com/GeoWebCache/geowebcache.git
```

**2. Disable Custom Build Flags**

Edit `.env`:
```bash
CUSTOM_GEOTOOLS=false
CUSTOM_GEOWEBCACHE=false
```

Restart:
```bash
docker-compose restart
```



---

## Volume Mount Problems

### Workspace Directory is Empty

**Symptoms**:
- `/workspace` directory exists but is empty
- Source code not visible after container restart
- `ls /workspace` shows no directories

**Diagnosis**:
```bash
# Check if volume exists
docker volume ls | grep devdocker

# Inspect volume
docker volume inspect devdocker-workspace

# Check mount points
docker inspect devdocker | grep -A 10 Mounts
```

**Solutions**:

**1. Volume Was Deleted**
```bash
# Volume needs to be recreated
docker-compose down
docker-compose up -d

# Reconnect and clone repositories
ssh -p 2222 root@localhost
cd /workspace
git clone https://github.com/YOUR_USERNAME/geoserver.git
```

**2. Wrong Container**
```bash
# Make sure you're connecting to the right container
docker ps
ssh -p 2222 root@localhost
hostname  # Should match container ID
```

### Cannot Write to Volume

**Symptoms**:
- Error: `Permission denied` when creating files
- Error: `Read-only file system`
- Cannot save files in `/workspace`

**Diagnosis**:
```bash
# Check volume permissions
docker exec devdocker ls -la /workspace

# Check if volume is read-only
docker inspect devdocker | grep -A 5 "Mounts"
```

**Solutions**:

**1. Fix Permissions**
```bash
# Fix ownership
docker exec devdocker chown -R root:root /workspace

# Fix permissions
docker exec devdocker chmod -R 755 /workspace
```

**2. Check Volume Mount**

Verify `docker-compose.yml` doesn't have `:ro` (read-only) flag:
```yaml
volumes:
  - devdocker-workspace:/workspace  # Correct
  # NOT: - devdocker-workspace:/workspace:ro
```



### Lost Work After Container Deletion

**Symptoms**:
- Deleted container and lost all source code
- Cannot find previous work

**Prevention**:
```bash
# ALWAYS push your work to GitHub before deleting containers
cd /workspace/geoserver
git status
git add .
git commit -m "Save work"
git push origin your-branch
```

**Recovery**:

If you pushed to GitHub:
```bash
# Start new container
docker-compose up -d

# Clone your fork
ssh -p 2222 root@localhost
cd /workspace
git clone https://github.com/YOUR_USERNAME/geoserver.git
cd geoserver
git checkout your-branch
```

If you didn't push (volume still exists):
```bash
# Check if volume still exists
docker volume ls | grep devdocker-workspace

# If volume exists, start container and it will mount the volume
docker-compose up -d
ssh -p 2222 root@localhost
ls /workspace/geoserver  # Your work should be here
```

If volume was deleted:
- Work is lost unless you have a backup
- Always push to GitHub regularly!

---

## IDE Connection Issues

### Kiro/VSCode Cannot Connect via Remote-SSH

**Symptoms**:
- Connection timeout
- "Could not establish connection to devdocker"
- IDE hangs on "Connecting..."

**Diagnosis**:
```bash
# Test SSH connection manually
ssh -p 2222 root@localhost

# Check container is running
docker ps | grep devdocker

# Check SSH server
docker exec devdocker service ssh status
```

**Solutions**:

**1. Verify SSH Config**

Check `~/.ssh/config`:
```
Host devdocker
    HostName localhost
    Port 2222
    User root
    IdentityFile ~/.ssh/your_key
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

**2. Test Connection First**
```bash
# Use the test script
./scripts/test-ssh-connection.sh

# Or manually
ssh -p 2222 root@localhost
```

**3. Restart SSH Service**
```bash
docker exec devdocker service ssh restart
docker-compose restart
```

**4. Check IDE Extension**

For Kiro/VSCode:
- Ensure "Remote - SSH" extension is installed
- Check extension is enabled
- Try reloading the IDE window



### VSCode Java Extension Issues

**Symptoms**:
- Java extension not working in remote environment
- No code completion or debugging support
- "Java runtime could not be located"

**Solution**:

See the comprehensive [VS Code Remote Debugging Guide](VSCODE-REMOTE-DEBUGGING.md) for detailed troubleshooting, including:
- Installing Extension Pack for Java in remote context
- Configuring Java runtime detection
- Fixing common Java extension issues
- Setting up debugging properly

Quick fix:
```bash
# Connect to remote container first
# Then install Extension Pack for Java in the remote environment
# (Not on your local machine)
```

### IntelliJ IDEA Connection Issues

**Symptoms**:
- Cannot connect via Remote Development
- SFTP deployment fails
- "Connection refused" errors

**Solutions**:

**1. Verify SSH Connection**
```bash
# Test SSH first
ssh -p 2222 root@localhost
```

**2. Configure Remote Development**

In IntelliJ:
- File → Remote Development → SSH
- Add new connection:
  - Host: localhost
  - Port: 2222
  - User: root
  - Authentication: Key pair
  - Private key: ~/.ssh/your_key

**3. Check Firewall**
```bash
# Ensure port 2222 is not blocked
# On Linux:
sudo ufw status
sudo ufw allow 2222/tcp

# On Windows:
# Check Windows Firewall settings
```

---

## Debugging Problems

### Cannot Connect Debugger to Port 5005

**Symptoms**:
- IDE shows "Connection refused" when attaching debugger
- Debug connection times out
- "Failed to connect to remote VM"

**Diagnosis**:
```bash
# Check if GeoServer is running
docker exec devdocker ps aux | grep java

# Check if debug port is listening
docker exec devdocker netstat -tlnp | grep 5005

# Check port mapping
docker port devdocker 5005
```

**Solutions**:

**1. Start GeoServer with Debugging**
```bash
ssh -p 2222 root@localhost
start-geoserver.sh
# Wait for "Server startup in [X] milliseconds"
```

**2. Verify Debug Port**
```bash
# Check JAVA_OPTS includes debug agent
docker exec devdocker env | grep JAVA_OPTS

# Should show: -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005
```

**3. Check Port Mapping**

Verify `docker-compose.yml`:
```yaml
ports:
  - "5005:5005"  # Debug port
```

**4. Restart with Debug Enabled**
```bash
docker-compose down
docker-compose up -d
ssh -p 2222 root@localhost
start-geoserver.sh
```



### Hot Code Replacement Not Working

**Symptoms**:
- Code changes don't take effect during debugging
- IDE shows "Hot code replacement failed"
- Changes require full restart

**Explanation**: Hot Code Replacement (HCR) has limitations. See the [Remote Debugging section in README](../README.md#hot-code-replacement-hcr) for details.

**What Works**:
- Method body changes (implementation only)
- Variable value changes
- Expression evaluation

**What Doesn't Work**:
- Adding/removing methods
- Changing method signatures
- Adding/removing fields
- Class structure changes

**Solutions**:

**For Compatible Changes** (method body only):
1. Set breakpoint and trigger it
2. Modify method implementation
3. Save file
4. IDE will hot-swap automatically
5. Continue execution

**For Incompatible Changes** (structure changes):
```bash
# Stop GeoServer (Ctrl+C)

# Rebuild changed module
cd /workspace/geoserver/src
mvn install -DskipTests -pl web/app -am

# Restart GeoServer
start-geoserver.sh

# Reconnect debugger
```

### Breakpoints Not Hit

**Symptoms**:
- Breakpoints show as disabled or hollow
- Debugger connected but breakpoints never trigger
- Code execution doesn't stop

**Solutions**:

**1. Verify Debugger is Attached**
```bash
# Check IDE shows "Connected" or "Attached"
# Check debug console for connection message
```

**2. Rebuild with Debug Symbols**
```bash
cd /workspace/geoserver/src
mvn clean install -DskipTests
start-geoserver.sh
```

**3. Check Breakpoint Location**
- Ensure breakpoint is on executable line (not comments or declarations)
- Verify you're debugging the correct module
- Check source code matches deployed code

**4. Trigger the Code Path**
```bash
# Access GeoServer to trigger your code
curl http://localhost:8080/geoserver/web/

# Or use browser to navigate to the feature
```



---

## Data Directory Issues

### GeoServer Cannot Find Data Directory

**Symptoms**:
- Error: `Could not find data directory`
- Error: `Unable to load configuration`
- GeoServer fails to start

**Diagnosis**:
```bash
# Check if data directory exists
docker exec devdocker ls -la /opt/geoserver/data_dir

# Check GEOSERVER_DATA_DIR environment variable
docker exec devdocker env | grep GEOSERVER_DATA_DIR

# Check GeoServer logs
docker exec devdocker tail -f /var/log/geoserver.log
```

**Solutions**:

**1. Initialize Default Data Directory**
```bash
# Copy from GeoServer source
docker exec devdocker bash -c "
  if [ ! -d /opt/geoserver/data_dir/workspaces ]; then
    cp -r /workspace/geoserver/data/* /opt/geoserver/data_dir/
  fi
"

# Restart GeoServer
docker exec devdocker pkill -f catalina
ssh -p 2222 root@localhost
start-geoserver.sh
```

**2. Verify Environment Variable**

Check `.env` file:
```bash
GEOSERVER_DATA_DIR=/opt/geoserver/data_dir
```

Restart container:
```bash
docker-compose restart
```

### Data Directory Corruption

**Symptoms**:
- Error: `Invalid configuration file`
- Error: `Failed to parse global.xml`
- GeoServer starts but features don't work

**Diagnosis**:
```bash
# Check for XML syntax errors
docker exec devdocker xmllint /opt/geoserver/data_dir/global.xml

# Check file permissions
docker exec devdocker ls -la /opt/geoserver/data_dir/
```

**Solutions**:

**1. Restore from Backup**
```bash
# If you have a backup
docker cp backup/data_dir devdocker:/opt/geoserver/

# Restart GeoServer
docker exec devdocker pkill -f catalina
ssh -p 2222 root@localhost
start-geoserver.sh
```

**2. Reinitialize Data Directory**
```bash
# Backup current (corrupted) directory
docker exec devdocker mv /opt/geoserver/data_dir /opt/geoserver/data_dir.backup

# Copy fresh default
docker exec devdocker cp -r /workspace/geoserver/data /opt/geoserver/data_dir

# Restart GeoServer
ssh -p 2222 root@localhost
start-geoserver.sh
```

**3. Fix Specific Configuration File**
```bash
# Edit the corrupted file
ssh -p 2222 root@localhost
vi /opt/geoserver/data_dir/global.xml

# Or copy from backup/default
docker exec devdocker cp /workspace/geoserver/data/global.xml /opt/geoserver/data_dir/
```



---

## Performance Issues

### Slow Build Times

**Symptoms**:
- Builds take over 15 minutes
- Maven appears to hang during compilation
- High CPU usage during builds

**Diagnosis**:
```bash
# Check system resources
docker stats devdocker

# Check Maven is using parallel builds
docker exec devdocker bash -c "cd /workspace/geoserver/src && mvn help:effective-settings | grep -A 5 threads"
```

**Solutions**:

**1. Increase Memory Allocation**

Edit `.env`:
```bash
JAVA_OPTS=-Xms2g -Xmx4g
```

Restart:
```bash
docker-compose restart
```

**2. Use Parallel Builds**
```bash
# Build with multiple threads (1 per CPU core)
mvn clean install -DskipTests -T 1C

# Or specify thread count
mvn clean install -DskipTests -T 4
```

**3. Skip Tests**
```bash
# Tests add significant time
mvn clean install -DskipTests
```

**4. Incremental Builds**
```bash
# Only rebuild changed modules
mvn install -DskipTests -pl web/app -am
```

**5. Use Named Volumes (Already Default)**

The DevDocker environment already uses named volumes for optimal performance. If you modified `docker-compose.yml` to use bind mounts, revert to named volumes:

```yaml
volumes:
  - devdocker-workspace:/workspace  # Fast
  # NOT: - ./workspace:/workspace   # Slow on Windows
```

See [Volume Strategy Documentation](VOLUME-STRATEGY.md) for details.

### Slow Container Startup

**Symptoms**:
- Container takes over 2 minutes to start
- SSH connection not available for a long time
- `docker-compose up` hangs

**Diagnosis**:
```bash
# Check container logs
docker logs devdocker

# Check startup script execution
docker exec devdocker ps aux
```

**Solutions**:

**1. Remove Custom Startup Script**

If you have a custom startup script that's slow:
```bash
# Temporarily disable
mv startup-custom.sh startup-custom.sh.disabled

# Restart
docker-compose restart
```

**2. Optimize Startup Script**

If using custom startup script:
- Remove unnecessary package installations
- Cache downloaded tools
- Use faster mirrors

**3. Check Docker Resources**

Increase Docker resources in Docker Desktop:
- Settings → Resources → Advanced
- Increase CPUs: 4+
- Increase Memory: 4GB+
- Click "Apply & Restart"



### High Memory Usage

**Symptoms**:
- Container uses excessive memory (>8GB)
- Host system becomes slow
- Out of memory errors

**Diagnosis**:
```bash
# Check container memory usage
docker stats devdocker

# Check Java heap usage
docker exec devdocker jps -lvm
```

**Solutions**:

**1. Reduce Java Heap Size**

Edit `.env`:
```bash
# Reduce from default 2GB to 1GB
JAVA_OPTS=-Xms512m -Xmx1g
```

Restart:
```bash
docker-compose restart
```

**2. Limit Container Memory**

Add to `docker-compose.yml`:
```yaml
services:
  devdocker:
    mem_limit: 4g
    memswap_limit: 4g
```

**3. Stop GeoServer When Not Needed**
```bash
# Stop GeoServer but keep container running
docker exec devdocker pkill -f catalina

# Restart when needed
ssh -p 2222 root@localhost
start-geoserver.sh
```

---

## Docker and System Issues

### Docker Daemon Not Running

**Symptoms**:
- Error: `Cannot connect to the Docker daemon`
- Error: `Is the docker daemon running?`
- `docker ps` fails

**Solutions**:

**On Linux**:
```bash
# Start Docker service
sudo systemctl start docker

# Enable on boot
sudo systemctl enable docker

# Check status
sudo systemctl status docker
```

**On macOS/Windows (Docker Desktop)**:
- Open Docker Desktop application
- Wait for "Docker Desktop is running" message
- Check system tray icon is green

### Docker Compose Version Issues

**Symptoms**:
- Error: `docker-compose: command not found`
- Error: `version is obsolete`
- Syntax errors in docker-compose.yml

**Solutions**:

**1. Install Docker Compose V2**
```bash
# Check version
docker compose version

# If using old v1 syntax, update commands:
# Old: docker-compose up
# New: docker compose up
```

**2. Update Docker Desktop**
- Download latest version from docker.com
- Install and restart

**3. Use Correct Syntax**

This project uses Compose V2 syntax. Use:
```bash
docker compose up -d      # Not: docker-compose up -d
docker compose down       # Not: docker-compose down
docker compose restart    # Not: docker-compose restart
```



### Permission Denied on Docker Commands

**Symptoms**:
- Error: `permission denied while trying to connect to the Docker daemon socket`
- Need to use `sudo` for every Docker command

**Solutions**:

**On Linux**:
```bash
# Add your user to docker group
sudo usermod -aG docker $USER

# Log out and log back in, or run:
newgrp docker

# Verify
docker ps
```

**On macOS/Windows**:
- This shouldn't happen with Docker Desktop
- Ensure Docker Desktop is running
- Try restarting Docker Desktop

### Container Name Already in Use

**Symptoms**:
- Error: `The container name "/devdocker" is already in use`
- Cannot start new container

**Solutions**:

**1. Remove Old Container**
```bash
# Stop and remove existing container
docker stop devdocker
docker rm devdocker

# Start new container
docker compose up -d
```

**2. Use Different Name**

Edit `docker-compose.yml`:
```yaml
services:
  devdocker:
    container_name: geoserver-dev-2  # Change name
```

### Image Build Fails

**Symptoms**:
- Error during `docker compose build`
- "Failed to build" messages
- Network timeout during build

**Solutions**:

**1. Clean Build**
```bash
# Remove old images and build fresh
docker compose down
docker rmi devdocker:latest
docker compose build --no-cache
docker compose up -d
```

**2. Check Network**
```bash
# Test connectivity
ping repo.maven.apache.org

# If behind proxy, add to Dockerfile:
ENV HTTP_PROXY=http://proxy.company.com:8080
ENV HTTPS_PROXY=http://proxy.company.com:8080
```

**3. Check Disk Space**
```bash
# Ensure enough space for build
df -h

# Clean Docker system
docker system prune -a
```

---

## Getting More Help

If you've tried the solutions above and still have issues:

### 1. Check Container Logs

```bash
# View all logs
docker logs devdocker

# Follow logs in real-time
docker logs -f devdocker

# View last 100 lines
docker logs --tail 100 devdocker
```

### 2. Check GeoServer Logs

```bash
# View GeoServer application logs
docker exec devdocker tail -f /var/log/geoserver.log

# View Tomcat logs
docker exec devdocker tail -f /usr/local/tomcat/logs/catalina.out
```

### 3. Inspect Container

```bash
# Get detailed container information
docker inspect devdocker

# Check environment variables
docker exec devdocker env

# Check running processes
docker exec devdocker ps aux
```

### 4. Test Components Individually

```bash
# Test SSH
ssh -v -p 2222 root@localhost

# Test Maven
docker exec devdocker mvn --version

# Test Java
docker exec devdocker java -version

# Test network
docker exec devdocker ping -c 3 repo.maven.apache.org
```

### 5. Report Issues

When reporting issues, include:
- Operating system and version
- Docker version: `docker --version`
- Docker Compose version: `docker compose version`
- Container logs: `docker logs devdocker`
- Steps to reproduce the issue
- Error messages (full text)

### 6. Community Resources

- GeoServer Mailing List: https://geoserver.org/comm/
- GeoServer GitHub Issues: https://github.com/geoserver/geoserver/issues
- Docker Documentation: https://docs.docker.com/

---

## Quick Reference

### Essential Commands

```bash
# Start environment
docker compose up -d

# Stop environment
docker compose down

# Restart environment
docker compose restart

# View logs
docker logs devdocker

# Connect via SSH
ssh -p 2222 root@localhost

# Check container status
docker ps

# Check volumes
docker volume ls

# Clean everything (WARNING: Deletes all data)
docker compose down -v
docker system prune -a
```

### Common File Locations

- **Source code**: `/workspace/geoserver`, `/workspace/geotools`, `/workspace/geowebcache`
- **Maven repository**: `/root/.m2/repository`
- **Data directory**: `/opt/geoserver/data_dir`
- **GeoServer logs**: `/var/log/geoserver.log`
- **Tomcat logs**: `/usr/local/tomcat/logs/catalina.out`
- **Build scripts**: `/opt/devdocker/scripts/`
- **SSH config**: `/root/.ssh/`

### Environment Variables

- `SSH_PORT`: SSH port (default: 2222)
- `DEBUG_PORT`: JDWP debug port (default: 5005)
- `GEOSERVER_PORT`: GeoServer web port (default: 8080)
- `CUSTOM_GEOTOOLS`: Build local GeoTools (default: false)
- `CUSTOM_GEOWEBCACHE`: Build local GeoWebCache (default: false)
- `JAVA_OPTS`: JVM options (default: -Xms512m -Xmx2g)
- `GEOSERVER_DATA_DIR`: Data directory path (default: /opt/geoserver/data_dir)

---

**Last Updated**: 2024
**Version**: 1.0
