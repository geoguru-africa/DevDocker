# SSH Host Key Verification for DevDocker

## The Problem

When you rebuild the Docker container, SSH generates new host keys. This causes SSH clients to flag a security warning:

```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
```

This is a security feature to prevent man-in-the-middle attacks, but for local development containers that are frequently rebuilt, it becomes a nuisance.

## The Solution

For development environments, you can disable strict host key checking. This tells SSH to accept new host keys without prompting.

### Option 1: SSH Config File (Recommended)

Add these lines to your SSH config for the DevDocker host:

**Linux/macOS** (`~/.ssh/config`):
```
Host devdocker
    HostName localhost
    Port 2222
    User root
    IdentityFile ~/.ssh/your_key
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

**Windows** (`C:\Users\YourUsername\.ssh\config`):
```
Host devdocker
    HostName localhost
    Port 2222
    User root
    IdentityFile C:/Users/YourUsername/.ssh/your_key.pem
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

The key settings are:
- `StrictHostKeyChecking no` - Accept new host keys without prompting
- `UserKnownHostsFile /dev/null` - Don't save host keys (they'll change on rebuild anyway)

### Option 2: Command Line Flag

Add the flags directly to your SSH command:

```bash
ssh -i ~/.ssh/your_key -p 2222 \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    root@localhost
```

### Option 3: Remove Old Host Key

If you prefer to keep strict checking enabled, manually remove the old host key after each rebuild:

```bash
ssh-keygen -R "[localhost]:2222"
```

Then connect normally - SSH will prompt you to accept the new host key.

## Claude Desktop Users: Extra Step Required

Claude Desktop's built-in SSH client does **not** read `~/.ssh/config` at all, so `StrictHostKeyChecking no` and `UserKnownHostsFile /dev/null` (Option 1 above) have no effect on it. Instead, before connecting it runs its own check equivalent to:

```bash
ssh-keygen -F "[localhost]:2222"
```

against your real `~/.ssh/known_hosts` file. If that lookup finds no entry (or a stale one from before a rebuild), Claude Desktop fails with:

```
Connection failed: Host denied (verification failed)
```

even though a terminal `ssh devdocker` connects fine.

**Important:** if you used Option 1's `UserKnownHostsFile /dev/null`, your terminal client never writes anything to `~/.ssh/known_hosts`, so Claude Desktop will *never* find a valid entry there and will always fail — even on a fresh, correctly-running container. Removing/re-adding the connection in the Claude Desktop UI does not help either, since the trust check is keyed to the literal `host:port` (`localhost:2222`), not the connection name.

### Fix

After every container rebuild, refresh the real `known_hosts` file so Claude Desktop's lookup succeeds:

```bash
ssh-keygen -R "[localhost]:2222"
ssh-keyscan -4 -p 2222 localhost >> ~/.ssh/known_hosts
```

Then retry the connection in Claude Desktop. (The `-4` avoids `ssh-keyscan` stalling on IPv6 `::1`, which can fail even though the IPv4 loopback is fine.)

## Security Considerations

Disabling host key verification is appropriate for:
- Local development containers on localhost
- Containers that are frequently rebuilt
- Trusted network environments

Do NOT disable host key verification for:
- Production servers
- Remote servers over the internet
- Shared development servers
- Any server where security is a concern

## Automated Setup

The DevDocker setup scripts automatically configure SSH with disabled host key checking for the development environment. If you used `./scripts/setup-ssh-config.sh`, this is already configured.

## Verifying Configuration

Test your SSH connection:

```bash
ssh devdocker
```

You should connect without any host key warnings, even after rebuilding the container.
