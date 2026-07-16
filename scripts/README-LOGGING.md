# Build Script Logging

All build scripts automatically log their output to `/tmp/devdocker-logs/` inside the container.

## Log Files

- `build-geoserver-latest.log` - Symlink to the latest GeoServer build log
- `build-geotrio-latest.log` - Symlink to the latest GeoTrio build log
- `build-geoserver-YYYYMMDD-HHMMSS.log` - Timestamped GeoServer build logs
- `build-geotrio-YYYYMMDD-HHMMSS.log` - Timestamped GeoTrio build logs

## Viewing Logs

### From inside the container (SSH):

```bash
# Show available logs and usage
tail-build-logs.sh

# Tail last 50 lines of GeoServer build
tail-build-logs.sh geoserver

# Tail last 100 lines of GeoTrio build
tail-build-logs.sh geotrio 100

# Follow the latest build log in real-time
tail -f /tmp/devdocker-logs/build-geoserver-latest.log
```

### From the host (if disconnected):

```bash
# Windows Git Bash
MSYS_NO_PATHCONV=1 docker exec devdocker tail -f /tmp/devdocker-logs/build-geoserver-latest.log

# Or use bash -c
docker exec devdocker bash -c "tail -f /tmp/devdocker-logs/build-geoserver-latest.log"
```

## Benefits

1. **Reconnect after disconnect**: If your SSH session drops during a long build, you can reconnect and view the logs
2. **Historical logs**: All builds are timestamped and preserved
3. **Easy debugging**: Full build output is saved for troubleshooting
4. **Real-time monitoring**: Use `tail -f` to follow builds in progress

## Log Retention

Logs are stored in `/tmp/devdocker-logs/` which is inside the container. They will persist until:
- The container is removed (not just stopped)
- You manually delete them
- The container's temporary filesystem is cleared

To preserve logs permanently, you could mount `/tmp/devdocker-logs` as a volume in docker-compose.yml.
