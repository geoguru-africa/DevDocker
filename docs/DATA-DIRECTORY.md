# Data Directory Management

The DevDocker environment automatically manages the GeoServer data directory, which contains configuration, styles, workspaces, and data stores.

## Default Data Directory

On first run, the container automatically initializes a default data directory from the GeoServer source repository:

- **Location**: `/opt/geoserver/data_dir` (inside container)
- **Host Location**: `../geoserver-data` (bind mounted, one level up from devdocker directory)
- **Source**: `/workspace/geoserver/data/release` (full sample data with demo layers)
- **Persistence**: Stored as bind mount, persists across container restarts and visible on host

If the release data directory is not found, GeoServer will create its own default data directory on first startup.

## Initialization Process

The entrypoint script automatically handles data directory initialization:

1. **First Run**: Copies the minimal data directory from GeoServer source to `/opt/geoserver/data_dir`
2. **Subsequent Runs**: Uses the existing data directory (no re-copying)
3. **Persistence**: All changes to the data directory persist across container restarts and are visible on the host at `../geoserver-data` (one level up from devdocker directory)

## Verifying Data Directory

Test the data directory setup:

```bash
docker compose exec devdocker test-data-directory.sh
```

This script verifies:
- `GEOSERVER_DATA_DIR` environment variable is set
- Data directory exists and is initialized
- Key configuration files are present (global.xml, logging.xml)
- Data directory is writable

## Data Directory Structure

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

## Customizing the Data Directory

**Option 1: Modify in Container**

Make changes directly in the running container:

```bash
# Connect to container
docker compose exec devdocker bash

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

## Resetting the Data Directory

To reset to the default configuration:

```bash
# Stop container
docker compose down

# Remove or rename the data directory on host
cd ..
mv geoserver-data geoserver-data.backup

# Restart container (will re-initialize from source)
cd DevDocker
docker compose up -d
```

## Backing Up the Data Directory

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
docker compose down

# Restore backup
cd ..
tar -xzf geoserver-data-backup-20240115.tar.gz

# Restart container
cd DevDocker
docker compose up -d
```

## Troubleshooting Data Directory

**Problem: Data directory is empty**

Solution: Check if GeoServer source is available in the container:
```bash
docker compose exec devdocker ls -la /workspace/geoserver/data/
```

If empty, ensure GeoServer is cloned inside the container at `/workspace/geoserver`.

**Problem: Permission denied when accessing data directory**

Solution: Check volume permissions:
```bash
docker compose exec devdocker ls -la /opt/geoserver/
docker compose exec devdocker chmod -R 755 /opt/geoserver/data_dir
```

**Problem: Changes not persisting**

Solution: Verify the volume is properly configured:
```bash
docker volume inspect devdocker_geoserver-data
```

If the volume doesn't exist, recreate it:
```bash
docker compose down
docker compose up -d
```

See also [Troubleshooting: Data Directory Issues](troubleshooting/data-directory-issues.md) for additional problems and fixes.
