# GeoServer DevDocker Environment

A containerized development environment for contributing to the GeoServer ecosystem (GeoServer, GeoTools, and GeoWebCache) with minimal setup.

## Features

- **Pre-configured Build Tools**: JDK 21, Maven 3.8+, Git (auto-selects correct Java/Tomcat version)
- **IDE Connectivity**: SSH access for VSCode, IntelliJ IDEA, and Kiro
- **Remote Debugging**: JDWP support for live debugging
- **Fast Builds**: Named volumes provide 16-17x faster builds on Windows vs bind mounts
- **Smart Maven Fallback**: Local cache → Host repo → Classroom mirror → Maven Central
- **Configurable Multi-Project Builds**: Optional GeoTools/GeoWebCache integration
- **Developer Extensibility**: Install custom tools and persist configurations

## Quick Start

### Prerequisites

- Docker Engine 20.10+ or Docker Desktop
- Docker Compose 2.0+
- SSH client (for connecting to the container)

### Setup

1. **Clone this repository**:
   ```bash
   git clone https://github.com/geoguru-africa/DevDocker.git
   cd DevDocker
   ```

2. **Configure environment** (optional):
   ```bash
   cp .env.example .env
   # Edit .env to customize ports or enable Maven mirror
   ```

3. **Start the DevDocker environment**:
   ```bash
   docker-compose up -d
   ```

4. **Connect via SSH**:
   ```bash
   ssh -p 2222 root@localhost
   # You'll start in /workspace directory
   ```

5. **Clone GeoServer inside the container**:
   ```bash
   # You're now inside the container at /workspace
   git clone https://github.com/YOUR_USERNAME/geoserver.git
   cd geoserver
   git remote add upstream https://github.com/geoserver/geoserver.git
   git fetch upstream --tags
   ```

6. **Build GeoServer**:
   ```bash
   build-geoserver.sh
   # First build: ~10-15 minutes (downloads dependencies)
   # Subsequent builds: ~2-3 minutes
   ```

That's it! You're ready to develop.

## Source Code Setup

The DevDocker environment uses Docker named volumes for optimal build performance. Source code is cloned inside the container, not on your host machine.

### Why Named Volumes?

Named volumes provide 16-17x faster build performance on Windows compared to bind mounts:
- **Windows bind mount**: 37-40 minutes per build
- **Named volume**: 2-3 minutes per build

### Creating Your Fork

Before cloning, create a personal fork on GitHub:

1. Navigate to https://github.com/geoserver/geoserver
2. Click the "Fork" button in the top-right corner
3. Select your GitHub account as the destination
4. Wait for GitHub to create your fork

### Initial Setup

After starting the container, connect via SSH and clone your fork:

```bash
# Connect to container
ssh -p 2222 root@localhost

# You'll start in /workspace directory
pwd  # Shows: /workspace

# Clone your GeoServer fork
git clone https://github.com/YOUR_USERNAME/geoserver.git
cd geoserver

# Configure upstream remote
git remote add upstream https://github.com/geoserver/geoserver.git
git fetch upstream --tags
```

### Working with Specific Versions

To work with a specific GeoServer release (e.g., 2.28.2):

```bash
# Inside the container
cd /workspace/geoserver

# Fetch tags from upstream
git fetch upstream --tags

# List available tags
git tag -l | grep "^2\." | sort -V | tail -20

# Checkout specific version
git checkout 2.28.2

# Or create a branch from the tag
git checkout -b my-feature-2.28.2 2.28.2
```

**Note**: Tags are not synced to your fork automatically. Always fetch them from upstream.

### Keeping Your Fork Updated

To sync your fork with the official repository:

```bash
# Inside the container
cd /workspace/geoserver

# Fetch latest changes
git fetch upstream

# Switch to main branch
git checkout main

# Merge upstream changes
git merge upstream/main

# Push to your fork
git push origin main
```

### Contributing Changes

When you're ready to contribute:

```bash
# Inside the container
cd /workspace/geoserver

# Create a feature branch
git checkout -b feature/my-improvement

# Make your changes and commit
git add .
git commit -m "Add my improvement"

# Push to your fork
git push origin feature/my-improvement
```

Then create a Pull Request on GitHub:
1. Navigate to your fork on GitHub
2. Click "Compare & pull request"
3. Fill in the PR description
4. Submit to the upstream repository

### Optional: GeoTools and GeoWebCache

If you need to modify GeoTools or GeoWebCache:

```bash
# Inside the container at /workspace
git clone https://github.com/YOUR_USERNAME/geotools.git
cd geotools
git remote add upstream https://github.com/geotools/geotools.git
git fetch upstream --tags
cd ..

git clone https://github.com/YOUR_USERNAME/geowebcache.git
cd geowebcache
git remote add upstream https://github.com/GeoWebCache/geowebcache.git
git fetch upstream --tags
cd ..
```

Then enable custom builds in `.env` on your host:

```bash
CUSTOM_GEOTOOLS=true
CUSTOM_GEOWEBCACHE=true
```

Restart the container: `docker-compose restart`

### Accessing Files from Host

Since source code is in a named volume, you can't directly access it from your host. Use these methods:

**Copy files out of container**:
```bash
docker cp devdocker:/workspace/geoserver/file.txt .
```

**Copy files into container**:
```bash
docker cp file.txt devdocker:/workspace/geoserver/
```

**Edit via SSH**: Connect with VSCode Remote-SSH or your preferred IDE for seamless editing.

### Backing Up Your Work

Your work is safe in the named volume, but always push to GitHub:

```bash
# Inside the container
cd /workspace/geoserver
git status  # Check for uncommitted changes
git push origin your-branch
```

**Volume backup** (optional):
```bash
# From host
docker run --rm -v devdocker-workspace:/data -v $(pwd):/backup ubuntu tar czf /backup/workspace-backup.tar.gz -C /data .
```

### Troubleshooting

**Problem: Lost connection during git clone**

Solution: Reconnect and check if clone completed:
```bash
ssh -p 2222 root@localhost
cd /workspace/geoserver
git status  # If this works, clone completed
```

If incomplete, remove and re-clone:
```bash
rm -rf /workspace/geoserver
git clone https://github.com/YOUR_USERNAME/geoserver.git
```

**Problem: Can't see source code from host**

