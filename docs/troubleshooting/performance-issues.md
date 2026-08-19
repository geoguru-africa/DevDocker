[← Troubleshooting Index](../TROUBLESHOOTING.md)

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
docker compose restart
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

See [Configuration Reference: Architecture](../CONFIGURATION-REFERENCE.md#architecture) for details on the volume layout.

### Slow Container Startup

**Symptoms**:
- Container takes over 2 minutes to start
- SSH connection not available for a long time
- `docker compose up` hangs

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
docker compose restart
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
docker compose restart
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

