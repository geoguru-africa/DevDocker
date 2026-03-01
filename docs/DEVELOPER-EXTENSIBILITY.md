# Developer Extensibility Guide

This guide explains how to customize the DevDocker environment to match your development preferences and workflow.

## Overview

The DevDocker environment provides three primary extensibility mechanisms:

1. **Persistent Home Directory** (`/root`) - All files persist across restarts and rebuilds
2. **Custom Startup Script** (`startup-custom.sh`) - Automated initialization on container startup
3. **Package Manager Access** (`apt-get`) - Direct installation of system packages (persists across restarts only, not rebuilds)

## Custom Tools Installation

### Where to Install Tools

With the persistent home directory, you can install tools in standard Unix locations:

- **`/root/bin`**: Personal scripts and binaries (automatically in PATH)
- **`/root/.local/bin`**: Standard Unix location for user binaries (automatically in PATH)
- **`/root/my-tools/`**: Custom directory for tool installations

All of these locations persist across container restarts and rebuilds.

### Installing Custom Tools

**Basic Installation**:

```bash
# Connect to container
ssh -p 2222 root@localhost

# Create bin directory if it doesn't exist
mkdir -p /root/bin

# Download and install a tool
curl -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -o /root/bin/jq
chmod +x /root/bin/jq

# Verify it's in PATH
which jq
jq --version
```

**Installing from Archives**:

```bash
# Download and extract
curl -L https://example.com/tool.tar.gz -o /tmp/tool.tar.gz
tar -xzf /tmp/tool.tar.gz -C /root/.local/
ln -s /root/.local/tool/bin/tool /root/bin/tool
rm /tmp/tool.tar.gz
```

**Installing Python Tools**:

```bash
# Install pip if not present
apt-get update && apt-get install -y python3-pip

# Install Python package
pip3 install httpie

# httpie installs to /usr/local/bin, which is already in PATH
```

### Common Tools to Install

**Development Tools**:
```bash
# jq - JSON processor
mkdir -p /root/bin
curl -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -o /root/bin/jq
chmod +x /root/bin/jq

# httpie - HTTP client
apt-get update && apt-get install -y python3-pip
pip3 install httpie
ln -s /usr/local/bin/http /root/bin/http

# yq - YAML processor
curl -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /root/bin/yq
chmod +x /root/bin/yq
```

**Database Clients**:
```bash
# PostgreSQL client
apt-get update && apt-get install -y postgresql-client
ln -s /usr/bin/psql /root/bin/psql

# MySQL client
apt-get update && apt-get install -y mysql-client
ln -s /usr/bin/mysql /root/bin/mysql
```

**Custom Build Scripts**:
```bash
# Quick rebuild script
mkdir -p /root/bin
cat > /root/bin/quick-rebuild <<'EOF'
#!/bin/bash
set -e
cd /workspace/geoserver/src
echo "Building GeoServer web app..."
mvn install -DskipTests -pl web/app -am
echo "Restarting GeoServer..."
restart-geoserver.sh
echo "Done!"
EOF
chmod +x /root/bin/quick-rebuild

# Clean build script
cat > /root/bin/clean-build <<'EOF'
#!/bin/bash
set -e
cd /workspace/geoserver/src
echo "Cleaning and building GeoServer..."
mvn clean install -DskipTests
echo "Done!"
EOF
chmod +x /root/bin/clean-build
```

### Verifying Custom Tools

```bash
# List installed tools
ls -la /root/bin/

# Check PATH
echo $PATH | grep "/root/bin"

# Test a tool
jq --version
```

## Custom Startup Script

### What is startup-custom.sh?

The `startup-custom.sh` script runs automatically every time the container starts. This is ideal for:

- Installing system packages
- Configuring Git
- Setting up shell aliases
- Installing tools that don't need persistence
- Configuring environment variables

### Creating a Custom Startup Script

**Step 1: Copy the Example**

```bash
cp startup-custom.sh.example startup-custom.sh
```

**Step 2: Edit the Script**

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

**Step 3: Mount in docker-compose.yml**

Uncomment the line in `docker-compose.yml`:

```yaml
volumes:
  - ./startup-custom.sh:/opt/devdocker/startup-custom.sh:ro
```

**Step 4: Restart Container**

```bash
docker-compose restart
```

### Startup Script Best Practices

**Use Error Handling**:
```bash
#!/bin/bash
set -e  # Exit on error

# Your commands here
```

