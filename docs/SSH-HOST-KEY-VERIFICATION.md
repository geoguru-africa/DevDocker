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
