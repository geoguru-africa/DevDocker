[← Troubleshooting Index](../TROUBLESHOOTING.md)

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

See the comprehensive [VS Code Remote Debugging Guide](../VSCODE-REMOTE-DEBUGGING.md) for detailed troubleshooting, including:
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