**Provide Feedback**:
```bash
echo "Installing development tools..."
apt-get update && apt-get install -y vim tmux
echo "Development tools installed"
```

**Check for Existing Configuration**:
```bash
# Only configure if not already done
if ! grep -q "alias gs=" /root/.bashrc; then
    echo "alias gs='cd /workspace/geoserver'" >> /root/.bashrc
fi
```

**Keep It Fast**:
```bash
# Minimize startup time
apt-get update -qq
apt-get install -y -qq vim tmux  # Quiet mode
```

### Complete Startup Script Example

```bash
#!/bin/bash
set -e

echo "=== Running custom startup script ==="

# Install development tools
echo "Installing development tools..."
apt-get update -qq
apt-get install -y -qq vim tmux htop jq curl postgresql-client
echo "✓ Development tools installed"

# Configure Git
echo "Configuring Git..."
git config --global user.name "Developer Name"
git config --global user.email "dev@example.com"
git config --global core.editor "vim"
git config --global pull.rebase false
git config --global alias.st "status"
git config --global alias.co "checkout"
git config --global alias.br "branch"
echo "✓ Git configured"

# Install custom CLI tools
echo "Installing custom tools..."
mkdir -p /root/bin
if [ ! -f /root/bin/jq ]; then
    curl -sL https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -o /root/bin/jq
    chmod +x /root/bin/jq
    echo "✓ jq installed"
fi

# Set up shell aliases
echo "Setting up shell aliases..."
cat >> /root/.bashrc <<'EOF'

# GeoServer development aliases
alias gs='cd /workspace/geoserver'
alias gt='cd /workspace/geotools'
alias gwc='cd /workspace/geowebcache'
alias build='build-geoserver.sh'
alias start='start-geoserver.sh'
alias stop='stop-geoserver.sh'
alias restart='restart-geoserver.sh'
alias logs='tail -f /var/log/geoserver.log'
alias rebuild='build-geoserver.sh && restart-geoserver.sh'

# Maven aliases
alias mci='mvn clean install -DskipTests'
alias mcp='mvn clean package -DskipTests'
alias mt='mvn test'

# Git aliases
alias gst='git status'
alias gco='git checkout'
alias gbr='git branch'
alias glog='git log --oneline --graph --decorate'
EOF
echo "✓ Shell aliases configured"

# Set up custom environment variables
echo "Setting up environment variables..."
cat > /etc/profile.d/custom-env.sh <<'EOF'
export MAVEN_OPTS="-Xmx2g"
export EDITOR="vim"
EOF
echo "✓ Environment variables configured"

# Create custom prompt
echo "Configuring shell prompt..."
cat >> /root/.bashrc <<'EOF'

# Custom prompt with Git branch
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
export PS1='\[\033[01;32m\]\u@devdocker\[\033[00m\]:\[\033[01;34m\]\w\[\033[33m\]$(parse_git_branch)\[\033[00m\]\$ '
EOF
echo "✓ Shell prompt configured"

echo "=== Custom startup script completed ==="
```

## Package Manager Access

### Installing Packages Directly

You can install system packages using apt-get:

```bash
# Connect to container
ssh -p 2222 root@localhost

# Install packages
apt-get update
apt-get install -y vim tmux htop
```

**Important**: Packages installed this way are **only persistent across container restarts**, not rebuilds. When you rebuild the container (`docker-compose build` or `docker-compose up --build`), all apt-get installed packages are lost because they're part of the container filesystem, not a volume.

### Making Package Installation Persistent

To make package installations persistent across rebuilds, add them to your `startup-custom.sh`:

```bash
#!/bin/bash
apt-get update
apt-get install -y vim tmux htop
```

This ensures packages are automatically reinstalled every time the container starts (including after rebuilds).

### Common Packages

**Text Editors**:
```bash
apt-get install -y vim emacs nano
```

**Shell Tools**:
```bash
apt-get install -y tmux screen zsh
```

**Monitoring Tools**:
```bash
apt-get install -y htop iotop nethogs
```

**Network Tools**:
```bash
apt-get install -y curl wget netcat-openbsd dnsutils
```

**Development Tools**:
```bash
apt-get install -y build-essential gdb valgrind
```

**Database Clients**:
```bash
apt-get install -y postgresql-client mysql-client
```

## Shell Configuration

### Customizing .bashrc

**Option 1: Via Startup Script (Recommended)**

Add to `startup-custom.sh`:

