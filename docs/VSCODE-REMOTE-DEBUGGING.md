# VS Code Remote Debugging Guide

This guide provides comprehensive instructions for setting up and using VS Code for remote debugging of GeoServer in the DevDocker environment.

## Overview

VS Code provides excellent support for remote Java debugging through:
- **Remote - SSH extension**: Connect to the DevDocker container
- **Extension Pack for Java**: Java language support and debugging capabilities
- **JDWP protocol**: Attach to running GeoServer instance on port 5005

## Prerequisites

- VS Code installed on your host machine
- DevDocker container running (`docker-compose up -d`)
- SSH keys configured (see [IDE Connectivity Guide](IDE-CONNECTIVITY.md))
- GeoServer source code cloned in `/workspace/geoserver`

## Step 1: Install Remote - SSH Extension

The Remote - SSH extension allows VS Code to connect to the DevDocker container and work with files as if they were local.

### Installation

1. **Open VS Code**

2. **Open Extensions panel**:
   - Press `Ctrl+Shift+X` (Windows/Linux) or `Cmd+Shift+X` (macOS)
   - Or click the Extensions icon in the Activity Bar (left sidebar)

3. **Search for "Remote - SSH"**:
   - Type "Remote - SSH" in the search box
   - Look for the official extension by Microsoft
   - Extension ID: `ms-vscode-remote.remote-ssh`

4. **Install the extension**:
   - Click the "Install" button
   - Wait for installation to complete
   - If prompted, click "Reload" or restart VS Code

5. **Verify installation**:
   - You should see a new icon in the bottom-left corner of VS Code (><)
   - Or check the Command Palette (`Ctrl+Shift+P`) for "Remote-SSH" commands

## Step 2: Configure SSH Connection

VS Code needs to know how to connect to the DevDocker container via SSH.

### Option A: Automated Setup (Recommended)

Run the automated SSH config setup script:

```bash
./scripts/setup-ssh-config.sh
```

This script will:
- Detect all SSH private keys (including .pem files)
- Let you select which key to use
- Create or update your `~/.ssh/config` file with the DevDocker host entry
- Use the correct path format for your operating system

After running the script, you can connect using the host alias:
```bash
ssh devdocker
```

### Option B: Manual SSH Config

Add to your `~/.ssh/config` file:

**On Linux/macOS**:
```
Host devdocker
    HostName localhost
    Port 2222
    User root
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

**On Windows** (note the path format):
```
Host devdocker
    HostName localhost
    Port 2222
    User root
    IdentityFile C:/Users/YourUsername/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

**Important Notes**:
- **Windows paths**: Use forward slashes (`/`) and the `C:/Users/` format, not Unix-style `/c/Users/` paths
- **Host key verification**: `StrictHostKeyChecking no` and `UserKnownHostsFile /dev/null` disable SSH host key verification, which prevents warnings when rebuilding the container (new host keys are generated each time). This is safe for local development but should not be used for production servers. See [SSH Host Key Verification](SSH-HOST-KEY-VERIFICATION.md) for details.

### Option C: Test SSH Connection

Verify SSH connectivity before connecting with VS Code:

```bash
./scripts/test-ssh-connection.sh
```

This script will:
- Check if the container is running
- Detect available SSH keys
- Let you select which key to use (if multiple found)
- Test the SSH connection
- Display workspace directories if successful

## Step 3: Connect VS Code to DevDocker

Now connect VS Code to the remote container.

### Connect Using SSH Config

1. **Open Command Palette**:
   - Press `Ctrl+Shift+P` (Windows/Linux) or `Cmd+Shift+P` (macOS)

2. **Select "Remote-SSH: Connect to Host"**:
   - Type "Remote-SSH: Connect"
   - Select "Remote-SSH: Connect to Host..."

3. **Select "devdocker"** from the list:
   - If you used the automated setup or manual config, you'll see "devdocker" in the list
   - Click on it to connect

4. **Wait for connection**:
   - VS Code will open a new window
   - It will install the VS Code Server on the remote container (first time only)
   - This may take 1-2 minutes on first connection

