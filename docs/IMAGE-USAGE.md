# Image Usage

The DevDocker image is available on Docker Hub, allowing you to skip the build process and start developing immediately. See [Quick Start](QUICK-START.md) for the basic setup.

## Pulling from Docker Hub

Instead of building the image locally, you can pull the pre-built image:

```bash
# Pull the latest version (recommended)
docker pull geoguruafrica/devdocker:latest

# Or pull a specific version tag (see Tags link below for what's available)
docker pull geoguruafrica/devdocker:<version>
```

The `docker-compose.yml` file is already configured to use the Docker Hub image. When you run `docker compose up -d`, it will automatically pull the image if it's not available locally.

## Image Versioning Strategy

The DevDocker project follows semantic versioning for Docker images:

- **`latest` tag**: Always points to the most recent stable release. Recommended for most users who want automatic updates.
- **Version-specific tags** (e.g., `1.0.0`, `1.1.0`): Pinned to specific releases. Recommended for production-like environments or when you need reproducible builds.

**When to use `latest`**:
- You want the newest features and bug fixes automatically
- You're doing active development and don't mind occasional breaking changes
- You're following the project closely and can adapt to updates

**When to use version-specific tags**:
- You need a stable, reproducible environment (e.g., for classroom settings)
- You want to control when to upgrade
- You're documenting a specific workflow that depends on particular tool versions
- You're troubleshooting and want to eliminate version differences as a variable

## Specifying Image Version

To use a specific version, modify your `docker-compose.yml`:

```yaml
services:
  devdocker:
    image: geoguruafrica/devdocker:latest  # Or pin to a specific version tag
    # ... rest of configuration
```

Or keep the default to use `latest`:

```yaml
services:
  devdocker:
    image: geoguruafrica/devdocker:latest  # Always use latest
    # ... rest of configuration
```

## Checking Your Current Version

To see which version you're currently running:

```bash
# View image details
docker images geoguruafrica/devdocker

# Check image labels (if version info is embedded)
docker inspect geoguruafrica/devdocker:latest | grep -i version
```

## Updating to Latest Version

To update to the latest version:

```bash
# Pull the latest image
docker pull geoguruafrica/devdocker:latest

# Restart your container
docker compose down
docker compose up -d
```

**Note**: Your data (source code, Maven cache, configurations) is stored in Docker volumes and will persist across image updates.

## Available Versions

Visit the Docker Hub repository to see all available versions:
- **Repository**: https://hub.docker.com/r/geoguruafrica/devdocker
- **Tags**: https://hub.docker.com/r/geoguruafrica/devdocker/tags

## Building Locally (For Developers)

If you're contributing to the DevDocker project itself or need to customize the Docker image, you can build it locally instead of using the pre-built image from Docker Hub.

### Using docker-compose.dev.yml

The easiest way to build locally is using the development override file:

```bash
# Build and start with local image
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build

# This will:
# 1. Build the image from the local Dockerfile
# 2. Tag it as devdocker:latest
# 3. Start the container with your local build
```

### Manual Build

Alternatively, you can build manually:

```bash
# Build the image
docker build -t devdocker:latest .

# Then modify docker-compose.yml to use your local image:
# Change: image: geoguruafrica/devdocker:latest
# To:     image: devdocker:latest

# Start the container
docker compose up -d
```

### When to Build Locally

Build locally when you:
- Are developing or testing changes to the DevDocker image itself
- Need to customize the base image or installed tools
- Want to test changes before contributing to the project
- Are working offline without access to Docker Hub

For normal GeoServer development, use the pre-built image from Docker Hub for faster setup.
