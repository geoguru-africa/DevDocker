[← Troubleshooting Index](../TROUBLESHOOTING.md)

## Quick Reference

### Essential Commands

```bash
# Start environment
docker compose up -d

# Stop environment
docker compose down

# Restart environment
docker compose restart

# View logs
docker logs devdocker

# Connect via SSH
ssh -p 2222 root@localhost

# Check container status
docker ps

# Check volumes
docker volume ls

# Clean everything (WARNING: Deletes all data)
docker compose down -v
docker system prune -a
```

### Common File Locations

- **Source code**: `/workspace/geoserver`, `/workspace/geotools`, `/workspace/geowebcache`
- **Maven repository**: `/root/.m2/repository`
- **Data directory**: `/opt/geoserver/data_dir`
- **GeoServer logs**: `/var/log/geoserver.log`
- **Tomcat logs**: `/usr/local/tomcat/logs/catalina.out`
- **Build scripts**: `/opt/devdocker/scripts/`
- **SSH config**: `/root/.ssh/`

### Environment Variables

- `SSH_PORT`: SSH port (default: 2222)
- `DEBUG_PORT`: JDWP debug port (default: 5005)
- `GEOSERVER_PORT`: GeoServer web port (default: 8080)
- `CUSTOM_GEOTOOLS`: Build local GeoTools (default: false)
- `CUSTOM_GEOWEBCACHE`: Build local GeoWebCache (default: false)
- `JAVA_OPTS`: JVM options (default: -Xms512m -Xmx2g)
- `GEOSERVER_DATA_DIR`: Data directory path (default: /opt/geoserver/data_dir)

---

**Last Updated**: 2024
**Version**: 1.0
