[← Troubleshooting Index](../TROUBLESHOOTING.md)

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