5. **Verify connection**:
   - Look at the bottom-left corner of VS Code
   - You should see "SSH: devdocker" indicating you're connected
   - The integrated terminal will show the container's shell prompt

### Connect Without SSH Config (Direct)

If you prefer not to use an SSH config file:

1. **Open Command Palette** (`Ctrl+Shift+P`)

2. **Select "Remote-SSH: Connect to Host"**

3. **Select "Add New SSH Host..."**

4. **Enter the full SSH command**:
   - Linux/macOS: `ssh -i ~/.ssh/id_rsa -p 2222 root@localhost`
   - Windows: `ssh -i C:/Users/YourUsername/.ssh/id_rsa -p 2222 root@localhost`

5. **Select which config file to save to** (or skip)

6. **Connect to the newly added host**

## Step 4: Install Extension Pack for Java (Remote)

Once connected to the DevDocker container, you need to install Java extensions **in the remote environment**.

### Why Install Remotely?

VS Code extensions can be installed in two contexts:
- **Locally**: Run on your host machine (UI extensions)
- **Remotely**: Run inside the container (language support, debugging)

Java extensions must be installed remotely to access the JDK and source code inside the container.

### Installation Steps

1. **Verify you're connected**:
   - Check bottom-left corner shows "SSH: devdocker"
   - If not connected, follow Step 3 above

2. **Open Extensions panel**:
   - Press `Ctrl+Shift+X` (Windows/Linux) or `Cmd+Shift+X` (macOS)
   - Or click the Extensions icon in the Activity Bar

3. **Search for "Extension Pack for Java"**:
   - Type "Extension Pack for Java" in the search box
   - Look for the official pack by Microsoft
   - Extension ID: `vscjava.vscode-java-pack`

4. **Install in SSH: devdocker**:
   - You'll see two buttons: "Install" and "Install in SSH: devdocker"
   - Click **"Install in SSH: devdocker"** (the remote button)
   - Wait for installation to complete (may take 2-3 minutes)

5. **Included extensions**:
   The Extension Pack for Java includes:
   - Language Support for Java (Red Hat)
   - Debugger for Java
   - Test Runner for Java
   - Maven for Java
   - Project Manager for Java
   - Visual Studio IntelliCode

6. **Verify installation**:
   - Open a Java file (e.g., `/workspace/geoserver/src/main/src/main/java/org/geoserver/config/GeoServer.java`)
   - You should see syntax highlighting and IntelliSense
   - Check the bottom-right corner for Java language server status

### Troubleshooting Extension Installation

**Problem: "Install in SSH: devdocker" button not visible**

Solution: You're not connected to the remote container. Check bottom-left corner and reconnect if needed.

**Problem: Java extension fails to activate**

Solution:
1. Check Java is installed: Open terminal and run `java -version`
2. Reload VS Code window: Command Palette → "Developer: Reload Window"
3. Check extension logs: Command Palette → "Java: Open Java Language Server Log"

**Problem: IntelliSense not working**

Solution:
1. Wait for Java language server to initialize (check bottom-right status)
2. Import Maven project: Command Palette → "Java: Import Java Projects into Workspace"
3. Clean Java workspace: Command Palette → "Java: Clean Java Language Server Workspace"

## Step 5: Open GeoServer Web App Module

**IMPORTANT**: Do NOT open the entire `/workspace/geoserver` folder - it contains hundreds of Maven modules and will take 60+ minutes to index. Instead, open just the web/app module where most debugging happens.

1. **Open the web/app folder**:
   - File → Open Folder (`Ctrl+K Ctrl+O`)
   - Navigate to: `/workspace/geoserver/src/web/app`
   - Click "OK"

2. **Trust the workspace**:
   - VS Code will ask if you trust the authors
   - Click "Yes, I trust the authors"

3. **Wait for Java project import**:
   - The Java extension will detect the Maven project
   - It will import and index the module (2-3 minutes)
   - Check bottom-right corner for "Java: Ready" status

