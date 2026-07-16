[← Troubleshooting Index](../TROUBLESHOOTING.md)

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

