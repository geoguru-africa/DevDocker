[← Troubleshooting Index](../TROUBLESHOOTING.md)

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