```bash
cat >> /root/.bashrc <<'EOF'
# Custom aliases
alias ll='ls -la'
alias gs='cd /workspace/geoserver'

# Custom functions
function build-and-restart() {
    build-geoserver.sh && restart-geoserver.sh
}

# Custom prompt
export PS1='\u@devdocker:\w\$ '
EOF
```

**Option 2: Direct Edit (Not Persistent)**

```bash
# Connect to container
ssh -p 2222 root@localhost

# Edit .bashrc
vim /root/.bashrc

# Reload
source /root/.bashrc
```

### Customizing Vim

Add to `startup-custom.sh`:

```bash
cat > /root/.vimrc <<'EOF'
set number
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
syntax on
EOF
```

### Customizing Tmux

Add to `startup-custom.sh`:

```bash
cat > /root/.tmux.conf <<'EOF'
# Set prefix to Ctrl-a
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Enable mouse
set -g mouse on

# Split panes using | and -
bind | split-window -h
bind - split-window -v
EOF
```

## Environment Variables

### Setting Custom Environment Variables

**Option 1: Via Startup Script**

Add to `startup-custom.sh`:

```bash
cat > /etc/profile.d/custom-env.sh <<'EOF'
export MY_CUSTOM_VAR="value"
export MAVEN_OPTS="-Xmx2g"
export EDITOR="vim"
EOF
```

**Option 2: Via docker-compose.yml**

Add to `docker-compose.yml`:

```yaml
environment:
  - MY_CUSTOM_VAR=value
```

### Persistent Home Directory (Implemented)

**Implementation**: The `/root` directory is backed by a persistent Docker volume (`devdocker-home`), which means:

- ✓ All dotfiles persist (`.bashrc`, `.vimrc`, `.gitconfig`, `.tmux.conf`, etc.)
- ✓ Shell history persists across container restarts and rebuilds
- ✓ SSH keys are copied from host source on startup and persist in the volume
- ✓ Custom configurations survive container recreation
- ✓ Tool installations in `/root` persist

**How It Works**:

1. **SSH Keys**: Copied from `./ssh-keys/` (host bind mount at `/opt/devdocker/ssh-keys-source`) to `/root/.ssh` (persistent volume) on container startup
2. **Maven Repository**: Symlinked from `/root/.m2/repository` to `/opt/maven-repo` (separate persistent volume `devdocker-maven-repo`)
3. **Everything Else**: Stored directly in the persistent home volume (`devdocker-home`)

**Benefits**:

- No need to recreate shell configuration on every startup
- Git configuration persists automatically
- SSH keys work at standard location and persist after initial copy
- Natural developer experience (everything in `/root` just works)
- Maven repository is isolated in its own volume for better management

**Example: What Persists**:

```bash
# These files persist across container restarts and rebuilds:
/root/.bashrc          # Shell configuration
/root/.bash_history    # Command history
/root/.vimrc           # Vim configuration
/root/.gitconfig       # Git configuration
/root/.tmux.conf       # Tmux configuration
/root/.ssh/            # SSH keys (copied from host on startup, then persist)
/root/bin/             # Custom scripts and tools
/root/.local/bin/      # User-installed binaries
/root/my-tools/        # Custom tool installations

# Maven repository is in a separate volume:
/root/.m2/repository   # Symlink to /opt/maven-repo (devdocker-maven-repo volume)
```

**Important Notes**:

- **SSH Keys**: The keys are copied from the host bind mount (`./ssh-keys/`) on every container startup. This means if you update keys on the host, they will be refreshed in the container on next restart.
- **Maven Repository**: Kept in a separate volume (`devdocker-maven-repo`) for easier management and cleanup without affecting other home directory contents.
- **Workspace**: Source code is in a separate volume (`devdocker-workspace`) at `/workspace` for optimal build performance.

## Troubleshooting

### Custom Tools Not in PATH

**Problem**: Installed tool not found

**Solution**: Verify tool is in `/root/bin`:
```bash
ls -la /root/bin/
echo $PATH | grep "/root/bin"
```

### Startup Script Not Executing

**Problem**: Custom startup script doesn't run

**Solution**: Verify mount and check logs:
```bash
# Check if mounted
docker-compose exec devdocker ls -la /opt/devdocker/startup-custom.sh

# Check logs
docker-compose logs devdocker | grep "custom startup"

# Verify it's executable
docker-compose exec devdocker test -x /opt/devdocker/startup-custom.sh && echo "Executable" || echo "Not executable"
```