Solution: This is expected with named volumes. Use:
- SSH to connect and edit in container
- `docker cp` to copy files
- VSCode Remote-SSH or your preferred IDE for seamless editing

**Problem: Workspace is empty after container restart**

Solution: Named volumes persist. Check if you're in the right container:
```bash
docker ps  # Verify container name
ssh -p 2222 root@localhost
ls -la /workspace/
```

If truly empty, the volume may have been deleted. Re-clone your repositories.

## Configuration

### Environment Variables

Configure the environment by editing the `.env` file in the project root. Copy `.env.example` to `.env` to get started:

```bash
cp .env.example .env
```

**Available Variables**:

| Variable | Description | Default | Notes |
|----------|-------------|---------|-------|
| `SSH_PORT` | SSH port for IDE connectivity | `2222` | Change if port 2222 is already in use |
| `DEBUG_PORT` | JDWP debug port | `5005` | Used for remote debugging |
| `GEOSERVER_PORT` | GeoServer web interface port | `8080` | Access GeoServer at http://localhost:8080/geoserver |
| `CUSTOM_GEOTOOLS` | Build local GeoTools | `false` | Set to `true` to compile GeoTools from source |
| `CUSTOM_GEOWEBCACHE` | Build local GeoWebCache | `false` | Set to `true` to compile GeoWebCache from source |
| `MAVEN_MIRROR_URL` | Maven repository mirror | (empty) | Optional: Set for classroom/team shared cache |
| `GEOSERVER_DATA_DIR` | Data directory location | `/opt/geoserver/data_dir` | Usually no need to change |
| `JAVA_OPTS` | JVM options | `-Xms512m -Xmx2g` | Adjust memory based on your system |

**Example `.env` file**:

```bash
# Port Configuration
SSH_PORT=2222
DEBUG_PORT=5005
GEOSERVER_PORT=8080

# Build Configuration
CUSTOM_GEOTOOLS=false
CUSTOM_GEOWEBCACHE=false

# Optional: Classroom Mode
# MAVEN_MIRROR_URL=http://presenter-host:8081/repository/maven-public/

# Optional: JVM Memory Configuration
# JAVA_OPTS=-Xms1g -Xmx4g
```

**Applying Changes**:

After modifying `.env`, restart the container for changes to take effect:

```bash
docker-compose down
docker-compose up -d
```

### Multi-Project Development

By default, DevDocker builds GeoServer only, using GeoTools and GeoWebCache from Maven Central. This is the recommended approach for most GeoServer development work.

#### Understanding CUSTOM_GEOTOOLS and CUSTOM_GEOWEBCACHE Flags

The `CUSTOM_GEOTOOLS` and `CUSTOM_GEOWEBCACHE` environment flags control whether the build system compiles and uses local versions of these dependencies:

**When flags are `false` (default)**:
- GeoServer builds using GeoTools and GeoWebCache artifacts from Maven Central
- Faster builds (no need to compile dependencies)
- Suitable for GeoServer-only development
- You can still have GeoTools/GeoWebCache repositories cloned for reference without compiling them

**When flags are `true`**:
- The build system compiles GeoTools/GeoWebCache from source
- Installs compiled artifacts to local Maven repository
- GeoServer build uses these local artifacts instead of Maven Central versions
- Required when you need to test GeoServer with modified GeoTools/GeoWebCache code
- Significantly longer build times (first build can take 30+ minutes)

**Use Cases**:

1. **GeoServer-only development** (most common):
   ```bash
   CUSTOM_GEOTOOLS=false
   CUSTOM_GEOWEBCACHE=false
   ```
   Clone only GeoServer, build in ~2-3 minutes.

2. **Reference other projects without building**:
   ```bash
   CUSTOM_GEOTOOLS=false
   CUSTOM_GEOWEBCACHE=false
   ```
   Clone GeoTools/GeoWebCache for code reference, but don't compile them.

3. **Testing GeoServer with modified GeoTools**:
   ```bash
   CUSTOM_GEOTOOLS=true
   CUSTOM_GEOWEBCACHE=false
   ```
   Modify GeoTools code, test integration with GeoServer.

4. **Full multi-project development**:
   ```bash
   CUSTOM_GEOTOOLS=true
   CUSTOM_GEOWEBCACHE=true
   ```
   Work on all three projects simultaneously.

#### Enabling Custom Builds

To use local GeoTools/GeoWebCache builds:

1. **Clone the repositories inside the container**:
   ```bash
   # Connect to container
   ssh -p 2222 root@localhost
   
   # Clone GeoTools (if needed)
   cd /workspace
   git clone https://github.com/YOUR_USERNAME/geotools.git
   cd geotools
   git remote add upstream https://github.com/geotools/geotools.git
   git fetch upstream --tags
   
   # Clone GeoWebCache (if needed)
   cd /workspace
   git clone https://github.com/YOUR_USERNAME/geowebcache.git
   cd geowebcache
   git remote add upstream https://github.com/GeoWebCache/geowebcache.git
   git fetch upstream --tags
   ```

2. **Set the corresponding flags in `.env` on your host**:
   ```bash
   CUSTOM_GEOTOOLS=true
   CUSTOM_GEOWEBCACHE=true
   ```

3. **Restart the container**:
   ```bash
   docker-compose restart
   ```

4. **Build using the orchestration script**:
   ```bash
   # Connect to container
   ssh -p 2222 root@localhost
   
   # Build all enabled projects
   build-geotrio.sh
   ```

The `build-geotrio.sh` script automatically detects which flags are enabled and builds projects in the correct order: GeoTools → GeoWebCache → GeoServer.

## IDE Connectivity

### SSH Access Setup

The DevDocker environment uses SSH for IDE connectivity. Follow these steps to configure SSH access:

#### Option 1: Automated Setup (Recommended)

Run the SSH setup helper script:

```bash
./scripts/setup-ssh-keys.sh
```

This script will:
- Detect existing SSH keys on your system
- Offer to use an existing key or generate a new one
- Configure the authorized_keys file automatically
- Provide connection instructions

#### Option 2: Manual Setup

1. **Create the ssh-keys directory**:
   ```bash
   mkdir -p ssh-keys
   chmod 700 ssh-keys
   ```

2. **Copy your public key**:
   ```bash
   cp ~/.ssh/id_rsa.pub ssh-keys/authorized_keys
   chmod 644 ssh-keys/authorized_keys
   ```