4. **Verify Java support is working**:
   - Open a Java file: `src/test/java/org/geoserver/web/Start.java`
   - You should see syntax highlighting
   - Hover over a class name - you should see documentation
   - IntelliSense should work when typing

## Step 6: Configure Debug Launch Configuration

VS Code needs a launch configuration to attach to the running GeoServer instance.

### Create launch.json

1. **Create launch.json file**:
   - File → New Text File (`Ctrl+N`)
   - Copy and paste this configuration:
     ```json
     {
       "version": "0.2.0",
       "configurations": [
         {
           "type": "java",
           "name": "Debug GeoServer (Remote)",
           "request": "attach",
           "hostName": "localhost",
           "port": 5005,
           "projectName": "gs-main"
         }
       ]
     }
     ```
   - File → Save As (`Ctrl+Shift+S`)
   - Save to: `/root/.vscode/launch.json`
   - VS Code will ask to create the `.vscode` directory if it doesn't exist


### Configuration Explanation

The launch.json configuration:
- `type`: "java" - Use Java debugger
- `name`: Display name shown in Run and Debug panel
- `request`: "attach" - Attach to running process (not launch new one)
- `hostName`: "localhost" - JDWP is exposed on localhost
- `port`: 5005 - Debug port configured in docker-compose.yml
- `projectName`: "gs-main" - Main GeoServer project (optional, helps with source mapping)

### Alternative: Multiple Configurations

For more flexibility, you can add multiple configurations:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "java",
      "name": "Debug GeoServer (Remote)",
      "request": "attach",
      "hostName": "localhost",
      "port": 5005,
      "projectName": "gs-main"
    },
    {
      "type": "java",
      "name": "Debug GeoServer (Custom Port)",
      "request": "attach",
      "hostName": "localhost",
      "port": "${input:debugPort}",
      "projectName": "gs-main"
    }
  ],
  "inputs": [
    {
      "id": "debugPort",
      "type": "promptString",
      "description": "Debug port",
      "default": "5005"
    }
  ]
}
```

This allows you to specify a custom debug port if you've changed it in `.env`.

## Step 7: Start GeoServer with Debugging

Before attaching the debugger, GeoServer must be running with JDWP enabled.

### Build GeoServer

If you haven't built GeoServer yet:

1. **Open integrated terminal**:
   - Terminal → New Terminal
   - Or press `` Ctrl+` ``

2. **Build GeoServer**:
   ```bash
   cd /workspace/geoserver
   build-geoserver.sh
   ```

3. **Wait for build to complete**:
   - First build: ~10-15 minutes (downloads dependencies)
   - Subsequent builds: ~2-3 minutes

### Start GeoServer

1. **In the integrated terminal**, run:
   ```bash
   start-geoserver.sh
   ```

2. **Wait for GeoServer to start**:
   - Watch the logs for "Server startup in [X] milliseconds"
   - GeoServer is ready when you see the startup message

3. **Verify JDWP is enabled**:
   - Look for "Listening for transport dt_socket at address: 5005" in the logs
   - This confirms the debug agent is running

4. **Verify GeoServer is accessible**:
   - Open browser: http://localhost:8080/geoserver
   - You should see the GeoServer welcome page
   - Default credentials: admin / geoserver

## Step 8: Attach Debugger

Now attach VS Code's debugger to the running GeoServer instance.

1. **Open Run and Debug panel**:
   - Click the Run and Debug icon in the Activity Bar (left sidebar)
   - Or press `Ctrl+Shift+D`

2. **Start debugging**:
   - Click the green play button (▶) next to "Debug GeoServer (Remote)"
   - Or press `F5`
   - VS Code will use the launch.json configuration to attach to port 5005

3. **Verify connection**:
   - The debug toolbar should appear at the top of VS Code
   - The status bar at the bottom should turn orange
   - The Debug Console should show "Debugger attached"

4. **If connection fails**:
   - Check GeoServer is running: Look for "Listening for transport dt_socket" in logs
   - Verify port 5005 is exposed: `docker-compose port devdocker 5005`
   - Check firewall settings on host machine

