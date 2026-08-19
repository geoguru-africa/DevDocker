# Source Code Workflow

The DevDocker environment uses Docker named volumes for optimal build performance. Source code is cloned inside the container, not on your host machine.

## Why Named Volumes?

Named volumes provide 16-17x faster build performance on Windows compared to bind mounts:
- **Windows bind mount**: 37-40 minutes per build
- **Named volume**: 2-3 minutes per build

## Creating Your Fork

Before cloning, create a personal fork on GitHub:

1. Navigate to https://github.com/geoserver/geoserver
2. Click the "Fork" button in the top-right corner
3. Select your GitHub account as the destination
4. Wait for GitHub to create your fork

## Initial Setup

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

## Working with Specific Versions

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

## Keeping Your Fork Updated

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

## Contributing Changes

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

## Optional: GeoTools and GeoWebCache

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

Restart the container: `docker compose restart`

See [Configuration Reference](CONFIGURATION-REFERENCE.md#multi-project-development) for the full explanation of these flags.

## Accessing Files from Host

Since source code is in a named volume, you can't directly access it from your host. Use these methods:

**Copy files out of container**:
```bash
docker cp devdocker:/workspace/geoserver/file.txt .
```

**Copy files into container**:
```bash
docker cp file.txt devdocker:/workspace/geoserver/
```

**Edit via SSH**: Connect with VSCode Remote-SSH or your preferred IDE for seamless editing. See [IDE Connectivity](IDE-CONNECTIVITY.md).

## Backing Up Your Work

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

## Troubleshooting

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

If truly empty, the volume may have been deleted. Re-clone your repositories. See also [Troubleshooting: Volume Mount Problems](troubleshooting/volume-mount-problems.md).
