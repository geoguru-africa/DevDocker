# IDE Connectivity Guide

This guide explains how to connect various IDEs to the GeoServer DevDocker environment for remote development.

## Overview

The DevDocker environment uses SSH as the primary connectivity mechanism for IDEs. This provides:

- Secure, encrypted connections
- Standard protocol supported by all major IDEs
- File system access to source code
- Remote command execution for builds and debugging
- Port forwarding for debugging and web interfaces

## SSH Configuration

### Prerequisites

- SSH client installed on your host machine
- SSH key pair (RSA, ED25519, or ECDSA)
- DevDocker container running

### Initial Setup

#### Automated Setup (Recommended)

Run the setup script:

```bash
./scripts/setup-ssh-keys.sh
```

The script will:
1. Detect existing SSH keys on your system
2. Offer to use an existing key or generate a new one
3. Configure the `authorized_keys` file
4. Provide connection instructions

#### Manual Setup

1. **Create SSH keys directory**:
   ```bash
   mkdir -p ssh-keys
   chmod 700 ssh-keys
   ```

2. **Copy your public key**:
   ```bash
   # For RSA keys
   cp ~/.ssh/id_rsa.pub ssh-keys/authorized_keys
   
   # For ED25519 keys (recommended)
   cp ~/.ssh/id_ed25519.pub ssh-keys/authorized_keys
   
   # Set correct permissions
   chmod 644 ssh-keys/authorized_keys
   ```

3. **Restart the container**:
   ```bash
   docker-compose restart
   ```

### Testing SSH Connection

Verify SSH connectivity:

```bash
./scripts/test-ssh-connection.sh
```

Or manually:

```bash
ssh -p 2222 root@localhost
```

### SSH Configuration File

For convenience, add an entry to `~/.ssh/config`:

```
Host geoserver-dev
    HostName localhost
    Port 2222
    User root
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

Then connect with:

```bash
ssh geoserver-dev
```

## IDE-Specific Configuration

### Kiro IDE

Kiro IDE provides native support for SSH-based remote development with excellent Java debugging capabilities.

#### Prerequisites

- Kiro IDE installed on your host machine
- SSH Remote extension (usually "Remote - SSH" or similar)
- SSH keys configured (see SSH Configuration section above)

#### Initial Setup

1. **Install SSH Remote Extension**:
   - Open Extensions panel (`Ctrl+Shift+X` or `Cmd+Shift+X`)
   - Search for "Remote - SSH" or "Remote Development"
   - Install the extension
   - Reload Kiro IDE if prompted

2. **Configure SSH Connection**:
   
   **Option A: Automated Setup (Recommended)**
   ```bash
   ./scripts/setup-ssh-config.sh
   ```
   This script will create/update your `~/.ssh/config` file with the DevDocker host entry.

   **Option B: Manual Configuration**
   
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

3. **Connect to DevDocker**:
   - Open Command Palette (`Ctrl+Shift+P` or `Cmd+Shift+P`)
   - Type "Remote-SSH: Connect to Host"
   - Select "devdocker" from the list
   - A new Kiro window will open connected to the container

4. **Open Workspace**:
   - In the remote window: File → Open Folder
   - Navigate to `/workspace/geoserver`
   - Click OK

5. **Install Java Extensions** (in remote environment):
   - Open Extensions panel in the remote window
   - Search for "Extension Pack for Java"
   - Install in the remote environment (SSH: devdocker)
   - This includes:
     - Language Support for Java
     - Debugger for Java
     - Maven for Java
     - Test Runner for Java

#### Debugging Setup

1. **Create Debug Configuration**:
   
   Create `.vscode/launch.json` in the GeoServer workspace:
   ```json
   {
     "version": "0.2.0",
     "configurations": [
       {
         "type": "java",
         "name": "Debug GeoServer (Remote)",
         "request": "attach",
         "hostName": "localhost",
         "port": 5005,
         "projectName": "gs-main"
       }
     ]
   }
   ```

2. **Start GeoServer with Debugging**:
   
   In the integrated terminal:
   ```bash
   start-geoserver.sh
   ```
   
   Wait for GeoServer to start (look for "Server startup" message).

3. **Attach Debugger**:
   - Press `F5` or click "Run and Debug" → "Debug GeoServer (Remote)"
   - The debugger will attach to the running GeoServer instance
   - You should see "Debugger attached" in the Debug Console

4. **Set Breakpoints and Debug**:
   - Open a Java file (e.g., `src/main/src/main/java/org/geoserver/GeoServerApplication.java`)
   - Click in the left margin to set a breakpoint (red dot appears)
   - Trigger the code path (e.g., access GeoServer web interface)
   - Execution will pause at your breakpoint

#### Features Available

- ✅ Full file system access
- ✅ Integrated terminal with SSH connection
- ✅ Remote debugging (JDWP) with hot code replacement
- ✅ Maven integration (run builds from IDE)
- ✅ Git integration (commit, push, pull from IDE)
- ✅ Code completion and IntelliSense
- ✅ Breakpoint debugging with variable inspection
- ✅ Conditional breakpoints and logpoints
- ✅ Step through code (step over, step into, step out)

#### Troubleshooting Kiro Connection

**Problem: "Remote - SSH" extension not found**

Solution: Kiro may use a different extension name. Try searching for:
- "Remote Development"
- "SSH FS"
- Or check Kiro documentation for SSH remote development

**Problem: Cannot connect to SSH host**

Solution:
1. Verify container is running: `docker ps`
2. Test SSH manually: `ssh -p 2222 root@localhost`
3. Check SSH keys: `ls -la ssh-keys/authorized_keys`
4. Review container logs: `docker logs devdocker`

**Problem: Java extensions not working in remote environment**

Solution:
1. Ensure extensions are installed in remote environment (not local)
2. Check Java is detected: Open Command Palette → "Java: Configure Java Runtime"
3. Verify JAVA_HOME: In terminal, run `echo $JAVA_HOME`
4. Reload window: Command Palette → "Developer: Reload Window"

**Problem: Debugger won't attach**

Solution:
1. Verify GeoServer is running: `ps aux | grep java`
2. Check debug port is listening: `netstat -tlnp | grep 5005`
3. Verify JAVA_OPTS includes debug agent: `echo $JAVA_OPTS`
4. Try restarting GeoServer: `stop-geoserver.sh && start-geoserver.sh`

### VSCode

VSCode supports remote development via the "Remote - SSH" extension with excellent Java debugging capabilities.

#### Quick Start

1. **Install Remote - SSH extension** in VS Code
2. **Configure SSH connection** (see SSH Configuration section above)
3. **Connect to DevDocker**: Command Palette → "Remote-SSH: Connect to Host" → "devdocker"
4. **Install Extension Pack for Java** in the remote environment
5. **Open workspace**: `/workspace/geoserver`
6. **Configure debugging**: Create `.vscode/launch.json` with JDWP attach configuration
7. **Start debugging**: Build GeoServer → Start GeoServer → Attach debugger (F5)

#### Comprehensive Guide

For detailed step-by-step instructions including:
- Extension Pack for Java installation in remote SSH context
- Complete launch.json template for JDWP debugging
- Debugging workflow (start GeoServer → attach debugger → set breakpoints)
- Hot code replacement usage and limitations
- Troubleshooting common VS Code Java extension issues
- Advanced debugging techniques (conditional breakpoints, logpoints, step filters)

See the **[VS Code Remote Debugging Guide](VSCODE-REMOTE-DEBUGGING.md)** for complete documentation.

#### Recommended Extensions

Install these extensions in the remote environment (SSH: devdocker):

- **Extension Pack for Java** (includes all below):
  - Language Support for Java (Red Hat)
  - Debugger for Java
  - Test Runner for Java
  - Maven for Java
  - Project Manager for Java
- **GitLens** (optional, for enhanced Git integration)

### IntelliJ IDEA

IntelliJ IDEA supports remote development via SFTP deployment and SSH terminal.

#### Setup Steps

1. **Configure SFTP deployment**:
   - Go to File → Settings → Build, Execution, Deployment → Deployment
   - Click "+" to add new SFTP server
   - Configure:
     - Name: `GeoServer DevDocker`
     - Type: SFTP
     - Host: `localhost`
     - Port: `2222`
     - User: `root`
     - Auth type: Key pair
     - Private key file: `~/.ssh/id_rsa`

2. **Map directories**:
   - In Deployment settings, go to "Mappings" tab
   - Local path: Your local project directory
   - Deployment path: `/workspace/geoserver`

3. **Configure remote interpreter** (optional):
   - File → Project Structure → SDKs
   - Add new SDK → Add SSH Interpreter
   - Configure SSH connection (same as above)
   - Select JDK path: `/opt/java/openjdk`

4. **Configure remote debugging**:
   - Run → Edit Configurations
   - Add new "Remote JVM Debug"
   - Host: `localhost`
   - Port: `5005`

#### Features Available

- ✅ SFTP file synchronization
- ✅ Remote debugging
- ✅ SSH terminal
- ✅ Remote Maven execution
- ⚠️ Limited IntelliSense (requires remote interpreter)

## Remote Debugging

All IDEs can connect to the JDWP debug port for remote debugging.

### Debug Configuration

The DevDocker environment exposes JDWP on port 5005:

- **Protocol**: JDWP (Java Debug Wire Protocol)
- **Port**: 5005 (mapped from container)
- **Host**: localhost
- **Suspend**: No (GeoServer starts immediately)

### IDE Debug Setup

#### Kiro IDE

1. Open Debug panel
2. Add new configuration: "Remote Java Application"
3. Configure:
   - Host: `localhost`
   - Port: `5005`
4. Start debugging

#### VSCode

**Quick Configuration**:

1. Create `.vscode/launch.json`:
   ```json
   {
     "version": "0.2.0",
     "configurations": [
       {
         "type": "java",
         "name": "Debug GeoServer (Remote)",
         "request": "attach",
         "hostName": "localhost",
         "port": 5005,
         "projectName": "gs-main"
       }
     ]
   }
   ```
2. Start GeoServer: `start-geoserver.sh`
3. Press F5 to attach debugger
4. Set breakpoints and debug

**For comprehensive VS Code debugging documentation**, including:
- Extension Pack for Java installation
- Complete debugging workflow
- Hot code replacement usage
- Troubleshooting common issues
- Advanced debugging techniques

See the **[VS Code Remote Debugging Guide](VSCODE-REMOTE-DEBUGGING.md)**.

#### IntelliJ IDEA

1. Run → Edit Configurations
2. Add new "Remote JVM Debug"
3. Configure:
   - Host: `localhost`
   - Port: `5005`
   - Debugger mode: Attach
4. Click Debug

### Hot Code Replacement

The debugger supports hot code replacement (HCR) for compatible changes:

- ✅ Method body changes
- ✅ Variable value changes
- ❌ Method signature changes (requires restart)
- ❌ Class structure changes (requires restart)

When HCR is not possible, the IDE will display a message indicating a restart is required.

## Port Forwarding

The following ports are exposed for IDE connectivity:

| Port | Service | Purpose |
|------|---------|---------|
| 2222 | SSH | IDE connectivity, terminal access |
| 5005 | JDWP | Remote debugging |
| 8080 | HTTP | GeoServer web interface |
| 8000 | HTTP | Documentation server (future) |

### Custom Port Configuration

Change ports in `.env` file:

```bash
SSH_PORT=2223
DEBUG_PORT=5006
GEOSERVER_PORT=8081
```

Then restart the container:

```bash
docker-compose down
docker-compose up -d
```

## Troubleshooting

### SSH Connection Refused

**Symptoms**: `Connection refused` when connecting via SSH

**Solutions**:
1. Verify container is running: `docker-compose ps`
2. Check SSH server is running: `docker-compose exec devdocker ps aux | grep sshd`
3. Verify port mapping: `docker-compose port devdocker 22`
4. Check container logs: `docker-compose logs devdocker`

### SSH Authentication Failed

**Symptoms**: `Permission denied (publickey)` error

**Solutions**:
1. Verify SSH keys are configured: `ls -la ssh-keys/`
2. Check key permissions: `chmod 644 ssh-keys/authorized_keys`
3. Verify correct private key: `ssh -i ~/.ssh/id_rsa -p 2222 root@localhost`
4. Check authorized_keys format (one key per line, no extra whitespace)

### Debug Connection Failed

**Symptoms**: IDE cannot connect to debug port 5005

**Solutions**:
1. Verify GeoServer is running with debug enabled
2. Check JAVA_OPTS includes debug agent: `docker-compose exec devdocker env | grep JAVA_OPTS`
3. Verify port mapping: `docker-compose port devdocker 5005`
4. Check firewall settings on host machine

### Slow File Operations

**Symptoms**: File operations are slow in IDE

**Solutions**:
1. Use native Docker volumes instead of bind mounts (Linux)
2. Enable file sharing in Docker Desktop settings (macOS/Windows)
3. Exclude large directories from IDE indexing (node_modules, target, .git)
4. Use rsync for large file transfers instead of SFTP

### IDE Cannot Find Java/Maven

**Symptoms**: IDE reports Java or Maven not found

**Solutions**:
1. Verify tools are installed: `docker-compose exec devdocker verify-tools.sh`
2. Check PATH in SSH session: `docker-compose exec devdocker echo $PATH`
3. Configure IDE to use absolute paths:
   - Java: `/opt/java/openjdk/bin/java`
   - Maven: `/usr/share/maven/bin/mvn`

## Security Considerations

### SSH Key Security

- ✅ Use strong key types (ED25519 or RSA 4096-bit)
- ✅ Protect private keys with passphrases
- ✅ Never commit private keys to version control
- ✅ Use separate keys for different environments
- ❌ Don't share private keys between developers

### Container Security

- ✅ SSH keys are mounted read-only
- ✅ Password authentication is disabled
- ✅ Root login requires public key
- ⚠️ Container runs as root (required for development tools)
- ⚠️ SSH port exposed to localhost only (not 0.0.0.0)

### Network Security

For production-like testing, consider:

- Using SSH tunneling for remote access
- Configuring firewall rules
- Using VPN for team access
- Implementing SSH bastion hosts

## Best Practices

### Development Workflow

1. **Start container**: `docker-compose up -d`
2. **Connect IDE**: Use SSH connection
3. **Open workspace**: `/workspace/geoserver`
4. **Make changes**: Edit code in IDE
5. **Build**: Run Maven from IDE or terminal
6. **Debug**: Attach debugger to port 5005
7. **Test**: Access GeoServer at http://localhost:8080

### Performance Optimization

- Use SSH connection pooling (ControlMaster in ~/.ssh/config)
- Enable compression for slow connections (Compression yes)
- Exclude unnecessary directories from IDE indexing
- Use incremental Maven builds (`mvn install -pl <module> -am`)

### Team Collaboration

- Share SSH configuration in project documentation
- Use consistent port mappings across team
- Document custom startup scripts
- Share IDE configuration files (.vscode, .idea)

## Additional Resources

- [OpenSSH Documentation](https://www.openssh.com/manual.html)
- [VSCode Remote Development](https://code.visualstudio.com/docs/remote/remote-overview)
- [IntelliJ Remote Development](https://www.jetbrains.com/help/idea/remote-development-overview.html)
- [JDWP Specification](https://docs.oracle.com/javase/8/docs/technotes/guides/jpda/jdwp-spec.html)