3. **Restart the container**:
   ```bash
   docker-compose restart
   ```

#### Connecting via SSH

Once configured, connect to the container:

```bash
ssh -p 2222 root@localhost
```

Or with a specific key:

```bash
ssh -i ~/.ssh/your_key -p 2222 root@localhost
```

**Note**: Password authentication is disabled for security. Only public key authentication is supported.

### Kiro IDE

Kiro IDE provides excellent support for remote development via SSH. Follow these steps to connect:

#### 1. Install SSH Remote Extension

Kiro IDE requires an SSH extension to connect to remote development environments. The extension enables you to work with files and run commands inside the DevDocker container as if they were local.

**Installation Steps**:

1. **Open Extensions Panel**:
   - Press `Ctrl+Shift+X` (Windows/Linux) or `Cmd+Shift+X` (macOS)
   - Or click the Extensions icon in the Activity Bar (left sidebar)

2. **Search for SSH Extension**:
   - Type "Remote - SSH" or "Remote SSH" in the search box
   - Look for the official extension (usually published by Microsoft or the Kiro team)
   - Common extension names:
     - "Remote - SSH"
     - "Remote Development"
     - "SSH FS" (alternative)

3. **Install the Extension**:
   - Click the "Install" button
   - Wait for installation to complete
   - If prompted, click "Reload" or restart Kiro IDE

4. **Verify Installation**:
   - After reload, you should see a new icon in the Activity Bar (usually a monitor with arrows)
   - Or check the Command Palette (Ctrl+Shift+P) for "Remote-SSH" commands

**Note**: Some Kiro distributions may have SSH support built-in. If you see "Remote-SSH" commands in the Command Palette without installing an extension, you're ready to proceed.

#### 2. Configure SSH Connection

**Option A: Automated Setup (Recommended)**

Run the automated SSH config setup script:

```bash
./scripts/setup-ssh-config.sh
```

This script will:
- Detect all SSH private keys (including .pem files)
- Let you select which key to use
- Create or update your `~/.ssh/config` file with the DevDocker host entry
- Use the correct path format for your operating system (Windows/Linux/macOS)

After running the script, you can connect using the host alias:
```bash
ssh devdocker
```

**Option B: Manual SSH Config**

Add to your `~/.ssh/config` file:

**On Linux/macOS**:
```
Host devdocker
    HostName localhost
    Port 2222
    User root
    IdentityFile ~/.ssh/your_key
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

**On Windows** (note the path format):
```
Host devdocker
    HostName localhost
    Port 2222
    User root
    IdentityFile C:/Users/YourUsername/.ssh/your_key.pem
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

**Important Notes**:
- **Windows paths**: Use forward slashes (`/`) and the `C:/Users/` format, not Unix-style `/c/Users/` paths
- **Host key verification**: `StrictHostKeyChecking no` and `UserKnownHostsFile /dev/null` disable SSH host key verification, which prevents warnings when rebuilding the container (new host keys are generated each time). This is safe for local development but should not be used for production servers. See [SSH Host Key Verification](docs/SSH-HOST-KEY-VERIFICATION.md) for details.

**Option C: Test SSH Connection**

Verify SSH connectivity before connecting with IDE:

```bash
./scripts/test-ssh-connection.sh
```

This script will:
- Check if the container is running
- Detect available SSH keys
- Let you select which key to use (if multiple found)
- Test the SSH connection
- Display workspace directories if successful

#### 3. Connect to DevDocker

**Method 1: Using SSH Config File (Recommended)**

1. Configure SSH using Option A or B above
2. In Kiro, open Command Palette (`Ctrl+Shift+P` or `Cmd+Shift+P`)
3. Type "Remote-SSH: Connect to Host"
4. Select "devdocker" from the list
5. A new Kiro window will open connected to the container

**Method 2: Using "Open SSH Configuration File" Command**

The "Open Remote - SSH" extension provides a convenient way to edit your SSH config directly:

1. Open Command Palette (`Ctrl+Shift+P` or `Cmd+Shift+P`)
2. Type "Remote-SSH: Open SSH Configuration File..."
3. Select your SSH config file (usually `~/.ssh/config` or `C:\Users\YourUsername\.ssh\config`)
4. Add the DevDocker host entry (see Option B above)
5. Save the file
6. Use "Remote-SSH: Connect to Host" and select "devdocker"

**Method 3: Direct Connection (No Config File)**

1. Open Command Palette
2. Type "Remote-SSH: Connect to Host"
3. Select "Add New SSH Host..."
4. Enter the full SSH command:
   - Linux/macOS: `ssh -i ~/.ssh/your_key -p 2222 root@localhost`
   - Windows: `ssh -i C:/Users/YourUsername/.ssh/your_key.pem -p 2222 root@localhost`
5. Select which config file to save to (or skip)
6. Connect to the newly added host

#### 4. Verify Connection

Once connected, verify everything is working:

**Open a Terminal in the Remote Container**:
- In the new Kiro window, open a terminal (`Ctrl+` ` or Terminal → New Terminal)
- You should see a prompt like `root@<container-id>:~#`

**Test 1: Verify Location**
```bash
pwd        # Should show /root
hostname   # Should show the container ID
```

**Test 2: Verify Build Tools**
```bash
java -version   # Should show OpenJDK 21
mvn -version    # Should show Maven 3.8+
git --version   # Should show Git 2.x
```

**Test 3: Check Workspace Directories**
```bash
ls -la /workspace/
```
You should see `geoserver`, `geotools`, and `geowebcache` directories.

**Test 4: Verify You're in the Container**
```bash
cat /etc/os-release   # Should show Ubuntu
ps aux | grep sshd    # Should show SSH server running
```

**Test 5: Test File Editing**
```bash
echo "Hello from DevDocker" > /workspace/test.txt
cat /workspace/test.txt
```

Then in Kiro:
- Open the file explorer
- Navigate to `/workspace/test.txt`
- Edit the file and save
- Verify changes from terminal: `cat /workspace/test.txt`

#### 5. Open Workspace

Once connected:
1. File → Open Folder
2. Navigate to `/workspace/geoserver`
3. Click OK

You now have full IDE access to the GeoServer source code with all build tools available in the integrated terminal.

#### Troubleshooting Kiro Connection

**Connection Refused**:
- Verify container is running: `docker ps`
- Check SSH server is running: `docker logs devdocker | grep SSH`
- Verify port mapping: `docker port devdocker 22`

**Permission Denied**:
- Verify SSH keys are configured: `docker exec devdocker cat /root/.ssh/authorized_keys`
- Check key permissions on host: `ls -la ~/.ssh/id_rsa*`
- Try with explicit key: `ssh -i ~/.ssh/id_rsa -p 2222 root@localhost`

**Host Key Verification Failed**:
- This happens when you rebuild the container (new SSH host keys are generated)
- The automated setup script already configures this, but if you set up manually:
  - Add to `~/.ssh/config`:
    ```
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ```
  - Or remove old host key after each rebuild: `ssh-keygen -R "[localhost]:2222"`
- See [SSH Host Key Verification](docs/SSH-HOST-KEY-VERIFICATION.md) for detailed explanation

### VSCode

1. Install the "Remote - SSH" extension
2. Add SSH configuration to `~/.ssh/config`:
   ```
   Host geoserver-dev
       HostName localhost
       Port 2222
       User root
       IdentityFile ~/.ssh/your_key
   ```
3. Connect using "Remote-SSH: Connect to Host"

### IntelliJ IDEA

1. Go to File → Settings → Build, Execution, Deployment → Deployment
2. Add new SFTP server:
   - Host: localhost
   - Port: 2222
   - User: root
   - Auth type: Key pair
   - Private key file: ~/.ssh/your_key
3. Map remote path `/workspace/geoserver` to local project

## Build Tools

The environment includes:

- **Java**: OpenJDK 21 (Temurin distribution) for GeoServer 2.28.x
- **Maven**: 3.8+ with local repository caching
- **Git**: 2.x for source control
- **SSH Server**: OpenSSH for IDE connectivity

Verify tools are working:

```bash
docker-compose exec devdocker verify-tools.sh
```

## Maven Repository Management

The DevDocker environment uses a smart fallback chain for Maven dependency resolution, optimizing for both performance and flexibility.

### How It Works

Maven uses a fallback chain for dependency resolution:

1. **Local repository**: `/root/.m2/repository` (devdocker-maven-repo volume) - fast, persistent
2. **Host repository** (optional): Your `~/.m2/repository` if mounted - read-only fallback
3. **Classroom mirror** (optional): If `MAVEN_MIRROR_URL` is set - shared team cache
4. **Maven Central**: Final fallback - downloads from internet

The local repository is stored in a Docker named volume for optimal performance. If a dependency isn't found there, Maven automatically checks the host repository (if mounted), then the classroom mirror (if configured), and finally Maven Central.

See [Maven Fallback Chain Documentation](docs/MAVEN-FALLBACK-CHAIN.md) for detailed configuration.

### Benefits

- **Fast Builds**: Named volume provides native Linux filesystem performance (16-17x faster on Windows)
- **Smart Fallback**: Automatically uses host repository if available, reducing downloads
- **Offline Capable**: Once dependencies are cached, builds work without internet
- **Team Friendly**: Optional classroom mirror for shared team environments
- **Easy Management**: Standard Maven commands work for cache inspection and cleanup

### Repository Configuration

The Maven `settings.xml` is dynamically configured at container startup with:

- **Local repository**: `/root/.m2/repository` (devdocker-maven-repo named volume)
- **Host repository mirror** (optional): If `~/.m2/repository` is mounted, configured as read-only fallback
- **Classroom mirror** (optional): If `MAVEN_MIRROR_URL` environment variable is set
- **OSGeo repositories**: Release and snapshot repositories for GeoServer dependencies
- **Maven Central**: Standard Maven Central repository (final fallback)
- **Update policy**: `never` for releases (use cached versions)
- **Parallel builds**: Configured to use 1 thread per CPU core (`-T 1C`)

To enable host repository fallback, uncomment the bind mount in `docker-compose.yml`:
```yaml
# Uncomment to enable host repo fallback:
- ~/.m2/repository:/root/.m2/repository-host:ro
```

On Windows, use the full path format:
```yaml
- C:/Users/YourUsername/.m2/repository:/root/.m2/repository-host:ro
```

### Classroom Mode (Post-MVP)

For classroom or team environments, you can configure a shared Maven repository proxy:

1. **Set up a Maven repository server** (e.g., Nexus, Artifactory) on the presenter's machine
2. **Configure students' containers** to use the proxy by setting `MAVEN_MIRROR_URL` in `.env`:
   ```bash
   MAVEN_MIRROR_URL=http://presenter-host:8081/repository/maven-public/
   ```
3. **Restart containers** to apply the configuration:
   ```bash
   docker-compose restart
   ```

This reduces network bandwidth by caching dependencies once on the presenter's server.

### Offline Development

Once you've built GeoServer at least once, all dependencies are cached. To verify offline capability:

```bash
# Disconnect from network or set Maven to offline mode
docker-compose exec devdocker bash -c "sed -i 's/<offline>false<\/offline>/<offline>true<\/offline>/' /root/.m2/settings.xml"

# Build should succeed using cached dependencies
docker-compose exec devdocker bash -c "cd /workspace/geoserver/src && mvn clean install -DskipTests"
```

### Managing the Maven Cache

**View cache size**:
```bash
docker-compose exec devdocker du -sh /root/.m2/repository
```

**Clear specific artifacts** (e.g., to force re-download):
```bash
docker-compose exec devdocker rm -rf /root/.m2/repository/org/geotools
```

**Reset entire cache**:
```bash
docker-compose down
docker volume rm devdocker-maven-repo
docker-compose up -d
```

### Concurrent Access Safety

Maven handles concurrent access to the local repository automatically through file locking. Multiple build processes can safely access the same repository without corruption.

## Remote Debugging

The DevDocker environment includes full JDWP (Java Debug Wire Protocol) support for remote debugging with your IDE.

### Debug Configuration

The debug port (5005) is automatically exposed and configured when you start the container. JDWP is enabled with the following parameters:

- **Transport**: Socket (dt_socket)
- **Mode**: Server (listens for debugger connections)
- **Suspend**: No (GeoServer starts immediately without waiting for debugger)
- **Address**: *:5005 (listens on all interfaces)

### Connecting Your IDE

#### VS Code (Recommended)

For comprehensive VS Code debugging documentation, see the **[VS Code Remote Debugging Guide](docs/VSCODE-REMOTE-DEBUGGING.md)**.

**Quick Start**:
1. Install "Remote - SSH" extension
2. Install "Extension Pack for Java" in remote environment
3. Create `.vscode/launch.json`:
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
4. Start GeoServer: `start-geoserver.sh`
5. Press F5 to attach debugger

The comprehensive guide includes:
- Step-by-step Extension Pack for Java installation
- Complete debugging workflow
- Hot code replacement usage and limitations
- Troubleshooting common VS Code Java extension issues
- Advanced debugging techniques

#### Kiro IDE

1. **Start GeoServer with debugging**:
   ```bash
   docker-compose exec devdocker start-geoserver.sh
   ```

2. **Configure debug connection** in Kiro:
   - Open Run/Debug Configurations
   - Add new "Remote JVM Debug" configuration
   - Set Host: `localhost`
   - Set Port: `5005`
   - Click "Debug"

3. **Set breakpoints** in your code and start debugging

#### IntelliJ IDEA

1. Go to Run → Edit Configurations
2. Add new "Remote JVM Debug" configuration
3. Set Host: `localhost`, Port: `5005`
4. Click Debug

### Hot Code Replacement (HCR)

The JDWP debugger supports hot code replacement, allowing you to modify code during a debug session without restarting GeoServer. However, there are important limitations:

#### What Works (Compatible Changes)

Hot code replacement works for:
- **Method body changes**: Modifying the implementation of existing methods
- **Variable values**: Changing local variable values during debugging
- **Expression evaluation**: Testing code snippets in the debug console

Example workflow:
1. Set a breakpoint in a method
2. Trigger the breakpoint by accessing GeoServer
3. Modify the method implementation in your IDE
4. Save the file (IDE will hot-swap the new bytecode)
5. Continue execution - the new code runs immediately

#### What Doesn't Work (Incompatible Changes)

Hot code replacement **does NOT work** for structural changes:
- **Adding or removing methods**: Requires full restart
- **Changing method signatures**: Parameter types, return types, or method names
- **Adding or removing fields**: Class structure changes
- **Changing class hierarchy**: Modifying extends or implements clauses
- **Adding or removing classes**: New classes or deleted classes

#### Feedback and Restart Workflow

When you attempt an incompatible change:

1. **IDE Feedback**: Your IDE will display a message like:
   - "Hot code replacement failed - add method not implemented"
   - "Changes require restart"

2. **Manual Restart Required**: For incompatible changes, you must:
   ```bash
   # Stop GeoServer (Ctrl+C in the terminal running start-geoserver.sh)
   
   # Rebuild the changed module
   docker-compose exec devdocker bash -c "cd /workspace/geoserver/src && mvn install -DskipTests -pl web/app -am"
   
   # Restart GeoServer
   docker-compose exec devdocker start-geoserver.sh
   ```

3. **Automatic Restart** (Future): The DevDocker environment will include automatic restart detection for incompatible changes in a future update.

#### Best Practices for HCR

To maximize hot code replacement effectiveness:

1. **Design for HCR**: Keep method signatures stable during active development
2. **Incremental changes**: Make small, method-level changes rather than large structural refactors
3. **Test in debug mode**: Use HCR for rapid iteration on business logic
4. **Restart for structure**: Plan structural changes for dedicated rebuild cycles

#### Debugging Tips

- **Conditional breakpoints**: Right-click breakpoint → Add condition (e.g., `request.getParameter("layer").equals("roads")`)
- **Evaluate expressions**: Select code → Right-click → Evaluate Expression
- **Watch variables**: Add variables to watch window for continuous monitoring
- **Step filters**: Configure your IDE to skip framework code (e.g., Spring, Servlet API)

### Debugging Performance

JDWP has minimal performance impact when no debugger is attached. When debugging:
- **Breakpoints**: Pause execution completely (expected behavior)
- **Step operations**: Slow down execution significantly (expected)
- **No breakpoints**: Near-normal performance even with debugger attached

For performance testing, disable debugging by setting `suspend=n` (already configured) or disconnect the debugger.

## Data Directory Management

The DevDocker environment automatically manages the GeoServer data directory, which contains configuration, styles, workspaces, and data stores.

### Default Data Directory

On first run, the container automatically initializes a default data directory from the GeoServer source repository:

- **Location**: `/opt/geoserver/data_dir` (inside container)
- **Host Location**: `../geoserver-data` (bind mounted, one level up from devdocker directory)
- **Source**: `/workspace/geoserver/data/release` (full sample data with demo layers)
- **Persistence**: Stored as bind mount, persists across container restarts and visible on host

If the release data directory is not found, GeoServer will create its own default data directory on first startup.

### Initialization Process

The entrypoint script automatically handles data directory initialization:

1. **First Run**: Copies the minimal data directory from GeoServer source to `/opt/geoserver/data_dir`
2. **Subsequent Runs**: Uses the existing data directory (no re-copying)
3. **Persistence**: All changes to the data directory persist across container restarts and are visible on the host at `../geoserver-data` (one level up from devdocker directory)

### Verifying Data Directory

Test the data directory setup:

```bash
docker-compose exec devdocker test-data-directory.sh
```

This script verifies:
- `GEOSERVER_DATA_DIR` environment variable is set
- Data directory exists and is initialized
- Key configuration files are present (global.xml, logging.xml)
- Data directory is writable

### Data Directory Structure

The release data directory includes:

```
/opt/geoserver/data_dir/
├── global.xml          # Global GeoServer configuration
├── logging.xml         # Logging configuration
├── wcs.xml            # WCS service configuration
├── wfs.xml            # WFS service configuration
├── wms.xml            # WMS service configuration
├── coverages/         # Sample raster data
├── data/              # Sample vector data (shapefiles)
├── demo/              # Demo requests
├── layergroups/       # Layer group configurations
├── layouts/           # Print layout templates
├── palettes/          # Color palettes
├── security/          # Security configurations
├── styles/            # Style definitions (SLD files)
├── user_projections/  # Custom coordinate reference systems
├── validation/        # WFS validation rules
└── workspaces/        # Workspace configurations with sample layers
```

### Customizing the Data Directory

**Option 1: Modify in Container**

Make changes directly in the running container:

```bash
# Connect to container
docker-compose exec devdocker bash

# Edit configuration
vi /opt/geoserver/data_dir/global.xml

# Changes persist automatically
```

**Option 2: Edit on Host**

Since the data directory is bind mounted to `../geoserver-data` (one level up from devdocker directory), you can edit files directly on your host:

```bash
# From devdocker directory, navigate to parent directory
cd ..

# Edit configuration files directly
vi geoserver-data/global.xml

# Changes are immediately reflected in the container
```

**Option 3: Replace with Custom Data Directory**

You can replace the entire data directory by modifying the bind mount in `docker-compose.yml`:

```yaml
# docker-compose.yml
volumes:
  - /path/to/my-custom-data:/opt/geoserver/data_dir
```

### Resetting the Data Directory

To reset to the default configuration:

```bash
# Stop container
docker-compose down

# Remove or rename the data directory on host
cd ..
mv geoserver-data geoserver-data.backup

# Restart container (will re-initialize from source)
cd DevDocker
docker-compose up -d
```

### Backing Up the Data Directory

**Simple backup** (since it's on the host):

```bash
# From devdocker directory, navigate to parent directory
cd ..

# Create backup
tar -czf geoserver-data-backup-$(date +%Y%m%d).tar.gz geoserver-data/
```

**Restore from backup**:

```bash
# Stop container
cd DevDocker
docker-compose down

# Restore backup
cd ..
tar -xzf geoserver-data-backup-20240115.tar.gz

# Restart container
cd DevDocker
docker-compose up -d
```

### Troubleshooting Data Directory

**Problem: Data directory is empty**

Solution: Check if GeoServer source is available in the container:
```bash
docker-compose exec devdocker ls -la /workspace/geoserver/data/
```

If empty, ensure GeoServer is cloned inside the container at `/workspace/geoserver`.

**Problem: Permission denied when accessing data directory**

Solution: Check volume permissions:
```bash
docker-compose exec devdocker ls -la /opt/geoserver/
docker-compose exec devdocker chmod -R 755 /opt/geoserver/data_dir
```

**Problem: Changes not persisting**

Solution: Verify the volume is properly configured:
```bash
docker volume inspect devdocker_geoserver-data
```

If the volume doesn't exist, recreate it:
```bash
docker-compose down
docker-compose up -d
```

## Developer Extensibility

The DevDocker environment provides multiple mechanisms for customizing your development environment without rebuilding the Docker image. This allows you to install preferred tools, configure your shell, and automate setup tasks.

**Key Feature: Persistent Home Directory** - The `/root` directory is backed by a persistent Docker volume (`devdocker-home`), so all your dotfiles, configurations, and custom tools survive container restarts and rebuilds. SSH keys are copied from the host on startup, and the Maven repository is kept in a separate volume for easier management.

**For comprehensive extensibility documentation, see [Developer Extensibility Guide](docs/DEVELOPER-EXTENSIBILITY.md).**

### Extensibility Mechanisms

The DevDocker environment supports three primary extensibility mechanisms:

1. **Persistent Home Directory**: Docker volume for dotfiles, configs, and custom tools
2. **Custom Startup Script**: Automated initialization on container startup
3. **Package Manager Access**: Direct use of apt-get for system packages

### Volume Architecture

Understanding the volume architecture helps you know where to install tools and what persists:

**Named Volumes (Persistent)**:
- `devdocker-home` → `/root`: Home directory (dotfiles, configs, SSH keys, custom tools)
- `devdocker-workspace` → `/workspace`: Source code (GeoServer, GeoTools, GeoWebCache)
- `devdocker-maven-repo` → `/opt/maven-repo`: Maven cache (symlinked to `/root/.m2/repository`)

**Bind Mounts (Host Access)**:
- `./ssh-keys` → `/opt/devdocker/ssh-keys-source`: SSH keys source (copied to `/root/.ssh` on startup)
- `./scripts` → `/opt/devdocker/scripts`: DevDocker scripts (edit on host)
- `../geoserver-data` → `/opt/geoserver/data_dir`: GeoServer data directory (convenient host access)
- `./startup-custom.sh` → `/opt/devdocker/startup-custom.sh`: Custom startup script (optional)

**PATH Configuration**:
The following directories are automatically added to PATH:
- `/root/bin`: Personal scripts and binaries (persistent)
- `/root/.local/bin`: Standard Unix location for user binaries (persistent)
- `/opt/devdocker/scripts`: DevDocker project scripts (bind mount)

**What This Means for Extensibility**:
- Install custom tools in `/root/bin` or `/root/.local/bin` for persistence
- Edit dotfiles (`.bashrc`, `.vimrc`, etc.) directly - they persist automatically
- Use `startup-custom.sh` for automated package installation on container startup
- SSH keys are refreshed from host on every container restart

### Custom Tools Directory

The `/root` directory is backed by a persistent Docker volume (`devdocker-home`), allowing you to install custom tools that survive container restarts and rebuilds.

**Installing Custom Tools**:

```bash
# Connect to container
ssh -p 2222 root@localhost

# Install tools in your home directory
mkdir -p /root/bin
curl -L https://example.com/tool -o /root/bin/my-tool
chmod +x /root/bin/my-tool

# Tools in /root/bin are automatically in PATH
my-tool --version
```

**Recommended Locations**:

- **`/root/bin`**: Personal scripts and binaries (automatically in PATH, persistent)
- **`/root/.local/bin`**: Standard Unix location for user binaries (automatically in PATH, persistent)
- **`/root/my-tools/`**: Custom directory for tool installations (persistent, add to PATH if needed)

**Why These Locations?**

- **Persistent**: Backed by Docker named volume `devdocker-home`
- **Automatic PATH**: `/root/bin` and `/root/.local/bin` are added to PATH by entrypoint.sh
- **Survives Rebuilds**: Tools persist even when container is recreated
- **Standard Location**: Follows Unix convention (`~/bin`)

**Common Use Cases**:

```bash
# Install jq for JSON processing
curl -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -o /root/bin/jq
chmod +x /root/bin/jq

# Install httpie for API testing
apt-get update && apt-get install -y python3-pip
pip3 install httpie
# httpie installs to /usr/local/bin, which is already in PATH

# Install custom build scripts
cat > /root/bin/quick-build <<'EOF'
#!/bin/bash
cd /workspace/geoserver/src
mvn install -DskipTests -pl web/app -am
EOF
chmod +x /root/bin/quick-build
```

### Custom Startup Script

For automated initialization, create a `startup-custom.sh` script that runs on every container start. This is ideal for installing packages, configuring Git, setting up aliases, and other one-time setup tasks.

**Creating a Custom Startup Script**:

1. **Copy the example template**:
   ```bash
   cp startup-custom.sh.example startup-custom.sh
   ```

2. **Edit the script** with your customizations:
   ```bash
   #!/bin/bash
   set -e
   
   echo "=== Running custom startup script ==="
   
   # Install additional packages
   apt-get update
   apt-get install -y vim tmux htop
   
   # Configure Git
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   git config --global core.editor "vim"
   
   # Set up shell aliases
   cat >> /root/.bashrc <<'EOF'
   alias gs='cd /workspace/geoserver'
   alias build='build-geoserver.sh'
   alias start='start-geoserver.sh'
   EOF
   
   echo "=== Custom startup script completed ==="
   ```

3. **Mount it in docker-compose.yml**:
   ```yaml
   volumes:
     - ./startup-custom.sh:/opt/devdocker/startup-custom.sh:ro
   ```

4. **Restart the container**:
   ```bash
   docker-compose restart
   ```

**Startup Script Best Practices**:

- **Use `set -e`**: Exit on errors to catch issues early
- **Add echo statements**: Provide feedback about what's being configured
- **Check for existing config**: Use conditional logic to avoid duplicate configuration
- **Keep it fast**: Minimize startup time by only installing essential tools
- **Document dependencies**: Comment why each tool is needed

**Example: Complete Startup Script**:

```bash
#!/bin/bash
set -e

echo "=== Running custom startup script ==="

# Install development tools
apt-get update
apt-get install -y vim tmux htop jq curl postgresql-client

# Configure Git
git config --global user.name "Developer Name"
git config --global user.email "dev@example.com"
git config --global core.editor "vim"
git config --global pull.rebase false

# Install custom CLI tools
mkdir -p /root/bin
curl -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -o /root/bin/jq
chmod +x /root/bin/jq

# Set up shell aliases
cat >> /root/.bashrc <<'EOF'
# GeoServer development aliases
alias gs='cd /workspace/geoserver'
alias gt='cd /workspace/geotools'
alias gwc='cd /workspace/geowebcache'
alias build='build-geoserver.sh'
alias start='start-geoserver.sh'
alias logs='tail -f /var/log/geoserver.log'
alias rebuild='build-geoserver.sh && restart-geoserver.sh'
EOF

# Set up custom environment variables
echo 'export MAVEN_OPTS="-Xmx2g"' >> /etc/profile.d/custom-env.sh

echo "=== Custom startup script completed ==="
```

### Package Manager Access

You can install system packages directly using apt-get. However, these installations are **only persistent across container restarts**, not rebuilds.

**Important**: When you rebuild the container (`docker-compose build` or `docker-compose up --build`), all apt-get installed packages are lost because they're part of the container filesystem, not a volume.

**For Persistent Packages**: Add installation commands to your `startup-custom.sh` script to automatically reinstall them on every container start (including after rebuilds).

**For Temporary Packages**: Install directly via SSH for one-time use:

```bash
# Connect to container
ssh -p 2222 root@localhost

# Install packages
apt-get update
apt-get install -y vim tmux htop

# Use immediately
htop
```

**Note**: Packages installed via apt-get are lost when the container is rebuilt (e.g., `docker-compose build` or `docker-compose up --build`). They persist across container restarts (`docker-compose restart` or `docker-compose stop/start`), but not rebuilds. To make them persistent across rebuilds, add the installation commands to your `startup-custom.sh` script, which runs automatically on every container start.

### Shell Configuration

You can customize your shell environment by editing `.bashrc` or creating custom profile scripts.

**Option 1: Edit .bashrc directly** (not persistent across rebuilds):

```bash
# Connect to container
ssh -p 2222 root@localhost

# Add aliases
cat >> /root/.bashrc <<'EOF'
alias gs='cd /workspace/geoserver'
alias build='build-geoserver.sh'
EOF

# Reload
source /root/.bashrc
```

**Option 2: Use startup script** (persistent):

Add to your `startup-custom.sh`:

```bash
cat >> /root/.bashrc <<'EOF'
# Custom aliases
alias gs='cd /workspace/geoserver'
alias build='build-geoserver.sh'
EOF
```

### Persistent Home Directory

**Implementation Status**: ✓ **Implemented** - The `/root` directory is backed by a persistent Docker volume (`devdocker-home`).

**How It Works**:

The DevDocker environment uses a persistent home directory volume that preserves your development environment across container restarts and rebuilds:

1. **SSH Keys**: Copied from `./ssh-keys/` (host bind mount) to `/root/.ssh` (persistent volume) on container startup
2. **Maven Repository**: Symlinked from `/root/.m2/repository` to `/opt/maven-repo` (separate persistent volume `devdocker-maven-repo`)
3. **Dotfiles & Configs**: All files in `/root` persist automatically (`.bashrc`, `.vimrc`, `.gitconfig`, etc.)
4. **Custom Tools**: Binaries in `/root/bin` and `/root/.local/bin` persist and are automatically in PATH

**What Persists**:

```bash
# These persist across container restarts and rebuilds:
/root/.bashrc          # Shell configuration
/root/.bash_history    # Command history
/root/.vimrc           # Vim configuration
/root/.gitconfig       # Git configuration
/root/.tmux.conf       # Tmux configuration
/root/.ssh/            # SSH keys (copied from host on startup, then persist)
/root/bin/             # Custom scripts and tools
/root/.local/bin/      # User-installed binaries
```

**Benefits**:

- ✓ No need to recreate shell configuration on every startup
- ✓ Git configuration persists automatically
- ✓ SSH keys work at standard location and persist after initial copy
- ✓ Natural developer experience (everything in `/root` just works)
- ✓ Maven repository isolated in separate volume for easier management

**If You Need Persistent Shell Config**:

Since the home directory is persistent, your shell configuration automatically persists. However, if you want to automate configuration on fresh setups, add to your `startup-custom.sh`:

```bash
# Configure shell only if not already done
if ! grep -q "alias gs=" /root/.bashrc; then
    cat >> /root/.bashrc <<'EOF'
# Custom aliases
alias gs='cd /workspace/geoserver'
alias build='build-geoserver.sh'
EOF
fi

# Configure vim only if not already done
if [ ! -f /root/.vimrc ]; then
    cat > /root/.vimrc <<'EOF'
set number
set tabstop=4
# ... more configuration
EOF
fi
```

### Extensibility Examples

**Example 1: Python Development Tools**

```bash
#!/bin/bash
# startup-custom.sh
apt-get update
apt-get install -y python3-pip
pip3 install requests beautifulsoup4 pytest
```

**Example 2: Database Clients**

```bash
#!/bin/bash
# startup-custom.sh
apt-get update
apt-get install -y postgresql-client mysql-client
```

**Example 3: Custom Build Scripts**

```bash
# Create a quick rebuild script
mkdir -p /root/bin
cat > /root/bin/quick-rebuild <<'EOF'
#!/bin/bash
cd /workspace/geoserver/src
mvn install -DskipTests -pl web/app -am
restart-geoserver.sh
EOF
chmod +x /root/bin/quick-rebuild
```

**Example 4: Git Configuration**

```bash
#!/bin/bash
# startup-custom.sh
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config --global core.editor "vim"
git config --global pull.rebase false
git config --global alias.st "status"
git config --global alias.co "checkout"
git config --global alias.br "branch"
```

### Troubleshooting Extensibility

**Problem: Custom tools not in PATH**

Solution: Ensure tools are in `/root/bin` or `/root/.local/bin`:
```bash
ls -la /root/bin/
echo $PATH | grep "/root/bin"
```

**Problem: Startup script not executing**

Solution: Verify the script is mounted and executable:
```bash
docker-compose exec devdocker ls -la /opt/devdocker/startup-custom.sh
docker-compose logs devdocker | grep "custom startup"
```

**Problem: Packages installed but lost after restart**

Solution: This is expected for `docker-compose build`. Add installations to `startup-custom.sh` for persistence across rebuilds.

**Problem: Permission denied when installing tools**

Solution: Ensure you're running as root:
```bash
whoami  # Should show: root
```

## Troubleshooting

### Error Handling and Logging

The DevDocker environment includes comprehensive error detection and logging. For detailed troubleshooting:

- **Error Handling Guide**: See [docs/ERROR-HANDLING.md](docs/ERROR-HANDLING.md) for:
  - Log levels and locations
  - Common errors and solutions
  - Debugging tips
  - Error recovery procedures

**Quick Log Access:**
```bash
# View container logs
docker logs devdocker

# View main log file
docker exec devdocker tail -f /var/log/devdocker/devdocker.log

# View latest build log
docker exec devdocker tail -f /tmp/devdocker-logs/build-geoserver-latest.log

# Enable debug logging
# In .env or docker-compose.yml:
LOG_LEVEL=DEBUG
```

### Port Conflicts

If ports are already in use, change them in `.env`:

```bash
SSH_PORT=2223
GEOSERVER_PORT=8081
```

### Build Tool Verification Fails

Rebuild the Docker image:

```bash
docker-compose build --no-cache
```

### Maven Repository Corruption

Clean the Maven repository in the container:

```bash
# Option 1: Remove entire Maven repository volume (will re-download everything)
docker-compose down
docker volume rm devdocker-maven-repo
docker-compose up -d

# Option 2: Remove only GeoServer-related artifacts
docker-compose exec devdocker rm -rf /root/.m2/repository/org/geoserver
docker-compose exec devdocker rm -rf /root/.m2/repository/org/geotools
docker-compose exec devdocker rm -rf /root/.m2/repository/org/geowebcache

# Option 3: Use Maven's built-in purge (from container)
docker-compose exec devdocker bash -c "cd /workspace/geoserver/src && mvn dependency:purge-local-repository"
```

## FAQ

### Why does my container have the wrong Java/Tomcat version?

**The Challenge**: Starting in 2026, GeoServer 3.0 introduced breaking changes that require different base images than GeoServer 2.x:

- **GeoServer 3.0 (main branch)**: Requires Java 21, Tomcat 11, and Jakarta EE (jakarta.servlet.*)
- **GeoServer 2.28.x**: Requires Java 17, Tomcat 9, and Java EE (javax.servlet.*)
- **GeoServer 2.27.x**: Requires Java 17, Tomcat 9, and Java EE (javax.servlet.*)
- **GeoServer 2.26.x and older**: Requires Java 11, Tomcat 9, and Java EE (javax.servlet.*)

Manually tracking these requirements is error-prone and frustrating.

**The Solution**: DevDocker includes automatic version detection and container rebuilding:

```bash
# Automatically detects GeoServer version and rebuilds with correct base image
bash scripts/rebuild-container.sh
```

The `rebuild-container.sh` script:
1. Uses `detect-geoserver-version.sh` to identify your GeoServer version from the workspace
2. Uses `get-tomcat-image.sh` to determine the correct Tomcat/Java base image
3. Rebuilds the container only if the Java version doesn't match
4. Preserves all your data in named volumes (source code, Maven cache, configurations)

**When to use it**:
- After switching GeoServer branches (e.g., from 2.28.x to main)
- After checking out a different GeoServer version tag
- When you see Java/Tomcat version errors in logs
- When GeoServer fails to deploy with servlet API errors

**Example workflow**:
```bash
# Inside container: switch to GeoServer 3.0
cd /workspace/geoserver
git checkout main

# On host: rebuild container with correct versions
bash scripts/rebuild-container.sh

# Container automatically rebuilds with Tomcat 11 + Java 21
```

The utility scripts handle all the complexity, so you can focus on development instead of infrastructure.

## Architecture

- **Base Image**: `tomcat:9.0-jdk21-temurin-noble` (for GeoServer 2.28.x) - automatically selected based on detected version
- **Build Tools**: JDK 21, Maven 3.8+, Git 2.x
- **Ports**: SSH (22→2222), JDWP (5005), GeoServer (8080)
- **Volumes**: 
  - Home directory: devdocker-home (named volume, persists dotfiles, configs, SSH keys, custom tools)
  - Source code: devdocker-workspace (named volume, cloned inside container)
  - Maven repository: devdocker-maven-repo (named volume, symlinked to /root/.m2/repository)
  - Data directory: bind mount to `../geoserver-data` (convenient host access)
  - Scripts: bind mount to `./scripts` (edit on host)
  - SSH keys source: bind mount to `./ssh-keys` (copied to /root/.ssh on startup)

## License

This project follows the same license as GeoServer.

## Contributing

Contributions are welcome! Please submit issues and pull requests.
