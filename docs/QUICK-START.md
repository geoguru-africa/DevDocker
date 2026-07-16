# Quick Start

## Features

- **Pre-configured Build Tools**: JDK 21, Maven 3.8+, Git (auto-selects correct Java/Tomcat version)
- **IDE Connectivity**: SSH access for VSCode, IntelliJ IDEA, and Kiro
- **Remote Debugging**: JDWP support for live debugging
- **Fast Builds**: Named volumes provide 16-17x faster builds on Windows vs bind mounts
- **Smart Maven Fallback**: Local cache → Host repo → Classroom mirror → Maven Central
- **Configurable Multi-Project Builds**: Optional GeoTools/GeoWebCache integration
- **Developer Extensibility**: Install custom tools and persist configurations

## Prerequisites

- Docker Engine 20.10+ or Docker Desktop
- Docker Compose 2.0+
- SSH client (for connecting to the container)

## Setup

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

   This will automatically pull the pre-built image from [Docker Hub](https://hub.docker.com/r/geoguruafrica/devdocker) (`geoguruafrica/devdocker`) if it's not already available locally. See [Image Usage](IMAGE-USAGE.md) for versioning and local-build details.

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

   See [Source Code Workflow](SOURCE-CODE-WORKFLOW.md) for forking, versioning, and multi-project (GeoTools/GeoWebCache) setup.

6. **Build GeoServer**:
   ```bash
   build-geoserver.sh
   # First build: ~10-15 minutes (downloads dependencies)
   # Subsequent builds: ~2-3 minutes
   ```

That's it! You're ready to develop.

## Where to Next

- [Configuration Reference](CONFIGURATION-REFERENCE.md) — environment variables, multi-project flags, architecture
- [IDE Connectivity](IDE-CONNECTIVITY.md) — connecting Kiro, VSCode, IntelliJ
- [Remote Debugging](VSCODE-REMOTE-DEBUGGING.md) — JDWP debugging setup
- [Data Directory](DATA-DIRECTORY.md) — how the GeoServer data directory is initialized and managed
- [Troubleshooting](TROUBLESHOOTING.md) — common problems and fixes
