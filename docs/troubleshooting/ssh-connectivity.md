[← Troubleshooting Index](../TROUBLESHOOTING.md)

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

See [SSH Host Key Verification](../SSH-HOST-KEY-VERIFICATION.md) for detailed explanation.

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

