[← Troubleshooting Index](../TROUBLESHOOTING.md)

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

