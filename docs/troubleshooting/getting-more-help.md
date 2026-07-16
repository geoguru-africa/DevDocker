[← Troubleshooting Index](../TROUBLESHOOTING.md)

## Getting More Help

If you've tried the solutions above and still have issues:

### 1. Check Container Logs

```bash
# View all logs
docker logs devdocker

# Follow logs in real-time
docker logs -f devdocker

# View last 100 lines
docker logs --tail 100 devdocker
```

### 2. Check GeoServer Logs

```bash
# View GeoServer application logs
docker exec devdocker tail -f /var/log/geoserver.log

# View Tomcat logs
docker exec devdocker tail -f /usr/local/tomcat/logs/catalina.out
```

### 3. Inspect Container

```bash
# Get detailed container information
docker inspect devdocker

# Check environment variables
docker exec devdocker env

# Check running processes
docker exec devdocker ps aux
```

### 4. Test Components Individually

```bash
# Test SSH
ssh -v -p 2222 root@localhost

# Test Maven
docker exec devdocker mvn --version

# Test Java
docker exec devdocker java -version

# Test network
docker exec devdocker ping -c 3 repo.maven.apache.org
```

### 5. Report Issues

When reporting issues, include:
- Operating system and version
- Docker version: `docker --version`
- Docker Compose version: `docker compose version`
- Container logs: `docker logs devdocker`
- Steps to reproduce the issue
- Error messages (full text)

### 6. Community Resources

- GeoServer Mailing List: https://geoserver.org/comm/
- GeoServer GitHub Issues: https://github.com/geoserver/geoserver/issues
- Docker Documentation: https://docs.docker.com/

---

