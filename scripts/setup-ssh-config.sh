#!/bin/bash
# Setup SSH Config for DevDocker
# Creates or updates SSH config file with DevDocker host entry

set -e

echo "=== SSH Config Setup for GeoServer DevDocker ==="
echo ""

# Detect SSH directory (handle Windows paths)
if [ -d "$HOME/.ssh" ]; then
    SSH_DIR="$HOME/.ssh"
elif [ -d "/c/Users/$USER/.ssh" ]; then
    SSH_DIR="/c/Users/$USER/.ssh"
elif [ -n "$USERPROFILE" ] && [ -d "$(cygpath -u "$USERPROFILE")/.ssh" 2>/dev/null ]; then
    SSH_DIR="$(cygpath -u "$USERPROFILE")/.ssh"
else
    SSH_DIR="$HOME/.ssh"
fi

SSH_CONFIG="$SSH_DIR/config"

echo "SSH directory: $SSH_DIR"
echo ""

# Create .ssh directory if it doesn't exist
if [ ! -d "$SSH_DIR" ]; then
    echo "Creating SSH directory..."
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
fi

# Find private keys
priv_keys=()
if [ -d "$SSH_DIR" ]; then
    # Look for private keys with corresponding .pub files
    while IFS= read -r -d '' file; do
        base_name="${file%.pub}"
        if [ -f "$base_name" ]; then
            priv_keys+=("$base_name")
        fi
    done < <(find "$SSH_DIR" -maxdepth 1 -name "*.pub" -type f -print0 2>/dev/null)
    
    # Also look for .pem files
    while IFS= read -r -d '' file; do
        priv_keys+=("$file")
    done < <(find "$SSH_DIR" -maxdepth 1 -name "*.pem" -type f -print0 2>/dev/null)
fi

if [ ${#priv_keys[@]} -eq 0 ]; then
    echo "ERROR: No SSH private keys found in $SSH_DIR"
    echo "Please run ./scripts/setup-ssh-keys.sh first to configure SSH keys"
    exit 1
fi

# Let user select a key
echo "Found ${#priv_keys[@]} SSH private key(s):"
for i in "${!priv_keys[@]}"; do
    echo "  $((i+1)). $(basename "${priv_keys[$i]}")"
done
echo ""

if [ ${#priv_keys[@]} -eq 1 ]; then
    selected_key="${priv_keys[0]}"
    echo "Using: $(basename "$selected_key")"
else
    read -p "Select a key to use (1-${#priv_keys[@]}): " key_choice
    
    if [ "$key_choice" -gt 0 ] && [ "$key_choice" -le ${#priv_keys[@]} ]; then
        selected_key="${priv_keys[$((key_choice-1))]}"
        echo "Using: $(basename "$selected_key")"
    else
        echo "ERROR: Invalid selection"
        exit 1
    fi
fi

echo ""

# Check if config file exists and has DevDocker entry
if [ -f "$SSH_CONFIG" ]; then
    if grep -q "Host devdocker" "$SSH_CONFIG"; then
        echo "DevDocker entry already exists in SSH config"
        read -p "Update it? (y/n): " update_config
        
        if [ "$update_config" != "y" ] && [ "$update_config" != "Y" ]; then
            echo "Skipping SSH config update"
            exit 0
        fi
        
        # Remove old entry
        echo "Removing old DevDocker entry..."
        sed -i '/Host devdocker/,/^$/d' "$SSH_CONFIG"
    fi
else
    echo "Creating new SSH config file..."
    touch "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
fi

# Add DevDocker entry
echo "Adding DevDocker entry to SSH config..."
cat >> "$SSH_CONFIG" << EOF

Host devdocker
    HostName localhost
    Port 2222
    User root
    IdentityFile $selected_key
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

EOF

echo ""
echo "✓ SSH config updated successfully!"
echo ""
echo "SSH config location: $SSH_CONFIG"
echo ""
echo "You can now connect using:"
echo "  1. Command line: ssh devdocker"
echo "  2. Kiro IDE: Remote-SSH: Connect to Host → devdocker"
echo ""
echo "To test the connection:"
echo "  ssh devdocker 'echo Connection successful!'"
echo ""
