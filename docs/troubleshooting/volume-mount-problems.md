[← Troubleshooting Index](../TROUBLESHOOTING.md)

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

