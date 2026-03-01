# SSH Keys Directory

This directory is used to store SSH keys for connecting to the DevDocker container via SSH.

## Quick Setup (Recommended)

Use the automated setup script to configure SSH keys:

```bash
./scripts/setup-ssh-keys.sh
```

This script will:
- Detect existing SSH keys on your system
- Let you choose which key to use
- Or generate a new key pair if needed
- Copy your public key to `authorized_keys` in this directory
- Set correct permissions

After running the script, you can optionally configure your SSH config file:

```bash
./scripts/setup-ssh-config.sh
```

This creates an SSH config entry so you can connect with just `ssh devdocker` instead of the full command.

## Manual Setup

If you prefer to configure SSH keys manually:

1. Copy your SSH public key to this directory as `authorized_keys`:
   ```bash
   cp ~/.ssh/id_rsa.pub ssh-keys/authorized_keys
   ```

2. Ensure correct permissions:
   ```bash
   chmod 644 ssh-keys/authorized_keys
   ```

3. Start the container:
   ```bash
   docker-compose up -d
   ```

4. Test the connection:
   ```bash
   ssh -p 2222 root@localhost
   ```

## What Gets Mounted

The `ssh-keys/` directory is mounted into the container at `/opt/devdocker/ssh-keys-source/`. During container startup, the `entrypoint.sh` script copies the keys to `/root/.ssh/` inside the container.

## Security Notes

- **Never commit private keys** to version control
- The `.gitignore` is configured to exclude all key files except this README
- Only the `authorized_keys` file (containing public keys) should be in this directory
- Private keys remain on your host machine in `~/.ssh/`

## Troubleshooting

**Connection refused:**
```bash
# Check if container is running
docker ps

# Check if SSH server started
docker logs devdocker | grep SSH
```

**Permission denied:**
```bash
# Verify authorized_keys exists and has correct permissions
ls -la ssh-keys/authorized_keys

# Should show: -rw-r--r-- (644 permissions)
```

**Wrong key:**
```bash
# Specify the correct private key explicitly
ssh -i ~/.ssh/your_key -p 2222 root@localhost
```

For more help, see the main [README.md](../README.md) SSH connectivity section.
