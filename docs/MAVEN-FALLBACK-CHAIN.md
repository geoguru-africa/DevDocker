# Maven Repository Fallback Chain

## Overview

The DevDocker environment configures Maven to use a multi-tier fallback chain for dependency resolution. This provides flexibility for different scenarios: individual development, team collaboration, and classroom environments.

## How It Works

When Maven needs a dependency, it checks repositories in this order:

1. **Local repository** (`/root/.m2/repository` - `devdocker-maven-repo` volume)
   - Fast internal volume (Linux filesystem)
   - Populated as you build
   - Persistent across container restarts

2. **Host repository** (optional: `/root/.m2/repository-host`)
   - Your existing `~/.m2/repository` from the host machine
   - Read-only mount (no copying, instant access)
   - Only checked if mounted in docker-compose.yml

3. **Classroom/presenter mirror** (optional: configured via `MAVEN_MIRROR_URL`)
   - Shared repository server (Nexus, Artifactory, etc.)
   - Reduces bandwidth in classroom/team settings
   - Only checked if ENV variable is set

4. **Maven Central** (always available)
   - Official Maven repository
   - Final fallback for all dependencies

## Configuration

### Option 1: Default (Maven Central Only)

**When to use**: Fresh setup, good internet connection

**Setup**: None required - this is the default

**Fallback chain**:
1. Local repo (empty initially)
2. Maven Central

**First build time**: ~10-15 minutes (downloads all dependencies)

### Option 2: With Host Repository Fallback

**When to use**: You have an existing `~/.m2/repository` with GeoServer dependencies

**Setup**: Uncomment one line in `docker-compose.yml`

```yaml
volumes:
  # Uncomment this line:
  - ~/.m2/repository:/root/.m2/repository-host:ro
```

**Fallback chain**:
1. Local repo (empty initially)
2. Host repo (your existing cache)
3. Maven Central

**First build time**: ~2-3 minutes (uses host cache, no re-downloading)

**Benefits**:
- No copying (instant access via read-only mount)
- Reuses existing dependencies
- Host repo remains unchanged
- Can be enabled/disabled anytime

### Option 3: With Classroom Mirror

**When to use**: Classroom/workshop, limited bandwidth, corporate proxy

**Setup**: Set `MAVEN_MIRROR_URL` in `.env` file

```bash
# .env
MAVEN_MIRROR_URL=http://presenter-host:8081/repository/maven-public/
```

**Fallback chain**:
1. Local repo (empty initially)
2. Classroom mirror
3. Maven Central (if mirror doesn't have it)

**First build time**: ~5-10 minutes (downloads from mirror)

**Benefits**:
- Shared cache across team/class
- Reduced bandwidth usage
- Presenter controls versions
- Works with corporate proxies

### Option 4: Combined (Host + Classroom)

**When to use**: Best of both worlds - use host cache first, then classroom mirror

**Setup**: Enable both options above

```yaml
# docker-compose.yml
volumes:
  - ~/.m2/repository:/root/.m2/repository-host:ro
```

```bash
# .env
MAVEN_MIRROR_URL=http://presenter-host:8081/repository/maven-public/
```

**Fallback chain**:
1. Local repo (empty initially)
2. Host repo (your existing cache)
3. Classroom mirror (shared cache)
4. Maven Central

**First build time**: ~2-3 minutes (uses host cache)

**Benefits**:
- Fastest possible first build
- Fallback to classroom mirror for missing deps
- Maximum flexibility

## Technical Details

### How Mirrors Work

Maven mirrors are configured in `/root/.m2/settings.xml`. The entrypoint script dynamically adds mirrors based on:
- Presence of `/root/.m2/repository-host` directory
- Value of `MAVEN_MIRROR_URL` environment variable

### File-Based Repository

The host repository uses a `file://` URL:
```xml
<mirror>
  <id>host-repo</id>
  <mirrorOf>*</mirrorOf>
  <url>file:///root/.m2/repository-host</url>
</mirror>
```

This provides instant access without copying. Maven reads artifacts directly from the host filesystem.

### Mirror Priority

Maven checks mirrors in the order they appear in settings.xml. The entrypoint adds them in this order:
1. Host repo (if mounted)
2. Classroom mirror (if ENV set)
3. Maven Central (implicit, always last)

### Local Repository Behavior

The local repository (`/root/.m2/repository`) is always checked first, before any mirrors. Once an artifact is downloaded, it's cached locally and mirrors are not consulted again for that artifact.

## Verification

### Check Configured Mirrors

```bash
# View Maven settings
docker exec devdocker cat /root/.m2/settings.xml | grep -A 5 "<mirrors>"

# View startup logs
docker logs devdocker | grep "Maven repository"
```

### Test Fallback Chain

```bash
# Clear local repo to test fallback
docker exec devdocker rm -rf /root/.m2/repository/*

# Run a build and watch which repos are accessed
docker exec devdocker bash -c "cd /workspace/geoserver/src && mvn dependency:resolve -X" | grep "Downloading"
```

## Troubleshooting

### Host Repository Not Detected

**Problem**: Logs show "No host Maven repository mounted"

**Solution**: 
1. Verify the bind mount is uncommented in docker-compose.yml
2. Verify `~/.m2/repository` exists on your host
3. Restart container: `docker-compose restart`

### Classroom Mirror Not Working

**Problem**: Dependencies still download from Maven Central

**Solution**:
1. Verify `MAVEN_MIRROR_URL` is set in `.env`
2. Verify mirror server is accessible: `curl $MAVEN_MIRROR_URL`
3. Restart container: `docker-compose restart`
4. Check logs: `docker logs devdocker | grep mirror`

### Slow First Build Despite Host Repo

**Problem**: First build is slow even with host repo mounted

**Solution**:
1. Verify host repo has GeoServer dependencies:
   ```bash
   ls ~/.m2/repository/org/geoserver
   ls ~/.m2/repository/org/geotools
   ```
2. Check if host repo is actually mounted:
   ```bash
   docker exec devdocker ls -la /root/.m2/repository-host/org/geoserver
   ```

### Permission Errors

**Problem**: "Permission denied" when accessing host repo

**Solution**: Ensure host repository is readable:
```bash
chmod -R a+r ~/.m2/repository
```

## Best Practices

1. **Individual developers**: Use Option 2 (host repo fallback) for fastest setup
2. **Classrooms**: Use Option 3 (classroom mirror) for bandwidth efficiency
3. **Advanced users**: Use Option 4 (combined) for maximum speed and flexibility
4. **After first build**: Can disable host repo mount to keep docker-compose.yml clean
5. **Corporate environments**: Use Option 3 with corporate Maven proxy

## Performance Comparison

| Scenario | First Build | Subsequent Builds | Network Usage |
|----------|-------------|-------------------|---------------|
| Default (Maven Central) | 10-15 min | 2-3 min | High (several GB) |
| With host repo | 2-3 min | 2-3 min | None (uses host cache) |
| With classroom mirror | 5-10 min | 2-3 min | Low (shared cache) |
| Combined (host + mirror) | 2-3 min | 2-3 min | None (uses host cache) |

## See Also

- `.env.example` - Environment variable reference
- `docker-compose.yml` - Volume mount configuration
- `entrypoint.sh` - Mirror configuration logic
- `config/settings.xml.template` - Maven settings template
