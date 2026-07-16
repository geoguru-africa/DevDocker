[← Troubleshooting Index](../TROUBLESHOOTING.md)

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