## Step 9: Set Breakpoints and Debug

Now you can set breakpoints and debug GeoServer.

### Setting Breakpoints in Web/App Module

1. **Open a Java file in the web/app module**:
   - Navigate to a file you want to debug
   - Example: `src/test/java/org/geoserver/web/Start.java`

2. **Set a breakpoint**:
   - Click in the gutter (left of line numbers) on the line where you want to pause
   - A red dot will appear indicating a breakpoint
   - Or press `F9` with cursor on the line

### Setting Breakpoints in Other Modules

Since you only have the web/app module open, you need to open files from other modules directly:

1. **Open a file from another module**:
   - File → Open File (`Ctrl+O`)
   - Navigate to the file you want to debug
   - Example: `/workspace/geoserver/src/main/src/main/java/org/geoserver/catalog/impl/CatalogImpl.java`
   - The file will open even though the module isn't in your workspace

2. **Set breakpoints in the opened file**:
   - Click in the gutter to set breakpoints
   - Breakpoints work perfectly even though the module isn't indexed
   - The debugger uses source mapping, not workspace indexing

3. **Why this works**:
   - JDWP debugging attaches to the running GeoServer process
   - Source mapping works across all modules
   - You don't need the module indexed to set breakpoints
   - Breakpoints are based on file path, not workspace structure

**Tip**: Keep commonly debugged files open in tabs for quick access.

### Conditional Breakpoints

1. **Right-click on a breakpoint**
2. **Select "Edit Breakpoint..."**
3. **Add a condition**:
   - Expression: `layerName.equals("roads")`
   - Hit count: `> 5` (break after 5th hit)
   - Log message: `Layer: {layerName}`

### Triggering Breakpoints

1. **Interact with GeoServer**:
   - Open browser: http://localhost:8080/geoserver
   - Navigate to a page that will execute your code
   - Example: Layer Preview → Select a layer → OpenLayers

2. **Execution pauses at breakpoint**:
   - VS Code will come to focus
   - The line with the breakpoint will be highlighted
   - The Debug panel shows variables, call stack, and watch expressions

### Debug Controls

Use the debug toolbar at the top of VS Code:

- **Continue** (F5): Resume execution until next breakpoint
- **Step Over** (F10): Execute current line and move to next line
- **Step Into** (F11): Enter into method calls
- **Step Out** (Shift+F11): Exit current method
- **Restart** (Ctrl+Shift+F5): Restart debugging session
- **Stop** (Shift+F5): Disconnect debugger

### Inspecting Variables

1. **Variables panel**:
   - Shows all local variables and their values
   - Expand objects to see fields
   - Hover over variables in code to see values

2. **Watch expressions**:
   - Add expressions to watch continuously
   - Click "+" in Watch panel
   - Enter expression (e.g., `request.getParameter("layer")`)

3. **Debug Console**:
   - Evaluate expressions interactively
   - Type expression and press Enter
   - Example: `layerName.toUpperCase()`

### Call Stack

The Call Stack panel shows:
- Current execution point (top of stack)
- Method call chain leading to current point
- Click on any frame to see variables at that point

## Step 10: Hot Code Replacement

VS Code supports hot code replacement (HCR) for compatible changes.

### What Works (Compatible Changes)

Hot code replacement works for:
- **Method body changes**: Modifying the implementation of existing methods
- **Variable values**: Changing local variable values during debugging
- **Expression evaluation**: Testing code snippets in the debug console

### Workflow for HCR

1. **Pause at a breakpoint**

