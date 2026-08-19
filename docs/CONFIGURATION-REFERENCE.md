# Configuration Reference

## Environment Variables

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
docker compose down
docker compose up -d
```

## Multi-Project Development

By default, DevDocker builds GeoServer only, using GeoTools and GeoWebCache from Maven Central. This is the recommended approach for most GeoServer development work.

### Understanding CUSTOM_GEOTOOLS and CUSTOM_GEOWEBCACHE Flags

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

### Enabling Custom Builds

To use local GeoTools/GeoWebCache builds:

1. **Clone the repositories inside the container** (see [Source Code Workflow](SOURCE-CODE-WORKFLOW.md#optional-geotools-and-geowebcache)):
   ```bash
   ssh -p 2222 root@localhost

   cd /workspace
   git clone https://github.com/YOUR_USERNAME/geotools.git
   cd geotools
   git remote add upstream https://github.com/geotools/geotools.git
   git fetch upstream --tags

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
   docker compose restart
   ```

4. **Build using the orchestration script**:
   ```bash
   ssh -p 2222 root@localhost
   build-geotrio.sh
   ```

The `build-geotrio.sh` script automatically detects which flags are enabled and builds projects in the correct order: GeoTools → GeoWebCache → GeoServer.

## Build Tools

The environment includes:

- **Java**: OpenJDK 21 (Temurin distribution) for GeoServer 2.28.x
- **Maven**: 3.8+ with local repository caching
- **Git**: 2.x for source control
- **SSH Server**: OpenSSH for IDE connectivity

Verify tools are working:

```bash
docker compose exec devdocker verify-tools.sh
```

## Architecture

- **Base Image**: `tomcat:9.0-jdk21-temurin-noble` (for GeoServer 2.28.x) — automatically selected based on detected version, see the FAQ in [README.md](../README.md#common-questions)
- **Build Tools**: JDK 21, Maven 3.8+, Git 2.x
- **Ports**: SSH (22→2222), JDWP (5005), GeoServer (8080)
- **Volumes**:
  - Home directory: `devdocker-home` (named volume, persists dotfiles, configs, SSH keys, custom tools)
  - Source code: `devdocker-workspace` (named volume, cloned inside container)
  - Maven repository: `devdocker-maven-repo` (named volume, symlinked to `/root/.m2/repository`)
  - Data directory: bind mount to `../geoserver-data` (convenient host access) — see [Data Directory](DATA-DIRECTORY.md)
  - Scripts: bind mount to `./scripts` (edit on host)
  - SSH keys source: bind mount to `./ssh-keys` (copied to `/root/.ssh` on startup)
