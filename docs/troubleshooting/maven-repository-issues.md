[← Troubleshooting Index](../TROUBLESHOOTING.md)

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
docker compose down

# Remove Maven repository volume
docker volume rm devdocker-maven-repo

# Restart and rebuild
docker compose up -d
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
docker compose down
docker compose up -d
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