2. **Modify the method**:
   - Edit the method body (don't change signature)
   - Save the file (Ctrl+S)

3. **VS Code recompiles**:
   - The Java extension automatically recompiles the file
   - New bytecode is sent to the JVM

4. **Continue execution**:
   - Press F5 to continue
   - The new code runs immediately

5. **Verify the change**:
   - Trigger the same code path again
   - The modified code should execute

### What Doesn't Work (Incompatible Changes)

Hot code replacement **does NOT work** for structural changes:
- **Adding or removing methods**: Requires full restart
- **Changing method signatures**: Parameter types, return types, or method names
- **Adding or removing fields**: Class structure changes
- **Changing class hierarchy**: Modifying extends or implements clauses
- **Adding or removing classes**: New classes or deleted classes

### Handling Incompatible Changes

When you make an incompatible change:

1. **VS Code shows a warning**:
   - "Hot code replace failed - add method not implemented"
   - Or similar message in Debug Console

2. **Stop the debugger**:
   - Click Stop button or press Shift+F5

3. **Stop GeoServer**:
   - In the terminal running GeoServer, press Ctrl+C

4. **Rebuild the changed module**:
   ```bash
   cd /workspace/geoserver/src
   mvn install -DskipTests -pl web/app -am
   ```

5. **Restart GeoServer**:
   ```bash
   start-geoserver.sh
   ```

6. **Reattach debugger**:
   - Press F5 in VS Code

## Troubleshooting

### Common Issues and Solutions

#### Language Support for Java Required Error

**Symptoms**: "Language Support for Java is required. Please install and enable it." when trying to debug, even though the extension is installed

**Root Cause**: Known caching bug in VS Code Java extension where the IDE fails to recognize that the Java language support extension is already active.

**Solution - Clear Extension Cache (3 Steps)**:

1. **Clear Java Language Server workspace cache**:
   ```bash
   rm -rf ~/.config/Code/User/workspaceStorage/*/redhat.java
   ```

2. **Clear Java extension global storage**:
   ```bash
   rm -rf ~/.config/Code/User/globalStorage/redhat.java
   ```

3. **Reload VS Code window**:
   - Command Palette (`Ctrl+Shift+P`) → "Developer: Reload Window"
   - Or press `Ctrl+R`

**Verification**:
- Open any Java file
- Press `F5` to start debugging
- Error should no longer appear

**If error persists** - Complete extension purge:
```bash
# Remove all Java extension traces
rm -rf ~/.vscode/extensions/redhat.java-*
rm -rf ~/.config/Code/User/globalStorage/redhat.java*
rm -rf ~/.config/Code/User/workspaceStorage/*/redhat.java
```
Then uninstall and reinstall "Language Support for Java" extension.

**Note**: On Windows, paths are in `%APPDATA%\Code\User\` instead of `~/.config/Code/User/`

#### Debugger Won't Attach

**Symptoms**: "Failed to attach to remote debugger" or "Connection refused"

**Solutions**:
1. **Verify GeoServer is running**:
   ```bash
   docker-compose exec devdocker ps aux | grep java
   ```
   You should see a Java process running.

2. **Check JDWP is enabled**:
   ```bash
   docker-compose exec devdocker bash -c "echo \$JAVA_OPTS"
   ```
   Should include: `-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005`

3. **Verify port is exposed**:
   ```bash
   docker-compose port devdocker 5005
   ```
   Should show: `0.0.0.0:5005` or `127.0.0.1:5005`

4. **Check firewall**:
   - Temporarily disable firewall to test
   - Add exception for port 5005 if needed

5. **Restart GeoServer with debug logging**:
   ```bash
   start-geoserver.sh
   # Look for "Listening for transport dt_socket at address: 5005"
   ```

#### Breakpoints Not Hitting

**Symptoms**: Breakpoints are set but never trigger

**Solutions**:
1. **Verify breakpoint is valid**:
   - Breakpoint should have a red dot (not gray or hollow)
   - Gray/hollow means source doesn't match running code

2. **Rebuild and restart**:
   - Code may have changed since last build
   - Rebuild: `mvn install -DskipTests -pl web/app -am`
   - Restart GeoServer

3. **Check source mapping**:
   - Ensure you're debugging the correct project
   - Verify `projectName` in launch.json matches your project

4. **Verify code path is executed**:
   - Add logging to confirm code is reached
   - Check GeoServer logs for your log statements

5. **Try a different breakpoint location**:
   - Set breakpoint on a line you know executes
   - Example: First line of a servlet's `doGet()` method

#### IntelliSense Not Working

**Symptoms**: No code completion, red squiggles on valid code

**Solutions**:
1. **Wait for Java language server**:
   - Check bottom-right corner for "Java: Ready" or progress indicator
   - Initial indexing can take 5-10 minutes

2. **Import Maven project**:
   - Command Palette → "Java: Import Java Projects into Workspace"
   - Select `/workspace/geoserver`

3. **Clean Java workspace**:
   - Command Palette → "Java: Clean Java Language Server Workspace"
   - Reload window when prompted

4. **Check Java extension logs**:
   - Command Palette → "Java: Open Java Language Server Log"
   - Look for errors or warnings

5. **Verify JDK is detected**:
   - Command Palette → "Java: Configure Java Runtime"
   - Should show JDK 21 at `/opt/java/openjdk`

#### Slow Performance

**Symptoms**: VS Code is slow, high CPU usage

**Solutions**:
1. **Exclude large directories from indexing**:
   - Add to `.vscode/settings.json`:
     ```json
     {
       "files.watcherExclude": {
         "**/target/**": true,
         "**/.git/**": true,
         "**/node_modules/**": true
       },
       "java.import.exclusions": [
         "**/target/**",
         "**/node_modules/**"
       ]
     }
     ```

2. **Reduce Java language server memory**:
   - Add to `.vscode/settings.json`:
     ```json
     {
       "java.jdt.ls.vmargs": "-Xmx1G"
     }
     ```

3. **Disable unused extensions**:
   - Disable extensions you don't need in the remote environment

4. **Use incremental builds**:
   - Build only changed modules: `mvn install -pl <module> -am`

#### Hot Code Replacement Fails

**Symptoms**: "Hot code replace failed" message

**Solutions**:
1. **Check change type**:
   - Only method body changes are supported
   - Structural changes require restart

2. **Verify compilation succeeded**:
   - Check Problems panel (Ctrl+Shift+M)
   - Fix any compilation errors

3. **Restart debugging session**:
   - Stop debugger (Shift+F5)
   - Rebuild: `mvn install -DskipTests -pl web/app -am`
   - Restart GeoServer
   - Reattach debugger (F5)

#### Connection Drops During Debugging

**Symptoms**: Debugger disconnects unexpectedly

**Solutions**:
1. **Check GeoServer is still running**:
   ```bash
   docker-compose exec devdocker ps aux | grep java
   ```

2. **Check container is running**:
   ```bash
   docker-compose ps
   ```

3. **Increase timeout**:
   - Add to launch.json:
     ```json
     {
       "timeout": 30000
     }
     ```

4. **Check network stability**:
   - Ensure stable connection to Docker
   - Restart Docker if needed

## Advanced Configuration

### Custom Debug Port

If you've changed the debug port in `.env`:

1. **Update launch.json**:
   ```json
   {
     "port": 5006
   }
   ```

2. **Or use input variable**:
   ```json
   {
     "port": "${input:debugPort}"
   }
   ```

### Multiple Debug Configurations

For different debugging scenarios:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "java",
      "name": "Debug GeoServer (Main)",
      "request": "attach",
      "hostName": "localhost",
      "port": 5005,
      "projectName": "gs-main"
    },
    {
      "type": "java",
      "name": "Debug GeoServer (WFS)",
      "request": "attach",
      "hostName": "localhost",
      "port": 5005,
      "projectName": "gs-wfs"
    },
    {
      "type": "java",
      "name": "Debug GeoServer (WMS)",
      "request": "attach",
      "hostName": "localhost",
      "port": 5005,
      "projectName": "gs-wms"
    }
  ]
}
```

### Step Filters

To skip framework code during debugging:

1. **Add to settings.json**:
   ```json
   {
     "java.debug.settings.stepping.skipClasses": [
       "java.*",
       "javax.*",
       "sun.*",
       "com.sun.*",
       "org.springframework.*"
     ]
   }
   ```

2. **Or configure in UI**:
   - File → Preferences → Settings
   - Search for "java debug stepping"
   - Add class patterns to skip

### Logpoints

Set logpoints instead of breakpoints to log without pausing:

1. **Right-click in gutter**
2. **Select "Add Logpoint..."**
3. **Enter message**: `Layer name: {layerName}`
4. **Execution logs message without pausing**

### Conditional Breakpoints

Break only when specific conditions are met:

1. **Right-click on breakpoint**
2. **Select "Edit Breakpoint..."**
3. **Add condition**:
   - Expression: `layerName.equals("roads")`
   - Hit count: `> 5` (break after 5th hit)
   - Log message: `Layer: {layerName}`

## Best Practices

### Debugging Workflow

1. **Start with logging**: Add log statements to understand code flow
2. **Set strategic breakpoints**: Don't set too many at once
3. **Use conditional breakpoints**: Reduce noise from frequent code paths
4. **Step through carefully**: Use Step Over (F10) for most navigation
5. **Inspect variables**: Check values before assuming behavior
6. **Use watch expressions**: Monitor key variables continuously
7. **Test HCR first**: Try hot code replacement before full restart
8. **Rebuild incrementally**: Only rebuild changed modules

### Performance Tips

1. **Exclude large directories**: Prevent indexing of target/, node_modules/
2. **Use incremental builds**: `mvn install -pl <module> -am`
3. **Disable unused extensions**: Reduce resource usage
4. **Close unused files**: Keep only relevant files open
5. **Use SSH connection pooling**: Add to ~/.ssh/config:
   ```
   ControlMaster auto
   ControlPath ~/.ssh/control-%r@%h:%p
   ControlPersist 10m
   ```

### Security Considerations

1. **SSH keys**: Use strong keys (ED25519 or RSA 4096-bit)
2. **Private keys**: Never commit to version control
3. **Debug port**: Only expose to localhost (not 0.0.0.0)
4. **Production**: Disable debugging in production environments
5. **Sensitive data**: Don't log passwords or API keys

## Limitations

### Known Limitations

1. **Hot Code Replacement**:
   - Only method body changes supported
   - Structural changes require restart
   - No support for adding/removing methods or fields

2. **Performance**:
   - Initial project import can take 5-10 minutes
   - Large projects may be slow to index
   - Remote file operations slower than local

3. **Maven Integration**:
   - Some Maven operations may be slower remotely
   - Build output may not stream in real-time
   - Dependency resolution can be slow on first build

4. **Source Mapping**:
   - Breakpoints may not work if source doesn't match compiled code
   - Requires rebuild after structural changes
   - Multi-module projects may have mapping issues

5. **Extension Compatibility**:
   - Not all VS Code extensions work remotely
   - Some extensions require local installation
   - Extension updates may require reconnection

### Workarounds

1. **For slow indexing**: Exclude large directories from workspace
2. **For HCR limitations**: Plan structural changes for rebuild cycles
3. **For slow Maven**: Use incremental builds and local repository cache
4. **For source mapping**: Always rebuild after pulling changes
5. **For extension issues**: Check extension documentation for remote support

## Additional Resources

- [VS Code Remote Development](https://code.visualstudio.com/docs/remote/remote-overview)
- [VS Code Java Debugging](https://code.visualstudio.com/docs/java/java-debugging)
- [Extension Pack for Java](https://marketplace.visualstudio.com/items?itemName=vscjava.vscode-java-pack)
- [JDWP Specification](https://docs.oracle.com/javase/8/docs/technotes/guides/jpda/jdwp-spec.html)
- [GeoServer Developer Guide](https://docs.geoserver.org/latest/en/developer/)

## Summary

You now have a complete VS Code remote debugging setup for GeoServer development:

✅ Remote - SSH extension installed
✅ Extension Pack for Java installed in remote environment
✅ SSH connection configured
✅ GeoServer workspace opened
✅ Debug launch configuration created
✅ Debugger attached to running GeoServer
✅ Breakpoints set and working
✅ Hot code replacement enabled for compatible changes

Happy debugging! 🐛🔍
