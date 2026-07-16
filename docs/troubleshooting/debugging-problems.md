[← Troubleshooting Index](../TROUBLESHOOTING.md)

## Debugging Problems

### Cannot Connect Debugger to Port 5005

**Symptoms**:
- IDE shows "Connection refused" when attaching debugger
- Debug connection times out
- "Failed to connect to remote VM"

**Diagnosis**:
```bash
# Check if GeoServer is running
docker exec devdocker ps aux | grep java

# Check if debug port is listening
docker exec devdocker netstat -tlnp | grep 5005

# Check port mapping
docker port devdocker 5005
```

**Solutions**:

**1. Start GeoServer with Debugging**
```bash
ssh -p 2222 root@localhost
start-geoserver.sh
# Wait for "Server startup in [X] milliseconds"
```

**2. Verify Debug Port**
```bash
# Check JAVA_OPTS includes debug agent
docker exec devdocker env | grep JAVA_OPTS

# Should show: -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005
```

**3. Check Port Mapping**

Verify `docker-compose.yml`:
```yaml
ports:
  - "5005:5005"  # Debug port
```

**4. Restart with Debug Enabled**
```bash
docker-compose down
docker-compose up -d
ssh -p 2222 root@localhost
start-geoserver.sh
```



### Hot Code Replacement Not Working

**Symptoms**:
- Code changes don't take effect during debugging
- IDE shows "Hot code replacement failed"
- Changes require full restart

**Explanation**: Hot Code Replacement (HCR) has limitations. See [Hot Code Replacement](../VSCODE-REMOTE-DEBUGGING.md#step-10-hot-code-replacement) in the VS Code Remote Debugging Guide for details.

**What Works**:
- Method body changes (implementation only)
- Variable value changes
- Expression evaluation

**What Doesn't Work**:
- Adding/removing methods
- Changing method signatures
- Adding/removing fields
- Class structure changes

**Solutions**:

**For Compatible Changes** (method body only):
1. Set breakpoint and trigger it
2. Modify method implementation
3. Save file
4. IDE will hot-swap automatically
5. Continue execution

**For Incompatible Changes** (structure changes):
```bash
# Stop GeoServer (Ctrl+C)

# Rebuild changed module
cd /workspace/geoserver/src
mvn install -DskipTests -pl web/app -am

# Restart GeoServer
start-geoserver.sh

# Reconnect debugger
```

### Breakpoints Not Hit

**Symptoms**:
- Breakpoints show as disabled or hollow
- Debugger connected but breakpoints never trigger
- Code execution doesn't stop

**Solutions**:

**1. Verify Debugger is Attached**
```bash
# Check IDE shows "Connected" or "Attached"
# Check debug console for connection message
```

**2. Rebuild with Debug Symbols**
```bash
cd /workspace/geoserver/src
mvn clean install -DskipTests
start-geoserver.sh
```

**3. Check Breakpoint Location**
- Ensure breakpoint is on executable line (not comments or declarations)
- Verify you're debugging the correct module
- Check source code matches deployed code

**4. Trigger the Code Path**
```bash
# Access GeoServer to trigger your code
curl http://localhost:8080/geoserver/web/

# Or use browser to navigate to the feature
```



---

