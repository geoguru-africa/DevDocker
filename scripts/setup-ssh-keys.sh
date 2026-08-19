#!/bin/bash
# SSH Key Setup Helper Script
# Helps developers configure SSH keys for IDE connectivity

set -e

SSH_KEYS_DIR="./ssh-keys"
AUTHORIZED_KEYS_FILE="${SSH_KEYS_DIR}/authorized_keys"

echo "=== SSH Key Setup for GeoServer DevDocker ==="
echo ""

# Create ssh-keys directory if it doesn't exist
if [ ! -d "$SSH_KEYS_DIR" ]; then
    echo "Creating ssh-keys directory..."
    mkdir -p "$SSH_KEYS_DIR"
    chmod 700 "$SSH_KEYS_DIR"
fi

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

echo "Looking for SSH keys in: $SSH_DIR"
echo ""

# Find all .pub files in SSH directory
pub_keys=()
if [ -d "$SSH_DIR" ]; then
    while IFS= read -r -d '' file; do
        pub_keys+=("$file")
    done < <(find "$SSH_DIR" -maxdepth 1 -name "*.pub" -type f -print0 2>/dev/null)
fi

# If we found any public keys, offer them to the user
if [ ${#pub_keys[@]} -gt 0 ]; then
    echo "Found ${#pub_keys[@]} SSH public key(s):"
    for i in "${!pub_keys[@]}"; do
        echo "  $((i+1)). $(basename "${pub_keys[$i]}")"
    done
    echo ""
    read -p "Select a key to use (1-${#pub_keys[@]}), or 0 to skip: " key_choice
    
    if [ "$key_choice" -gt 0 ] && [ "$key_choice" -le ${#pub_keys[@]} ]; then
        selected_key="${pub_keys[$((key_choice-1))]}"
        echo "Using: $(basename "$selected_key")"
        echo "Copying public key to authorized_keys..."
        cp "$selected_key" "$AUTHORIZED_KEYS_FILE"
        chmod 644 "$AUTHORIZED_KEYS_FILE"
        echo "✓ SSH key configured successfully!"
        echo ""
        # Only default-named identity files (id_rsa, id_ed25519, ...) are tried
        # automatically by ssh; an arbitrarily-named selected key needs -i.
        selected_key_base="$(basename "$selected_key" .pub)"
        case "$selected_key_base" in
            id_rsa|id_ed25519|id_ecdsa|id_dsa)
                echo "You can now connect to the container via SSH:"
                echo "  ssh -p 2222 root@localhost"
                ;;
            *)
                echo "You can now connect to the container via SSH:"
                echo "  ssh -i ${selected_key%.pub} -p 2222 root@localhost"
                ;;
        esac
        echo ""
        echo "Note: authorized_keys is only copied into the container at startup."
        echo "If devdocker is already running, restart it first so this key takes effect:"
        echo "  docker compose up -d --force-recreate"
        exit 0
    fi
fi

# Check if user already has SSH keys (legacy check for standard names)
if [ -f "$SSH_DIR/id_rsa.pub" ]; then
    echo "Found existing SSH public key: $SSH_DIR/id_rsa.pub"
    read -p "Use this key for DevDocker? (y/n): " use_existing
    
    if [ "$use_existing" = "y" ] || [ "$use_existing" = "Y" ]; then
        echo "Copying public key to authorized_keys..."
        cp "$SSH_DIR/id_rsa.pub" "$AUTHORIZED_KEYS_FILE"
        chmod 644 "$AUTHORIZED_KEYS_FILE"
        echo "✓ SSH key configured successfully!"
        echo ""
        echo "You can now connect to the container via SSH:"
        echo "  ssh -p 2222 root@localhost"
        echo ""
        echo "Note: authorized_keys is only copied into the container at startup."
        echo "If devdocker is already running, restart it first so this key takes effect:"
        echo "  docker compose up -d --force-recreate"
        exit 0
    fi
fi

# Check for other common key types
for key_type in id_ed25519 id_ecdsa id_dsa; do
    if [ -f "$SSH_DIR/${key_type}.pub" ]; then
        echo "Found existing SSH public key: $SSH_DIR/${key_type}.pub"
        read -p "Use this key for DevDocker? (y/n): " use_existing

        if [ "$use_existing" = "y" ] || [ "$use_existing" = "Y" ]; then
            echo "Copying public key to authorized_keys..."
            cp "$SSH_DIR/${key_type}.pub" "$AUTHORIZED_KEYS_FILE"
            chmod 644 "$AUTHORIZED_KEYS_FILE"
            echo "✓ SSH key configured successfully!"
            echo ""
            echo "You can now connect to the container via SSH:"
            echo "  ssh -p 2222 root@localhost"
            echo ""
            echo "Note: authorized_keys is only copied into the container at startup."
            echo "If devdocker is already running, restart it first so this key takes effect:"
            echo "  docker compose up -d --force-recreate"
            exit 0
        fi
    fi
done

# No existing keys found or user wants to create new ones
echo ""
echo "No SSH keys configured yet."
echo ""
echo "Options:"
echo "  1. Generate a new SSH key pair"
echo "  2. Manually specify a public key file"
echo "  3. Exit and configure manually"
echo ""
read -p "Choose an option (1-3): " option

case $option in
    1)
        echo ""
        echo "Generating new SSH key pair..."
        KEY_NAME="devdocker_rsa"
        mkdir -p "$SSH_DIR"
        ssh-keygen -t rsa -b 4096 -f "$SSH_DIR/$KEY_NAME" -N "" -C "devdocker@localhost"

        echo "Copying public key to authorized_keys..."
        cp "$SSH_DIR/${KEY_NAME}.pub" "$AUTHORIZED_KEYS_FILE"
        chmod 644 "$AUTHORIZED_KEYS_FILE"

        echo ""
        echo "✓ SSH key pair generated and configured!"
        echo ""
        echo "Private key: $SSH_DIR/$KEY_NAME"
        echo "Public key: $SSH_DIR/${KEY_NAME}.pub"
        echo ""
        # devdocker_rsa is not a default SSH identity filename, so -i is required
        CONNECT_CMD="ssh -i $SSH_DIR/$KEY_NAME -p 2222 root@localhost"
        echo "You can now connect to the container via SSH:"
        echo "  $CONNECT_CMD"
        ;;
    2)
        echo ""
        read -p "Enter path to your public key file: " pubkey_path

        if [ ! -f "$pubkey_path" ]; then
            echo "ERROR: File not found: $pubkey_path"
            exit 1
        fi

        echo "Copying public key to authorized_keys..."
        cp "$pubkey_path" "$AUTHORIZED_KEYS_FILE"
        chmod 644 "$AUTHORIZED_KEYS_FILE"

        echo "✓ SSH key configured successfully!"
        echo ""
        # The matching private key is conventionally the same path without .pub.
        # Not guaranteed to be a default identity filename, so pass -i explicitly.
        CONNECT_CMD="ssh -i ${pubkey_path%.pub} -p 2222 root@localhost"
        echo "You can now connect to the container via SSH:"
        echo "  $CONNECT_CMD"
        ;;
    3)
        echo ""
        echo "Manual configuration:"
        echo "  1. Copy your public key to: $AUTHORIZED_KEYS_FILE"
        echo "  2. Ensure permissions: chmod 644 $AUTHORIZED_KEYS_FILE"
        echo "  3. Start the container (use --force-recreate if devdocker is"
        echo "     already running, since authorized_keys is only copied in"
        echo "     at startup): docker compose up -d --force-recreate"
        exit 0
        ;;
    *)
        echo "Invalid option. Exiting."
        exit 1
        ;;
esac

echo ""
echo "Next steps:"
echo "  1. Start the container (use --force-recreate if devdocker is already"
echo "     running, since authorized_keys is only copied in at startup):"
echo "       docker compose up -d --force-recreate"
echo "  2. Test SSH connection: $CONNECT_CMD"
echo ""