### Packages Lost After Rebuild

**Problem**: Installed packages disappear after `docker-compose build`

**Solution**: This is expected. Add installations to `startup-custom.sh`:
```bash
#!/bin/bash
apt-get update
apt-get install -y vim tmux htop
```

### Permission Denied

**Problem**: Cannot install tools or packages

**Solution**: Verify you're running as root:
```bash
whoami  # Should show: root
```

### Startup Script Fails

**Problem**: Container starts but startup script has errors

**Solution**: Check logs for error details:
```bash
docker-compose logs devdocker | grep -A 10 "custom startup"
```

Add error handling to your script:
```bash
#!/bin/bash
set -e  # Exit on error

# Your commands here
```

## Examples

### Example 1: Python Development Environment

```bash
#!/bin/bash
# startup-custom.sh
set -e

echo "Setting up Python development environment..."

# Install Python tools
apt-get update -qq
apt-get install -y -qq python3-pip python3-venv

# Install Python packages
pip3 install requests beautifulsoup4 pytest black flake8

# Create aliases
cat >> /root/.bashrc <<'EOF'
alias pytest='python3 -m pytest'
alias black='python3 -m black'
EOF

echo "Python development environment ready"
```

### Example 2: Database Development

```bash
#!/bin/bash
# startup-custom.sh
set -e

echo "Setting up database development environment..."

# Install database clients
apt-get update -qq
apt-get install -y -qq postgresql-client mysql-client

# Configure PostgreSQL connection
cat >> /root/.bashrc <<'EOF'
export PGHOST=localhost
export PGUSER=geoserver
export PGDATABASE=geoserver
alias psql-gs='psql -h $PGHOST -U $PGUSER -d $PGDATABASE'
EOF

echo "Database development environment ready"
```

### Example 3: Advanced Git Configuration

```bash
#!/bin/bash
# startup-custom.sh
set -e

echo "Configuring Git..."

# Basic Git config
git config --global user.name "Developer Name"
git config --global user.email "dev@example.com"
git config --global core.editor "vim"

# Advanced Git config
git config --global pull.rebase false
git config --global push.default current
git config --global core.autocrlf input
git config --global init.defaultBranch main

# Git aliases
git config --global alias.st "status"
git config --global alias.co "checkout"
git config --global alias.br "branch"
git config --global alias.ci "commit"
git config --global alias.unstage "reset HEAD --"
git config --global alias.last "log -1 HEAD"
git config --global alias.visual "log --oneline --graph --decorate --all"

echo "Git configured"
```

### Example 4: Custom Build Workflow

```bash
#!/bin/bash
# startup-custom.sh
set -e

echo "Setting up custom build workflow..."

# Create custom build scripts
mkdir -p /root/bin
cat > /root/bin/quick-build <<'EOF'
#!/bin/bash
set -e
cd /workspace/geoserver/src
echo "Quick building GeoServer web app..."
mvn install -DskipTests -pl web/app -am -T 1C
echo "Build complete!"
EOF
chmod +x /root/bin/quick-build

cat > /root/bin/full-build <<'EOF'
#!/bin/bash
set -e
cd /workspace/geoserver/src
echo "Full clean build of GeoServer..."
mvn clean install -DskipTests -T 1C
echo "Build complete!"
EOF
chmod +x /root/bin/full-build

cat > /root/bin/rebuild-and-restart <<'EOF'
#!/bin/bash
set -e
echo "Rebuilding and restarting GeoServer..."
quick-build
restart-geoserver.sh
echo "GeoServer restarted with new build!"
EOF
chmod +x /root/bin/rebuild-and-restart

# Create aliases
cat >> /root/.bashrc <<'EOF'
alias qb='quick-build'
alias fb='full-build'
alias rr='rebuild-and-restart'
EOF

echo "Custom build workflow ready"
```

## Best Practices

1. **Use startup-custom.sh for automation**: Automate repetitive setup tasks
2. **Keep tools in /root/bin**: Use the standard location for persistence
3. **Document your customizations**: Add comments explaining why tools are needed
4. **Test startup script**: Verify it works by restarting the container
5. **Keep it fast**: Minimize startup time by only installing essential tools
6. **Use error handling**: Add `set -e` to catch errors early
7. **Provide feedback**: Use echo statements to show progress
8. **Version control your scripts**: Commit `startup-custom.sh` to your repository
9. **Share with team**: Document common tools and configurations
10. **Keep it simple**: Don't over-engineer the startup script
