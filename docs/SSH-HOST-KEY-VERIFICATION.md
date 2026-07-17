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

## `choose_kex: unsupported KEX method sntrup761x25519-sha512@openssh.com`

### Symptom

```
ssh-keyscan -4 -p 2222 localhost >> ~/.ssh/known_hosts
# localhost:2222 SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13.18
choose_kex: unsupported KEX method sntrup761x25519-sha512@openssh.com
```

repeated for every retry, with nothing appended to `known_hosts`. This is a
different failure from the host-key-changed warning above — it happens
*before* any host key is even exchanged, so removing/re-adding entries in
`known_hosts` will not fix it.

### Root cause

This is a **client-side** bug, not a container or network problem:

- The container's SSH server is OpenSSH 9.6 (Ubuntu 24.04 base image), which
  defaults to offering the post-quantum key exchange algorithm
  `sntrup761x25519-sha512@openssh.com` as its top preference.
- The `ssh-keyscan.exe` / `ssh.exe` bundled with Windows (the "OpenSSH
  Client" optional feature, Win32-OpenSSH) is often an older build that
  advertises support for that KEX method in its own proposal but doesn't
  actually implement it. When the server picks it, the Windows client's own
  `choose_kex()` fails to find an implementation for the algorithm it just
  claimed to support, and the handshake aborts.
- This affects `ssh-keyscan`, `ssh`, `scp`, and `sftp` equally — anything
  using the Windows-bundled OpenSSH client against a modern OpenSSH 9.x
  server.

### Fix applied in this repo

`config/sshd_config` pins `KexAlgorithms` to an explicit list that excludes
`sntrup761x25519-sha512@openssh.com`:

```
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group14-sha256
```

Since the post-quantum KEX is never offered by the server, negotiation never
reaches the code path that breaks on Windows. This fixes the problem for
**every** client without any client-side changes, so it's the preferred
fix — rebuild the image to pick it up:

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build
```

### Alternative / client-side workarounds

If you can't rebuild the container immediately:

- **Use Git Bash's `ssh-keyscan`/`ssh`** instead of the Windows one — Git for
  Windows ships a current OpenSSH build that negotiates the PQ KEX
  correctly.
- **Update the Windows OpenSSH Client** optional feature (Settings → Apps →
  Optional Features → OpenSSH Client → Update).
- **Force a classical KEX list from the client**, in `~/.ssh/config`:
  ```
  Host devdocker
      KexAlgorithms -sntrup761x25519-sha512@openssh.com
  ```
  Note: `ssh` reads this; `ssh-keyscan` does **not** honor `~/.ssh/config`,
  so this only helps regular `ssh`/`scp`/`sftp` connections, not the
  keyscan step itself.

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
